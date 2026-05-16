<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class DebtDetectionService
{
    // İşlem açıklamasında borç varlığına işaret eden anahtar kelimeler
    private const DEBT_KEYWORDS = [
        'borç', 'borc', 'ödünç', 'odunc', 'borcum', 'borcun',
        'borç attım', 'borç verdim', 'borç verdi', 'borçlandım',
        'loan', 'lend', 'borrow', 'advance',
    ];

    // Geri ödemeye işaret eden kelimeler
    private const REPAYMENT_KEYWORDS = [
        'geri ödeme', 'geri odeme', 'iade', 'geri verdi',
        'geri aldım', 'geri alındı', 'ödeme iade', 'repayment', 'geri dön',
    ];

    /**
     * Son 90 günün işlemlerini tarayıp, daha önce borç olarak kayıt edilmemiş
     * ve açıklamasında borç anahtar kelimesi geçen işlemleri döner.
     */
    public function detectUnconfirmedDebts(int $userId): array
    {
        $linkedTxIds = DB::table('personal_debts')
            ->where('user_id', $userId)
            ->whereNotNull('transaction_id')
            ->pluck('transaction_id')
            ->all();

        $transactions = DB::table('transactions')
            ->where('user_id', $userId)
            ->whereDate('transaction_date', '>=', now()->subDays(90))
            ->when($linkedTxIds, fn ($q) => $q->whereNotIn('id', $linkedTxIds))
            ->orderByDesc('transaction_date')
            ->get(['id', 'description', 'merchant_name', 'amount', 'transaction_date', 'currency']);

        $suggestions = [];

        foreach ($transactions as $tx) {
            $desc = mb_strtolower($tx->description ?? $tx->merchant_name ?? '');

            if (! $this->hasKeyword($desc, self::DEBT_KEYWORDS)) {
                continue;
            }

            // Para çıkışı (negatif) = borç verdim, para girişi (pozitif) = borç aldım
            $txAmount = (float) $tx->amount;
            $direction = $txAmount < 0 ? 'given' : 'received';

            $suggestions[] = [
                'transaction_id'    => $tx->id,
                'transaction_date'  => $tx->transaction_date,
                'description'       => $tx->description ?? $tx->merchant_name,
                'amount'            => round(abs($txAmount), 2),
                'currency'          => $tx->currency ?? 'TRY',
                'direction'         => $direction,
                'suggested_contact' => $this->extractContactName($tx->description ?? $tx->merchant_name ?? ''),
                'is_repayment_hint' => $this->hasKeyword($desc, self::REPAYMENT_KEYWORDS),
            ];
        }

        return $suggestions;
    }

    /**
     * Mevcut açık borçlara karşılık gelebilecek işlemleri bulur.
     * Yön (gelen/giden), tutar aralığı (%90 eşiği) ve geri ödeme anahtar kelimeleri kontrol edilir.
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
            ->where('user_id', $userId)
            ->whereDate('transaction_date', '>=', now()->subDays(90))
            ->when($linkedTxIds, fn ($q) => $q->whereNotIn('id', $linkedTxIds))
            ->get(['id', 'description', 'merchant_name', 'amount', 'transaction_date', 'currency']);

        $candidates = [];

        foreach ($transactions as $tx) {
            $txAmount = (float) $tx->amount;
            $absAmount = abs($txAmount);

            foreach ($openDebts as $debt) {
                // Borç verdim (given) → geri ödeme gelir (pozitif işlem)
                // Borç aldım (received) → geri ödeme gider (negatif işlem)
                $isOppositeDir = ($debt->direction === 'given'    && $txAmount > 0)
                              || ($debt->direction === 'received' && $txAmount < 0);

                if (! $isOppositeDir) {
                    continue;
                }

                // Tutar en az orijinal borcun %90'ı kadar olmalı
                if ($absAmount < (float) $debt->amount * 0.9) {
                    continue;
                }

                $profit = round(max(0.0, $absAmount - (float) $debt->amount), 2);

                $candidates[] = [
                    'debt_id'          => $debt->id,
                    'debt_contact'     => $debt->contact_name,
                    'debt_amount'      => (float) $debt->amount,
                    'debt_direction'   => $debt->direction,
                    'transaction_id'   => $tx->id,
                    'transaction_date' => $tx->transaction_date,
                    'description'      => $tx->description ?? $tx->merchant_name,
                    'repayment_amount' => $absAmount,
                    'profit'           => $profit,
                ];
            }
        }

        return $candidates;
    }

    // ── Yardımcı metodlar ──────────────────────────────────────────────

    private function hasKeyword(string $text, array $keywords): bool
    {
        foreach ($keywords as $kw) {
            if (str_contains($text, $kw)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Açıklamadan kişi adı çıkarmaya çalışır.
     * Türkçe isim kalıplarını tanır: "Ali'ye borç", "borç Mehmet", "Ahmet'ten borç"
     */
    private function extractContactName(string $description): ?string
    {
        $desc = mb_strtolower($description);

        $patterns = [
            "/([a-zçğışöüa-z]{2,})'[ye|e|a|den|dan|te|ta]+\s+borç/u",
            "/borç\s+([a-zçğışöüa-z]{2,})/u",
            "/([a-zçğışöüa-z]{2,})\s+borç\s/u",
            "/([a-zçğışöüa-z]{2,})'den\s/u",
        ];

        $stopWords = ['borç', 'borc', 'ödünç', 'odunc', 'para', 'geri', 'iade', 'ver', 'al'];

        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $desc, $m)) {
                $name = mb_strtolower($m[1]);
                if (! in_array($name, $stopWords, true) && mb_strlen($name) >= 2) {
                    return mb_convert_case($name, MB_CASE_TITLE, 'UTF-8');
                }
            }
        }

        return null;
    }
}
