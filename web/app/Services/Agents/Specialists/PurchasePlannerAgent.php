<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class PurchasePlannerAgent extends AbstractAgent
{
    public function getName(): string { return 'purchase_planner'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen Türkiye'de yaşayan kullanıcıların büyük satın almalarını planlayan uzman bir
        finansal danışmansın. Taksit, nakit, erteleme seçeneklerini kıyasla. Türkçe konuş.
        Kişisel enflasyon ve bütçe durumunu mutlaka hesaba kat. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $targetItem   = $input['item'] ?? 'belirtilmemiş ürün';
        $targetAmount = (float) ($input['amount'] ?? 0);
        $monthlyIncome = (float) ($this->user->monthly_income ?? 0);

        $totalBalance = (float) DB::table('accounts')
            ->where('user_id', $this->user->id)
            ->sum('balance');

        $totalCardDebt = (float) DB::table('cards')
            ->where('user_id', $this->user->id)
            ->sum('current_debt');

        $avgMonthlyExpense = (float) DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $this->user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', Carbon::now()->subMonths(3))
            ->avg(DB::raw('ABS(t.amount)'));

        $healthScore = DB::table('financial_health_scores')
            ->where('user_id', $this->user->id)
            ->orderByDesc('calculated_at')
            ->value('score');

        $personalInflation = DB::table('inflation_rates')
            ->where('user_id', $this->user->id)
            ->orderByDesc('reference_month')
            ->value('annual_rate');

        $monthlySavings = max(0, $monthlyIncome - $avgMonthlyExpense);
        $monthsToSave   = $monthlySavings > 0 ? ceil($targetAmount / $monthlySavings) : 999;
        $personalRate   = $personalInflation ? round((float) $personalInflation, 2) : 38.0;
        $monthlyInflationRate = $personalRate / 100 / 12;
        $futurePrice6m  = round($targetAmount * ((1 + $monthlyInflationRate) ** 6), 0);
        $futurePrice12m = round($targetAmount * ((1 + $monthlyInflationRate) ** 12), 0);

        $prompt = <<<PROMPT
        Kullanıcı büyük alım planı:
        - Hedef: {$targetItem}
        - Fiyat: ₺{$targetAmount}
        - Aylık gelir: ₺{$monthlyIncome}
        - Toplam mevduat: ₺{$totalBalance}
        - Toplam kart borcu: ₺{$totalCardDebt}
        - Aylık ortalama gider: ₺{$avgMonthlyExpense}
        - Aylık tasarruf kapasitesi: ₺{$monthlySavings}
        - Finansal sağlık skoru: {$healthScore}/100
        - Kişisel enflasyon: %{$personalRate}/yıl
        - 6 ay sonra tahmini fiyat: ₺{$futurePrice6m}
        - 12 ay sonra tahmini fiyat: ₺{$futurePrice12m}
        - Tasarrufla alım için gereken süre: {$monthsToSave} ay

        Bu satın alma için 3 farklı strateji alternatifi üret.
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'alternatives' => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'title'          => ['type' => 'string'],
                            'strategy'       => ['type' => 'string'],
                            'total_cost'     => ['type' => 'number'],
                            'pros'           => ['type' => 'array', 'items' => ['type' => 'string']],
                            'cons'           => ['type' => 'array', 'items' => ['type' => 'string']],
                            'recommendation' => ['type' => 'string'],
                        ],
                        'required' => ['title', 'strategy', 'pros', 'cons'],
                    ],
                ],
                'verdict'           => ['type' => 'string'],
                'inflation_warning' => ['type' => 'string'],
            ],
            'required' => ['alternatives', 'verdict'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema);
    }
}
