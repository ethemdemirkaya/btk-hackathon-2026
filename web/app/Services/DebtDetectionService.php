<?php

namespace App\Services;

use App\Models\User;
use App\Services\Agents\Specialists\PersonalDebtAiAgent;
use Illuminate\Support\Facades\DB;

class DebtDetectionService
{
    /**
     * Descriptions that are clearly institutional/bank transactions — never personal debts.
     * Checked against both detection and repayment matching.
     */
    private const INSTITUTIONAL_PATTERNS = [
        'kredi taksit', 'kredisi taksit', 'taksit ödemesi',
        'ihtiyaç kredisi', 'konut kredisi', 'taşıt kredisi', 'araç kredisi',
        'kredi kartı ödemesi', 'kart ödemesi', 'kart borcu',
        'otomatik ödeme', 'düzenli ödeme', 'otomatik talimat',
        'fatura ödemesi', 'elektrik faturası', 'doğalgaz faturası',
        'su faturası', 'internet faturası', 'telefon faturası',
        'netflix', 'spotify', 'youtube', 'amazon', 'apple',
        'sigorta', 'kasko', 'aidat', 'apartman aidatı',
        'maaş ödemesi', 'maaş', 'sgk', 'vergi',
        'havale masrafı', 'işlem ücreti', 'komisyon',
        'atm nakit', 'nakit çekim',
    ];

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
            $rawDesc = $tx->description ?? $tx->merchant_name ?? '';
            $desc    = mb_strtolower($rawDesc, 'UTF-8');

            // Hard-skip institutional/bank transactions — never personal debts
            if ($this->hasKeyword($desc, self::INSTITUTIONAL_PATTERNS)) {
                continue;
            }

            // Skip if merchant is set (POS/merchant transactions are not personal)
            if (! empty($tx->merchant_name)) {
                continue;
            }

            $hasDebt      = $this->hasKeyword($desc, self::DEBT_KEYWORDS);
            $hasRepayment = $this->hasKeyword($desc, self::REPAYMENT_KEYWORDS);

            // Must match at least a debt keyword (repayment-only hint goes to repayment section)
            if (! $hasDebt) {
                continue;
            }

            $txAmount  = (float) $tx->amount;
            $direction = $txAmount < 0 ? 'given' : 'received';

