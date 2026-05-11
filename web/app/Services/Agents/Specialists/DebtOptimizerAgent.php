<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Illuminate\Support\Facades\DB;

class DebtOptimizerAgent extends AbstractAgent
{
    public function getName(): string { return 'debt_optimizer'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir borç optimizasyon uzmanısın. Kullanıcının kredi kartı borçlarını ve
        kredilerini analiz edip en hızlı ve en az faiz ödeyen geri ödeme stratejilerini
        önerisin. Avalanche ve Snowball metotlarını Türkçe anlatırsın. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $monthlyIncome = (float) ($this->user->monthly_income ?? 0);

        // Cards
        $cards = DB::table('cards')
            ->where('user_id', $this->user->id)
            ->where('current_debt', '>', 0)
            ->get(['masked_number', 'current_debt', 'credit_limit', 'due_day']);

        // Loans
        $loans = DB::table('loans')
            ->where('user_id', $this->user->id)
            ->where('current_balance', '>', 0)
            ->get(['type', 'current_balance', 'interest_rate', 'next_payment_amount', 'ends_at']);

        $totalCardDebt = (float) $cards->sum('current_debt');
        $totalLoanDebt = (float) $loans->sum('current_balance');
        $totalDebt     = $totalCardDebt + $totalLoanDebt;

        // Monthly expenses (for disposable income calc)
        $avgMonthlyExpense = (float) DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $this->user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subMonths(3))
            ->avg(DB::raw('ABS(t.amount)'));

        $monthlySurplus = max(0, $monthlyIncome - $avgMonthlyExpense);
        $debtToIncomeRatio = $monthlyIncome > 0
            ? round($totalDebt / ($monthlyIncome * 12) * 100, 1)
            : 0;

        $cardsJson = $cards->toJson(JSON_UNESCAPED_UNICODE);
        $loansJson = $loans->toJson(JSON_UNESCAPED_UNICODE);
        $context   = $input['context'] ?? '';

        $prompt = <<<PROMPT
        Kullanıcının borç profili:
        - Aylık gelir: ₺{$monthlyIncome}
        - Aylık surplus (gider sonrası kalan): ₺{$monthlySurplus}

        - Toplam kart borcu: ₺{$totalCardDebt}
        - Toplam kredi borcu: ₺{$totalLoanDebt}
        - Toplam borç: ₺{$totalDebt}
        - Borç/Gelir oranı: %{$debtToIncomeRatio}

        Kredi kartları: {$cardsJson}
        Krediler: {$loansJson}

        Bağlam: {$context}

        3 farklı borç ödeme stratejisi öner:
        1. Avalanche (yüksek faizden başla)
        2. Snowball (küçük borçtan başla)
        3. Hibrit (Paranette önerisi — kısa vadeli bakış açısıyla)
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'debt_summary' => [
                    'type'       => 'object',
                    'properties' => [
                        'total_debt'           => ['type' => 'number'],
                        'debt_to_income_ratio' => ['type' => 'string'],
                        'risk_level'           => ['type' => 'string'],
                    ],
                ],
                'strategies' => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'name'              => ['type' => 'string'],
                            'description'       => ['type' => 'string'],
                            'payoff_months'     => ['type' => 'integer'],
                            'total_interest'    => ['type' => 'number'],
                            'first_step'        => ['type' => 'string'],
                            'pros'              => ['type' => 'array', 'items' => ['type' => 'string']],
                            'cons'              => ['type' => 'array', 'items' => ['type' => 'string']],
                        ],
                        'required' => ['name', 'description', 'first_step'],
                    ],
                ],
                'recommended_strategy' => ['type' => 'string'],
                'quick_wins'           => ['type' => 'array', 'items' => ['type' => 'string']],
            ],
            'required' => ['strategies', 'recommended_strategy', 'quick_wins'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema, 0.6);
    }
}
