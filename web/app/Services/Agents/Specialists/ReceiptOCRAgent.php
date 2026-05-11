<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;

class ReceiptOCRAgent extends AbstractAgent
{
    public function getName(): string { return 'receipt_ocr'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::vision(); }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir Türk fiş/fatura OCR uzmanısın. Sana verilen görüntüden makbuz bilgilerini
        çıkar. Türkiye'deki alışveriş makbuzlarını, faturaları, restoran fişlerini tanırsın.
        Sadece JSON döndür. Emin olmadığın alanları null bırak.
        SYS;
    }

    /**
     * @param  array{image_path: string, mime_type?: string}  $input
     */
    public function run(array $input): array
    {
        $imagePath = $input['image_path'];
        $mimeType  = $input['mime_type'] ?? $this->guessMime($imagePath);
        $imageData = base64_encode(file_get_contents($imagePath));

        $contents = [[
            'role'  => 'user',
            'parts' => [
                [
                    'inlineData' => [
                        'mimeType' => $mimeType,
                        'data'     => $imageData,
                    ],
                ],
                [
                    'text' => <<<'PROMPT'
                    Bu fiş/fatura görüntüsünden aşağıdaki bilgileri çıkar:
                    - merchant_name: İşyeri/mağaza adı
                    - merchant_address: Adres (varsa)
                    - purchased_at: Tarih ve saat (ISO 8601 formatı, örn: "2026-05-10T14:30:00")
                    - total_amount: Toplam tutar (sadece sayı, TL)
                    - subtotal_amount: Ara toplam (KDV hariç, varsa)
                    - vat_amount: KDV tutarı (varsa)
                    - vat_rate: KDV oranı yüzde olarak (örn: 20)
                    - currency: Para birimi (genellikle "TRY")
                    - items: Ürün listesi (her biri: name, quantity, unit_price, total_price)
                    - payment_method: Ödeme yöntemi (nakit/kredi_karti/debit/temassiz)
                    - receipt_no: Fiş/fatura numarası (varsa)
                    - category: Harcama kategorisi (gida/lokanta/ulastirma/saglik/egitim/eglence/giyim/mobilya/haberlesme/konut/diger)
                    - category_confidence: Kategori güven skoru 0.0-1.0
                    - warranty_until: Garanti bitiş tarihi (varsa, YYYY-MM-DD)
                    - raw_text: Fişteki tüm metin (ham)
                    PROMPT,
                ],
            ],
        ]];

        $schema = [
            'type'       => 'object',
            'properties' => [
                'merchant_name'       => ['type' => 'string'],
                'merchant_address'    => ['type' => 'string'],
                'purchased_at'        => ['type' => 'string'],
                'total_amount'        => ['type' => 'number'],
                'subtotal_amount'     => ['type' => 'number'],
                'vat_amount'          => ['type' => 'number'],
                'vat_rate'            => ['type' => 'number'],
                'currency'            => ['type' => 'string'],
                'payment_method'      => ['type' => 'string'],
                'receipt_no'          => ['type' => 'string'],
                'category'            => ['type' => 'string'],
                'category_confidence' => ['type' => 'number'],
                'warranty_until'      => ['type' => 'string'],
                'raw_text'            => ['type' => 'string'],
                'items'               => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'name'       => ['type' => 'string'],
                            'quantity'   => ['type' => 'number'],
                            'unit_price' => ['type' => 'number'],
                            'total_price'=> ['type' => 'number'],
                        ],
                    ],
                ],
            ],
            'required' => ['merchant_name', 'total_amount', 'category', 'raw_text'],
        ];

        $this->createRun($input);
        return $this->generate($contents, $schema, 0.2);
    }

    private function guessMime(string $path): string
    {
        $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
        return match ($ext) {
            'jpg', 'jpeg' => 'image/jpeg',
            'png'         => 'image/png',
            'gif'         => 'image/gif',
            'webp'        => 'image/webp',
            'pdf'         => 'application/pdf',
            default       => 'image/jpeg',
        };
    }
}
