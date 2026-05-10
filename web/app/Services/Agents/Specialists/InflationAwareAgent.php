<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Illuminate\Support\Facades\DB;

class InflationAwareAgent extends AbstractAgent
{
    public function getName(): string { return 'inflation_aware'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir enflasyon ve satın alma gücü analisti olarak Türkiye'deki kullanıcıların
        kişisel enflasyon profilini kullanarak finansal kararlarına gerçek değer bazlı
        içgörüler üretirsin. TÜİK verileriyle desteklenmiş Türkçe analiz sun. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $personalRate = DB::table('inflation_rates')
            ->where('user_id', $this->user->id)
            ->orderByDesc('reference_month')
            ->value('annual_rate');

        $tufeRate = DB::table('inflation_category_rates')
            ->orderByDesc('reference_month')
            ->avg('annual_rate');

        $categoryBreakdown = DB::table('inflation_category_rates as icr')
            ->select('icr.tuik_category_slug', 'icr.annual_rate')
            ->orderByDesc('icr.reference_month')
            ->orderByDesc('icr.annual_rate')
            ->limit(14)
            ->get();

        $monthlyIncome = (float) ($this->user->monthly_income ?? 0);
        $targetAmount  = (float) ($input['target_amount'] ?? 0);
        $months        = (int)   ($input['months'] ?? 12);
        $context       = $input['context'] ?? '';

        $categoryJson = $categoryBreakdown->toJson(JSON_UNESCAPED_UNICODE);
        $personalRateDisplay = $personalRate ? round((float) $personalRate, 2) : 'bilinmiyor';
        $tufeDisplay = $tufeRate ? round((float) $tufeRate, 2) : 0;

        $prompt = <<<PROMPT
        Kullanıcı enflasyon profili:
        - Kişisel enflasyon oranı (yıllık): %{$personalRateDisplay}
        - Manşet TÜFE (yıllık): %{$tufeDisplay}
        - Aylık gelir: ₺{$monthlyIncome}
        - TÜİK kategori oranları: {$categoryJson}

        Analiz talebi: {$context}
        Hedef tutar: ₺{$targetAmount}
        Süre: {$months} ay

        Enflasyonun bu finansal karar üzerindeki etkisini analiz et.
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'real_value_impact'        => ['type' => 'string'],
                'future_price_estimate'    => ['type' => 'number'],
                'purchasing_power_change'  => ['type' => 'string'],
                'recommendation'           => ['type' => 'string'],
                'personal_vs_official_gap' => ['type' => 'string'],
                'key_insights'             => [
                    'type'  => 'array',
                    'items' => ['type' => 'string'],
                ],
            ],
            'required' => ['real_value_impact', 'recommendation', 'key_insights'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema);
    }
}
