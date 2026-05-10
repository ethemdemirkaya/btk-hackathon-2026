<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Illuminate\Support\Facades\DB;

class TransactionClassifierAgent extends AbstractAgent
{
    public function getName(): string { return 'transaction_classifier'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir finansal işlem sınıflandırma uzmanısın. Verilen işlem açıklamalarını
        Türkiye'deki banka ekstrelerinden analiz edip Türkçe kategori ve alt kategori ata.
        Her işlem için kesin bir JSON objesi döndür. Sadece JSON, başka açıklama yok.
        SYS;
    }

    public function run(array $input): array
    {
        $transactions = $input['transactions'] ?? [];

        if (empty($transactions)) {
            return ['classified' => []];
        }

        $categories = DB::table('categories')
            ->whereNull('parent_id')
            ->pluck('name', 'slug')
            ->toArray();

        $txList = collect($transactions)
            ->map(fn ($t) => "ID:{$t['id']} DESC:{$t['description']} AMOUNT:{$t['amount']}")
            ->implode("\n");

        $categoryList = implode(', ', array_values($categories));

        $prompt = <<<PROMPT
        Aşağıdaki banka işlemlerini kategorize et. Her biri için category_slug ve confidence (0.0-1.0) döndür.
        Mevcut kategoriler: {$categoryList}

        İşlemler:
        {$txList}
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'classified' => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'id'            => ['type' => 'string'],
                            'category_slug' => ['type' => 'string'],
                            'confidence'    => ['type' => 'number'],
                            'reason'        => ['type' => 'string'],
                        ],
                        'required' => ['id', 'category_slug', 'confidence'],
                    ],
                ],
            ],
            'required' => ['classified'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema, 0.2);
    }
}
