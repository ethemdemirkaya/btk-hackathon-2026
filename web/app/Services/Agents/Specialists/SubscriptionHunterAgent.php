<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class SubscriptionHunterAgent extends AbstractAgent
{
    public function getName(): string { return 'subscription_hunter'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir abonelik avı uzmanısın. Kullanıcının işlemlerindeki tekrarlayan ödemeleri
        tespit eder, fiyat artışlarını yakalar ve gereksiz abonelikleri işaretlersin.
        Türkiye'de yaygın dijital abonelikler konusunda bilgilisin. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $monthlyIncome = (float) ($this->user->monthly_income ?? 0);

        // Find recurring transactions (same merchant, multiple times in last 4 months)
        $recurring = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $this->user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', Carbon::now()->subMonths(4))
            ->whereNotNull('t.merchant_name')
            ->select(
                't.merchant_name',
                DB::raw('COUNT(*) as occurrences'),
                DB::raw('AVG(ABS(t.amount)) as avg_amount'),
                DB::raw('MIN(ABS(t.amount)) as min_amount'),
                DB::raw('MAX(ABS(t.amount)) as max_amount'),
                DB::raw('SUM(ABS(t.amount)) as total_paid'),
            )
            ->groupBy('t.merchant_name')
            ->having('occurrences', '>=', 2)
            ->orderByDesc('total_paid')
            ->limit(20)
            ->get();

        // Existing tracked subscriptions
        $existing = DB::table('subscriptions')
            ->where('user_id', $this->user->id)
            ->whereNull('cancelled_at')
            ->pluck('merchant_name')
            ->toArray();

        // Untracked candidates (not yet in subscriptions table)
        $untracked = $recurring->filter(fn ($r) => ! in_array($r->merchant_name, $existing));

        $totalMonthlySubscriptions = DB::table('subscriptions')
            ->where('user_id', $this->user->id)
            ->whereNull('cancelled_at')
            ->where('billing_cycle', 'monthly')
            ->sum('amount');

        $recurringJson  = $recurring->toJson(JSON_UNESCAPED_UNICODE);
        $untrackedJson  = $untracked->toJson(JSON_UNESCAPED_UNICODE);
        $existingJson   = json_encode($existing, JSON_UNESCAPED_UNICODE);
        $context        = $input['context'] ?? '';

        $prompt = <<<PROMPT
        Kullanıcı abonelik analizi:
        - Aylık gelir: ₺{$monthlyIncome}
        - Mevcut takip edilen aylık abonelik toplam: ₺{$totalMonthlySubscriptions}

        Son 4 ayda tekrarlayan ödemeler:
        {$recurringJson}

        Mevcut kayıtlı abonelikler: {$existingJson}

        Henüz takip edilmeyen tekrarlayan ödemeler:
        {$untrackedJson}

        Bağlam: {$context}

        1. Tespit edilmemiş abonelikleri listele
        2. Fiyat artışı olan abonelikleri işaretle (min vs max fark > %5)
        3. Gereksiz/pahalı abonelikleri öner
        4. Abonelik yükünü gelire oranla değerlendir
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'detected_subscriptions' => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'merchant'      => ['type' => 'string'],
                            'monthly_cost'  => ['type' => 'number'],
                            'occurrences'   => ['type' => 'integer'],
                            'is_tracked'    => ['type' => 'boolean'],
                            'price_change'  => ['type' => 'string'],
                        ],
                        'required' => ['merchant', 'monthly_cost'],
                    ],
                ],
                'total_monthly_burden' => ['type' => 'number'],
                'income_percentage'    => ['type' => 'string'],
                'cancellation_candidates' => [
                    'type'  => 'array',
                    'items' => ['type' => 'string'],
                ],
                'price_increase_alerts' => [
                    'type'  => 'array',
                    'items' => ['type' => 'string'],
                ],
                'summary' => ['type' => 'string'],
            ],
            'required' => ['detected_subscriptions', 'summary'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema);
    }
}
