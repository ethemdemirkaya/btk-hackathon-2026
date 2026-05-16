<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class DebtDetectionService
{
    private const DEBT_KEYWORDS = [
        // Core Turkish
        'borç', 'borc', 'ödünç', 'odunc',
        'borcum', 'borcun', 'borçlu',
        'borç verdim', 'borç verdi', 'borç attım', 'borç istedi',
        'borçlandım', 'ödünç verdim', 'ödünç aldım',
        'para ödünç', 'kira için borç',
        // English
        'loan', 'lend', 'lent', 'borrow', 'borrowed', 'advance',
    ];

    private const REPAYMENT_KEYWORDS = [
        'geri ödeme', 'geri odeme', 'geri verdi', 'geri ödedi',
        'geri aldım', 'geri alındı', 'ödeme iade', 'borç iade',
        'borç geri', 'borcunu geri', 'borcunu ödedi', 'borcunu verdi',
        'iade', 'repayment', 'geri dön', 'geri dönüş',
    ];

    /**
     * Son 90 günün işlemlerini tarar; borç anahtar kelimesi geçen veya
     * kişisel transfer olduğu anlaşılan işlemleri döner.
     */
    public function detectUnconfirmedDebts(int $userId): array
    {
        $linkedTxIds = DB::table('personal_debts')
            ->where('user_id', $userId)
            ->whereNotNull('transaction_id')
            ->pluck('transaction_id')
            ->all();

        $transactions = DB::table('transactions')
            ->join('accounts', 'transactions.account_id', '=', 'accounts.id')
            ->where('accounts.user_id', $userId)
            ->where('transactions.posted_at', '>=', now()->subDays(90))
            ->when(
                count($linkedTxIds) > 0,
                fn ($q) => $q->whereNotIn('transactions.id', $linkedTxIds)
            )
            ->orderByDesc('transactions.posted_at')
            ->get([
                'transactions.id',
                'transactions.description',
                'transactions.merchant_name',
                'transactions.amount',
                'transactions.posted_at',
                'transactions.currency',
                'transactions.channel',
            ]);

        $suggestions = [];

        foreach ($transactions as $tx) {
            $desc = mb_strtolower($tx->description ?? $tx->merchant_name ?? '', 'UTF-8');

            $hasDebt      = $this->hasKeyword($desc, self::DEBT_KEYWORDS);
            $hasRepayment = $this->hasKeyword($desc, self::REPAYMENT_KEYWORDS);

            if (! $hasDebt && ! $hasRepayment) {
                continue;
            }

            $txAmount  = (float) $tx->amount;
            $direction = $txAmount < 0 ? 'given' : 'received';

            $suggestions[] = [
                'transaction_id'    => $tx->id,
                'transaction_date'  => $tx->posted_at,
                'description'       => $tx->description ?? $tx->merchant_name,
                'amount'            => round(abs($txAmount), 2),
                'currency'          => $tx->currency ?? 'TRY',
                'direction'         => $direction,
                'suggested_contact' => $this->extractContactName($tx->description ?? $tx->merchant_name ?? ''),
                'is_repayment_hint' => $hasRepayment,
            ];
        }

        return $suggestions;
    }

    /**
     * Mevcut açık borçlara karşılık gelebilecek işlemleri bulur.
     */
    public function findRepaymentCandidates(int $userId): array
    {
        $openDebts = DB::table('personal_debts')
            ->where('user_id', $userId)
            ->where('is_settled', false)
            ->get();

        if ($openDebts->isEmpty()) {
            return [];
        }

        $linkedTxIds = DB::table('personal_debts')
            ->where('user_id', $userId)
            ->whereNotNull('transaction_id')
            ->pluck('transaction_id')
            ->all();

        $transactions = DB::table('transactions')
            ->join('accounts', 'transactions.account_id', '=', 'accounts.id')
            ->where('accounts.user_id', $userId)
            ->where('transactions.posted_at', '>=', now()->subDays(180))
            ->when(
                count($linkedTxIds) > 0,
                fn ($q) => $q->whereNotIn('transactions.id', $linkedTxIds)
            )
            ->get([
                'transactions.id',
                'transactions.description',
                'transactions.merchant_name',
                'transactions.amount',
                'transactions.posted_at',
                'transactions.currency',
            ]);

        $candidates = [];
        $seen       = [];  // avoid duplicate (debt_id, tx_id) pairs

        foreach ($transactions as $tx) {
            $txAmount  = (float) $tx->amount;
            $absAmount = abs($txAmount);
            $txDesc    = mb_strtolower($tx->description ?? '', 'UTF-8');

            foreach ($openDebts as $debt) {
                $pairKey = $debt->id . '_' . $tx->id;
                if (isset($seen[$pairKey])) {
                    continue;
                }

                // Direction must be opposite: given debt → expect incoming repayment
                $isOppositeDir = ($debt->direction === 'given'    && $txAmount > 0)
                              || ($debt->direction === 'received' && $txAmount < 0);

                if (! $isOppositeDir) {
                    continue;
                }

                $debtAmount = (float) $debt->amount;

                // Match if repayment amount is ≥ 80% of debt amount
                if ($absAmount < $debtAmount * 0.80) {
                    continue;
                }

                // Bonus confidence: description mentions the contact's name or repayment keywords
                $contactLower    = mb_strtolower($debt->contact_name ?? '', 'UTF-8');
                $nameMatch       = $contactLower && str_contains($txDesc, $contactLower);
                $repaymentKeyword = $this->hasKeyword($txDesc, self::REPAYMENT_KEYWORDS);

                // Skip if no keyword/name match AND amount is ≥ 3× the debt (likely unrelated)
                if (! $nameMatch && ! $repaymentKeyword && $absAmount > $debtAmount * 3) {
                    continue;
                }

                $profit = round(max(0.0, $absAmount - $debtAmount), 2);

                $candidates[] = [
                    'debt_id'          => $debt->id,
                    'debt_contact'     => $debt->contact_name,
                    'debt_amount'      => $debtAmount,
                    'debt_direction'   => $debt->direction,
                    'transaction_id'   => $tx->id,
                    'transaction_date' => $tx->posted_at,
                    'description'      => $tx->description ?? $tx->merchant_name,
                    'repayment_amount' => $absAmount,
                    'profit'           => $profit,
                ];

                $seen[$pairKey] = true;
            }
        }

        return $candidates;
    }

    // ── Helpers ────────────────────────────────────────────────────────

    private function hasKeyword(string $text, array $keywords): bool
    {
        foreach ($keywords as $kw) {
            if (mb_strpos($text, $kw, 0, 'UTF-8') !== false) {
                return true;
            }
        }
        return false;
    }

    private function extractContactName(string $description): ?string
    {
        $desc = mb_strtolower($description, 'UTF-8');

        $patterns = [
            // "Ahmet'e borç", "Can'a ödünç"
            "/([a-zçğışöüa-z]{2,})'[yeaıiuü]+\s+(?:borç|ödünç)/u",
            // "Zeynep'ten ödünç"
            "/([a-zçğışöüa-z]{2,})'(?:ten|tan|den|dan)\s+(?:borç|ödünç)/u",
            // "Ahmet borcunu geri"
            "/^([a-zçğışöüa-z]{2,})\s+borcu/u",
            // "borç Ahmet"
            "/borç\s+([a-zçğışöüa-z]{2,})/u",
            // generic: "X geri ödeme"
            "/^([a-zçğışöüa-z]{2,})\s+geri/u",
        ];

        $stopWords = [
            'borç', 'borc', 'ödünç', 'odunc', 'para', 'geri', 'iade',
            'ver', 'al', 'kira', 'için', 'istek', 'nakit',
        ];

        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $desc, $m)) {
                $name = mb_strtolower($m[1], 'UTF-8');
                if (! in_array($name, $stopWords, true) && mb_strlen($name, 'UTF-8') >= 2) {
                    return mb_convert_case($name, MB_CASE_TITLE, 'UTF-8');
                }
            }
        }

        return null;
    }
}
