<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;

class CriticAgent extends AbstractAgent
{
    public function getName(): string { return 'critic'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir finansal analiz eleştirmensin. Diğer ajanların ürettiği önerileri
        çapraz kontrol eder, tutarsızlıkları ve riskli önerileri işaretler, doğruluğu
        artırırsın. Yapıcı eleştiri yap, neyin eksik kaldığını belirt. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $specialistResults = $input['specialist_results'] ?? [];
        $userMessage       = $input['context'] ?? '';
        $monthlyIncome     = (float) ($this->user->monthly_income ?? 0);

        $resultsJson = json_encode($specialistResults, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

        $prompt = <<<PROMPT
        Kullanıcı sorusu: "{$userMessage}"
        Kullanıcı aylık geliri: ₺{$monthlyIncome}

        Diğer uzman ajanların çıktıları:
        {$resultsJson}

        Bu çıktıları eleştir:
        1. Öneriler gerçekçi mi? (gelire oran)
        2. Tutarsızlık var mı?
        3. Türkiye ekonomik koşulları dikkate alındı mı?
        4. Kullanıcıya zarar verebilecek öneri var mı?
        5. Eksik bırakılan önemli nokta var mı?
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'overall_quality'   => ['type' => 'string', 'enum' => ['high', 'medium', 'low']],
                'inconsistencies'   => ['type' => 'array', 'items' => ['type' => 'string']],
                'risky_suggestions' => ['type' => 'array', 'items' => ['type' => 'string']],
                'missing_points'    => ['type' => 'array', 'items' => ['type' => 'string']],
                'corrections'       => ['type' => 'array', 'items' => ['type' => 'string']],
                'confidence_score'  => ['type' => 'integer'],
                'critique_summary'  => ['type' => 'string'],
            ],
            'required' => ['overall_quality', 'critique_summary', 'confidence_score'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema, 0.3);
    }
}
