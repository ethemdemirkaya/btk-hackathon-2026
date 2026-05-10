<?php

namespace App\Services;

use App\Models\InflationCategoryRate;
use App\Models\InflationRate;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * TÜİK EVDS / Bireysel Erişim Sistemi entegrasyonu
 *
 * Manşet TÜFE ve 14 kategori bazında yıllık değişim oranlarını çeker.
 * API erişilemezse önceki kayıtları veya yerleşik yedek veriyi kullanır.
 *
 * Çevre değişkenleri:
 *   TUIK_API_KEY  — EVDS API anahtarı (isteğe bağlı, kamuya açık veri)
 *   TUIK_BASE_URL — varsayılan: https://evds2.tcmb.gov.tr
 */
class TuikApiService
{
    // TCMB-EVDS series codes for TÜİK TÜFE data
    private const TUFE_SERIES       = 'TP.FG.J0';      // Manşet TÜFE
    private const CATEGORY_SERIES   = [
        'gida'         => 'TP.FG.J01',  // Gıda ve Alkolsüz İçecekler
        'alkol'        => 'TP.FG.J02',  // Alkollü İçecekler, Sigara
        'giyim'        => 'TP.FG.J03',  // Giyim ve Ayakkabı
        'konut'        => 'TP.FG.J04',  // Konut, Su, Elektrik
        'mobilya'      => 'TP.FG.J05',  // Ev Eşyası
        'saglik'       => 'TP.FG.J06',  // Sağlık
        'ulastirma'    => 'TP.FG.J07',  // Ulaştırma
        'haberlesme'   => 'TP.FG.J08',  // Haberleşme
        'eglence'      => 'TP.FG.J09',  // Eğlence ve Kültür
        'egitim'       => 'TP.FG.J10',  // Eğitim
        'lokanta'      => 'TP.FG.J11',  // Lokanta ve Oteller
        'diger'        => 'TP.FG.J12',  // Çeşitli Mal ve Hizmetler
        'finans'       => 'TP.FG.J0',   // Finans – genel olarak manşet kullanılır
        'genel'        => 'TP.FG.J0',   // Genel – manşet
    ];

    // Yerleşik yedek veri (API erişilemezse kullanılır) — Nisan 2025
    private const FALLBACK_DATA = [
        'genel'      => 37.86,
        'gida'       => 30.97,
        'alkol'      => 42.30,
        'giyim'      => 35.24,
        'konut'      => 59.08,
        'mobilya'    => 38.90,
        'saglik'     => 32.10,
        'ulastirma'  => 31.22,
        'haberlesme' => 26.45,
        'eglence'    => 39.67,
        'egitim'     => 75.33,
        'lokanta'    => 43.51,
        'diger'      => 40.12,
        'finans'     => 37.86,
    ];

    public function __construct(
        private readonly string $baseUrl = 'https://evds2.tcmb.gov.tr',
        private readonly ?string $apiKey = null
    ) {}

    /**
     * Belirtilen ay için tüm TÜİK verisini çeker ve kaydeder.
     * Döner: ['success' => bool, 'period' => 'YYYY-MM', 'source' => 'api'|'fallback']
     */
    public function fetchAndStore(?Carbon $period = null): array
    {
        $period ??= Carbon::now()->subMonth()->startOfMonth();
        $year    = $period->year;
        $month   = $period->month;
        $cacheKey = "tuik_fetch_{$year}_{$month}";

        if (Cache::has($cacheKey)) {
            return ['success' => true, 'period' => "{$year}-{$month}", 'source' => 'cache'];
        }

        // Önce EVDS API dene
        $rates = $this->fetchFromEvds($period);

        if (empty($rates)) {
            // API başarısız — yerleşik veriye dön
            $rates  = self::FALLBACK_DATA;
            $source = 'fallback';
        } else {
            $source = 'api';
        }

        $this->storeRates($year, $month, $rates);

        // 24 saatlik cache
        Cache::put($cacheKey, true, now()->addHours(24));

        return ['success' => true, 'period' => "{$year}-{$month}", 'source' => $source];
    }

    /**
     * Son kaydedilmiş manşet TÜFE oranını döner.
     */
    public function getLatestHeadlineRate(): ?float
    {
        $row = InflationCategoryRate::where('tuik_category_slug', 'genel')
            ->orderByDesc('period_year')
            ->orderByDesc('period_month')
            ->first();

        return $row ? (float) $row->annual_change_rate : null;
    }

    /**
     * Belirtilen ay için kategori bazında yıllık oranları döner.
     * ['gida' => 30.97, 'konut' => 59.08, ...]
     */
    public function getCategoryRates(int $year, int $month): array
    {
        $rows = InflationCategoryRate::where('period_year', $year)
            ->where('period_month', $month)
            ->get()
            ->keyBy('tuik_category_slug');

        if ($rows->isEmpty()) {
            return self::FALLBACK_DATA;
        }

        return $rows->map(fn ($r) => (float) $r->annual_change_rate)->all();
    }

    // ──────────────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────────────

    private function fetchFromEvds(Carbon $period): array
    {
        if (! $this->apiKey) {
            return [];
        }

        try {
            // EVDS API: /service/dataindex?key=...&series=...&startDate=MM-YYYY&endDate=MM-YYYY&type=json
            $startDate = $period->format('d-m-Y');
            $endDate   = $period->endOfMonth()->format('d-m-Y');
            $allSeries = implode('-', array_unique(array_values(self::CATEGORY_SERIES)));

            $response = Http::timeout(10)->get("{$this->baseUrl}/service/dataindex", [
                'key'       => $this->apiKey,
                'series'    => $allSeries,
                'startDate' => $startDate,
                'endDate'   => $endDate,
                'type'      => 'json',
            ]);

            if (! $response->successful()) {
                return [];
            }

            return $this->parseEvdsResponse($response->json());
        } catch (\Throwable $e) {
            Log::warning('TÜİK EVDS API hatası', ['error' => $e->getMessage()]);
            return [];
        }
    }

    private function parseEvdsResponse(array $data): array
    {
        $rates = [];

        foreach (self::CATEGORY_SERIES as $slug => $series) {
            // EVDS JSON structure: items[0]['seriesCode'] → value
            foreach ($data['items'] ?? [] as $item) {
                if (($item['seriesCode'] ?? '') === $series && isset($item['value'])) {
                    $rates[$slug] = (float) $item['value'];
                    break;
                }
            }
        }

        return $rates;
    }

    private function storeRates(int $year, int $month, array $rates): void
    {
        $now = now();

        // Manşet TÜFE
        InflationCategoryRate::updateOrCreate(
            ['period_year' => $year, 'period_month' => $month, 'tuik_category_slug' => 'genel'],
            ['annual_change_rate' => $rates['genel'] ?? self::FALLBACK_DATA['genel'], 'fetched_at' => $now]
        );

        // 13 kategori
        foreach (array_keys(self::CATEGORY_SERIES) as $slug) {
            if ($slug === 'genel') {
                continue;
            }
            InflationCategoryRate::updateOrCreate(
                ['period_year' => $year, 'period_month' => $month, 'tuik_category_slug' => $slug],
                ['annual_change_rate' => $rates[$slug] ?? self::FALLBACK_DATA[$slug], 'fetched_at' => $now]
            );
        }
    }
}
