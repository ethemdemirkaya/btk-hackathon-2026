<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class BudgetAdvisorAgent extends AbstractAgent
{
    public function getName(): string { return 'budget_advisor'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir kişisel finans danışmanısın. Türkiye'deki kullanıcıların bütçe yönetiminde
        somut, uygulanabilir öneriler sun. Türkçe konuş. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $monthlyIncome = (float) ($this->user->monthly_income ?? 0);

        $categorySpend = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->join('categories as c', 'c.id', '=', 't.category_id')
            ->select('c.name as category', DB::raw('SUM(ABS(t.amount)) as total'))
            ->where('a.user_id', $this->user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', Carbon::now()->subDays(30))
            ->whereNotNull('t.category_id')
            ->groupBy('c.id', 'c.name')
            ->orderByDesc('total')
            ->get();

        $healthScore = DB::table('financial_health_scores')
            ->where('user_id', $this->user->id)
            ->orderByDesc('calculated_at')
            ->value('score');

        $spendJson = $categorySpend->toJson(JSON_UNESCAPED_UNICODE);

        $prompt = <<<PROMPT
        Kullanıcı finansal profili:
        - Aylık gelir: ₺{$monthlyIncome}
        - Finansal sağlık skoru: {$healthScore}/100
        - Son 30 gün kategori harcamaları: {$spendJson}

        Ek bağlam: {$input['context']}

        Bu profil için somut bütçe önerileri sun.
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'recommendations' => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'category'   => ['type' => 'string'],
                            'suggestion' => ['type' => 'string'],
                            'saving_tl'  => ['type' => 'number'],
                            'priority'   => ['type' => 'string'],
                        ],
                        'required' => ['category', 'suggestion', 'priority'],
                    ],
                ],
                'monthly_savings_potential' => ['type' => 'number'],
                'summary'                   => ['type' => 'string'],
            ],
            'required' => ['recommendations', 'summary'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema);
    }
}
