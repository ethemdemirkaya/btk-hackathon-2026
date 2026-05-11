<?php

namespace App\Services\Agents\Orchestrator;

use App\Services\Gemini\GeminiClient;
use App\Services\Gemini\GeminiModelEnum;

/**
 * Uses Gemini Flash to classify user intent and select which specialist agents to invoke.
 */
class IntentRouter
{
    private GeminiClient $gemini;

    public function __construct()
    {
        $this->gemini = app(GeminiClient::class);
    }

    /**
     * @return array{agents: string[], context: string, extracted: array}
     */
    public function route(string $userMessage): array
    {
        $systemPrompt = <<<'SYS'
        Sen bir finansal asistan yönlendirme sistemisin. Kullanıcı mesajını analiz edip
        hangi uzman ajanların çalışması gerektiğine karar ver. Türkçe mesajları anla.
        Sadece JSON döndür.
        SYS;

        $agentList = implode(', ', [
            'purchase_planner',
            'budget_advisor',
            'inflation_aware',
            'anomaly_detector',
            'transaction_classifier',
            'forecaster',
            'debt_optimizer',
            'subscription_hunter',
        ]);

        $prompt = <<<PROMPT
        Kullanıcı mesajı: "{$userMessage}"

        Mevcut uzman ajanlar: {$agentList}

        - purchase_planner: büyük alım planlaması, "alabilir miyim?", bütçe hesabı
        - budget_advisor: harcama önerileri, tasarruf ipuçları, bütçe oluşturma
        - inflation_aware: enflasyon etkisi, reel değer, satın alma gücü analizi
        - anomaly_detector: şüpheli işlem, olağandışı harcama tespiti
        - transaction_classifier: işlem kategorize etme talebi
        - forecaster: gelecek projeksiyon, birikim tahmini, 3-12 ay finansal görünüm
        - debt_optimizer: borç azaltma stratejisi, kredi kartı optimizasyonu, Avalanche/Snowball
        - subscription_hunter: abonelik tespiti, tekrarlayan ödeme analizi, gereksiz abonelik

        Bu mesaj için hangi ajanlar çalışmalı? Ve mesajdan çıkartılan bilgileri döndür.
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'agents'  => [
                    'type'  => 'array',
                    'items' => ['type' => 'string'],
                ],
                'context' => ['type' => 'string'],
                'extracted' => [
                    'type'       => 'object',
                    'properties' => [
                        'item'   => ['type' => 'string'],
                        'amount' => ['type' => 'number'],
                        'months' => ['type' => 'integer'],
                    ],
                ],
            ],
            'required' => ['agents', 'context'],
        ];

        $contents = [['role' => 'user', 'parts' => [['text' => $prompt]]]];
        $result   = $this->gemini->generate(GeminiModelEnum::FLASH, $contents, $systemPrompt, $schema, 0.2);

        return array_merge(['agents' => [], 'context' => $userMessage, 'extracted' => []], $result['content']);
    }
}
