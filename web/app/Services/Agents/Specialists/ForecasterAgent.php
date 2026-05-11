<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ForecasterAgent extends AbstractAgent
{
    public function getName(): string { return 'forecaster'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir finansal tahmin uzmanısın. Kullanıcının geçmiş harcama eğilimlerini,
        gelirini ve Türkiye'deki enflasyonu kullanarak 3–12 aylık finansal projeksiyon
        yaparsın. Gerçekçi, konservatif tahminler üret. Türkçe yanıt ver. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $months       = max(1, min(24, (int) ($input['months'] ?? 6)));
        $context      = $input['context'] ?? '';
        $monthlyIncome = (float) ($this->user->monthly_income ?? 0);

        // Last 6 months monthly spend
        $spendRows = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $this->user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', Carbon::now()->subMonths(6))
            ->selectRaw("DATE_FORMAT(t.posted_at,'%Y-%m') as month, SUM(ABS(t.amount)) as total")
            ->groupBy('month')
            ->orderBy('month')
            ->get();

        $avgMonthlySpend = $spendRows->isNotEmpty() ? (float) $spendRows->avg('total') : 0;
        $monthlySavings  = max(0, $monthlyIncome - $avgMonthlySpend);

        // Personal inflation
        $tufeRate = (float) (DB::table('inflation_category_rates')
            ->where('tuik_category_slug', 'genel')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->value('annual_change_rate') ?? 37.86);

        // Current balance
        $currentBalance = (float) DB::table('accounts')
            ->where('user_id', $this->user->id)
            ->sum('balance');

        // Credit card debt
        $cardDebt = (float) DB::table('cards')
            ->where('user_id', $this->user->id)
            ->sum('current_debt');

        // Health score
        $healthScore = DB::table('financial_health_scores')
            ->where('user_id', $this->user->id)
            ->orderByDesc('calculated_at')
            ->value('score');

        // Monthly spend trend (is it growing?)
        $spendAmounts = $spendRows->pluck('total')->toArray();
        $spendTrend   = count($spendAmounts) >= 2
            ? (end($spendAmounts) - reset($spendAmounts)) / (count($spendAmounts) - 1)
            : 0;

        $monthlyInflation = $tufeRate / 100 / 12;
        $projectedBalance = round($currentBalance + ($monthlySavings * $months), 0);
        $realProjectedBalance = round($projectedBalance / ((1 + $monthlyInflation) ** $months), 0);

        $prompt = <<<PROMPT
        Kullanıcı finansal durumu:
        - Aylık gelir: ₺{$monthlyIncome}
        - Aylık ortalama gider (son 6 ay): ₺{$avgMonthlySpend}
        - Aylık tasarruf kapasitesi: ₺{$monthlySavings}
        - Mevcut toplam bakiye: ₺{$currentBalance}
        - Kart borcu: ₺{$cardDebt}
        - Finansal sağlık skoru: {$healthScore}/100
        - Yıllık TÜFE: %{$tufeRate}
        - Harcama trendi: ₺{$spendTrend}/ay değişim
        - Projeksiyon süresi: {$months} ay
        - Nominal projeksiyon sonrası bakiye: ₺{$projectedBalance}
        - Reel (enflasyona göre düzeltilmiş) bakiye: ₺{$realProjectedBalance}

        Bağlam: {$context}

        {$months} aylık finansal projeksiyon yap. Nominal ve reel değerleri karşılaştır.
        Alım gücü kaybını hesaba kat. Tasarruf hedefleri öner.
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'projected_balance_nominal' => ['type' => 'number'],
                'projected_balance_real'    => ['type' => 'number'],
                'purchasing_power_loss'     => ['type' => 'string'],
                'monthly_projections'       => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'month'           => ['type' => 'string'],
                            'balance_nominal' => ['type' => 'number'],
                            'balance_real'    => ['type' => 'number'],
                        ],
                    ],
                ],
                'savings_recommendations' => [
                    'type'  => 'array',
                    'items' => ['type' => 'string'],
                ],
                'risk_assessment' => ['type' => 'string'],
                'outlook'         => ['type' => 'string'],
            ],
            'required' => ['projected_balance_nominal', 'projected_balance_real', 'savings_recommendations', 'outlook'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema);
    }
}