            $suggestions[] = [
                'transaction_id'    => $tx->id,
                'transaction_date'  => $tx->posted_at,
                'description'       => $rawDesc,
                'amount'            => round(abs($txAmount), 2),
                'currency'          => $tx->currency ?? 'TRY',
                'direction'         => $direction,
                'suggested_contact' => $this->extractContactName($rawDesc),
                'is_repayment_hint' => $hasRepayment,
                'source'            => 'keyword',
                'confidence'        => 'high',
                'ai_reason'         => null,
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
            $rawDesc   = $tx->description ?? $tx->merchant_name ?? '';
            $txDesc    = mb_strtolower($rawDesc, 'UTF-8');
            $txAmount  = (float) $tx->amount;
            $absAmount = abs($txAmount);

            // Hard-skip institutional transactions — loan installments, bills, etc.
            if ($this->hasKeyword($txDesc, self::INSTITUTIONAL_PATTERNS)) {
                continue;
            }

            // Skip merchant POS transactions (shops, restaurants, etc.)
            if (! empty($tx->merchant_name)) {
                continue;
            }

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

                // Amount must be between 80% and 200% of the original debt
                if ($absAmount < $debtAmount * 0.80 || $absAmount > $debtAmount * 2.0) {
                    continue;
                }

                // Require EITHER contact name match OR repayment keyword in description
                $contactLower     = mb_strtolower($debt->contact_name ?? '', 'UTF-8');
                $nameMatch        = $contactLower !== '' && mb_strpos($txDesc, $contactLower, 0, 'UTF-8') !== false;
                $repaymentKeyword = $this->hasKeyword($txDesc, self::REPAYMENT_KEYWORDS);

                if (! $nameMatch && ! $repaymentKeyword) {
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
                    'description'      => $rawDesc,
                    'repayment_amount' => $absAmount,
                    'profit'           => $profit,
                ];

                $seen[$pairKey] = true;
            }
        }

        return $candidates;
    }

    /**
     * AI-powered detection pass: finds transfer transactions that look like
     * personal debt/repayment even without explicit debt keywords.
     * Uses Gemini Flash to identify person names and intent.
     * Falls back to empty array if AI is unavailable.
     */
    public function detectFromTransfersAi(User $user): array
    {
        // Already-linked transaction IDs
        $linkedTxIds = DB::table('personal_debts')
            ->where('user_id', $user->id)
            ->whereNotNull('transaction_id')
            ->pluck('transaction_id')
            ->all();

        // Fetch recent transfer-channel, non-merchant transactions
        $query = DB::table('transactions')
            ->join('accounts', 'transactions.account_id', '=', 'accounts.id')
            ->where('accounts.user_id', $user->id)
            ->where('transactions.posted_at', '>=', now()->subDays(90))
            ->where('transactions.channel', 'transfer')
            ->whereNull('transactions.merchant_name');

        if (count($linkedTxIds) > 0) {
            $query->whereNotIn('transactions.id', $linkedTxIds);
        }

        $transactions = $query
            ->orderByDesc('transactions.posted_at')
            ->get([
                'transactions.id',
                'transactions.description',
                'transactions.amount',
                'transactions.posted_at',
                'transactions.currency',
            ]);

        if ($transactions->isEmpty()) {
            return [];
        }

        // Skip obviously institutional transactions
        $candidates = $transactions->filter(function ($tx) {
            $desc = mb_strtolower($tx->description ?? '', 'UTF-8');
            return ! $this->hasKeyword($desc, self::INSTITUTIONAL_PATTERNS);
        });

        // Exclude transactions already caught by the keyword scanner (dedup)
        $keywordResults  = $this->detectUnconfirmedDebts($user->id);
        $keywordTxIds    = array_column($keywordResults, 'transaction_id');
        $candidates      = $candidates->filter(fn ($tx) => ! in_array($tx->id, $keywordTxIds, true));

        if ($candidates->isEmpty()) {
            return [];
        }

        // Limit to 20 per call to stay within token budget
        $candidates = $candidates->values()->take(20);

        $agentInput = $candidates->map(fn ($tx) => [
            'id'          => (string) $tx->id,
            'description' => (string) ($tx->description ?? ''),
            'amount'      => (float) $tx->amount,
            'posted_at'   => (string) ($tx->posted_at ?? ''),
        ])->all();

        try {
            $agent  = new PersonalDebtAiAgent($user);
            $result = $agent->run(['transactions' => $agentInput]);
            $rows   = $result['results'] ?? [];

            $txMap       = $candidates->keyBy('id');
            $suggestions = [];

            foreach ($rows as $r) {
                if (empty($r['is_personal_debt'])) {
                    continue;
                }
                // Only surface high/medium confidence results
                $confidence = $r['confidence'] ?? 'low';
                if ($confidence === 'low') {
                    continue;
                }

                $tx = $txMap->get($r['transaction_id'] ?? '');
                if (! $tx) {
                    continue;
                }

                $txAmount  = (float) $tx->amount;
                $direction = $r['direction'] ?? ($txAmount < 0 ? 'given' : 'received');

                $suggestions[] = [
                    'transaction_id'    => $tx->id,
                    'transaction_date'  => $tx->posted_at,
                    'description'       => $tx->description,
                    'amount'            => round(abs($txAmount), 2),
                    'currency'          => $tx->currency ?? 'TRY',
                    'direction'         => $direction,
                    'suggested_contact' => $r['person_name'] ?: null,
                    'is_repayment_hint' => false,
                    'source'            => 'ai',
                    'confidence'        => $confidence,
                    'ai_reason'         => $r['reason'] ?? null,
                ];
            }

            return $suggestions;
        } catch (\Throwable) {
            // AI failure is non-fatal — keyword results still surface
            return [];
        }
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
