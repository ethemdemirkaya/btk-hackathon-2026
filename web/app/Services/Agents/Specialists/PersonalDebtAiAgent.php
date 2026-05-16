<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;

class PersonalDebtAiAgent extends AbstractAgent
{
    public function getName(): string { return 'personal_debt_ai'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir Türk bankacılık işlem analiz uzmanısın. Banka hesap hareketlerini inceleyerek
        hangilerinin kişisel borç/alacak işlemi olduğunu tespit edersin.

        Kişisel borç sayılır:
        - EFT/HAVALE/FAST ile gerçek kişiye yapılan transferler ("EFT GÖNDER - AHMET YILMAZ")
        - Açıklamada borç/ödünç/geri ödeme geçen transferler
        - Açıklamada Türk kişi adı geçen ve kurumsal olmayan transferler

        Kişisel borç SAYILMAZ:
        - Maaş ödemeleri, kredi taksitleri, faturalar, ATM, sigorta, SGK, vergi
        - Netflix, Spotify, Amazon, Apple, Trendyol, Hepsiburada gibi merchant işlemler
        - "MaaşÖdeme", "KrediTaksit", "FaturaÖdeme" gibi kurumsal açıklamalar

        Türkçe kişi adı formatları: "AHMET YILMAZ", "Zeynep Koç", "MEHMET KAYA",
        "EFT GÖNDER - AD SOYAD", "HAVALE - AD SOYAD", "FAST ÖDEME - AD SOYAD"

        Yön belirleme:
        - Negatif tutar (para çıkışı) = "given" (ben verdim / gönderdim)
        - Pozitif tutar (para girişi) = "received" (bana geldi / aldım)

        Güven seviyesi:
        - "high": açıkça borç/ödünç sözcüğü var VEYA EFT/HAVALE/FAST + tam kişi adı formatı
        - "medium": kişi adı var ama format belirsiz, ya da tutar kişisel görünüyor
        - "low": sadece tahmin, kesin değil

        Sadece JSON döndür, başka hiçbir şey ekleme.
        SYS;
    }

    /**
     * Analyze a batch of transfer transactions for personal debt detection.
     *
     * Input: ['transactions' => [['id', 'description', 'amount', 'posted_at'], ...]]
     * Output: ['results' => [['transaction_id', 'is_personal_debt', 'person_name', 'direction', 'confidence', 'reason'], ...]]
     */
    public function run(array $input): array
    {
        $transactions = $input['transactions'] ?? [];

        if (empty($transactions)) {
            return ['results' => []];
        }

        $txLines = [];
        foreach ($transactions as $idx => $tx) {
            $sign   = (float) $tx['amount'] >= 0 ? '+' : '-';
            $abs    = number_format(abs((float) $tx['amount']), 2, '.', '');
            $date   = substr((string) ($tx['posted_at'] ?? ''), 0, 10);
            $txLines[] = sprintf(
                '%d. ID:%s | Açıklama: "%s" | Tutar: %s%s TL | Tarih: %s',
                $idx + 1,
                $tx['id'],
                $tx['description'] ?? '',
                $sign,
                $abs,
                $date,
            );
        }

        $count  = count($transactions);
        $list   = implode("\n", $txLines);

        $prompt = <<<PROMPT
        Aşağıdaki {$count} adet banka transfer işlemini analiz et.

        Her işlem için şunları belirle:
        1. is_personal_debt: kişisel borç/alacak mı? (true/false)
        2. person_name: kişi adı varsa çıkar (null ise boş string döndür)
        3. direction: "given" (para gönderdim) veya "received" (para aldım)
        4. confidence: "high", "medium" veya "low"
        5. reason: max 80 karakter Türkçe açıklama

        Yanıttaki transaction_id değerleri verilen ID'lerle bire bir eşleşmeli.

        İşlemler:
        {$list}
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'results' => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'transaction_id'   => ['type' => 'string'],
                            'is_personal_debt' => ['type' => 'boolean'],
                            'person_name'      => ['type' => 'string'],
                            'direction'        => ['type' => 'string', 'enum' => ['given', 'received']],
                            'confidence'       => ['type' => 'string', 'enum' => ['high', 'medium', 'low']],
                            'reason'           => ['type' => 'string'],
                        ],
                        'required' => ['transaction_id', 'is_personal_debt', 'confidence', 'reason'],
                    ],
                ],
            ],
            'required' => ['results'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema, 0.2);
    }
}
