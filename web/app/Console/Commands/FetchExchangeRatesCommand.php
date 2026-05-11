<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class FetchExchangeRatesCommand extends Command
{
    protected $signature   = 'rates:fetch';
    protected $description = 'Fetch latest exchange rates from TCMB XML + gold-api.com';

    private const TCMB_URL = 'https://www.tcmb.gov.tr/kurlar/today.xml';
    private const GOLD_URL = 'https://api.gold-api.com/price/XAU';
    private const TRACKED  = ['USD', 'EUR', 'GBP', 'CHF', 'JPY', 'SAR', 'AUD', 'CAD'];

    public function handle(): int
    {
        $today = now()->toDateString();
        $rows  = [];

        // ── 1. TCMB döviz kurları ────────────────────────────────────────────
        try {
            $xml = Http::withoutVerifying()
                ->timeout(15)
                ->get(self::TCMB_URL)
                ->body();

            $data = simplexml_load_string($xml);

            foreach ($data->Currency as $cur) {
                $code = (string) $cur['CurrencyCode'];
                if (! in_array($code, self::TRACKED, true)) {
                    continue;
                }

                $buying  = (float) $cur->ForexBuying;
                $selling = (float) $cur->ForexSelling;
                $unit    = max(1, (int) $cur->Unit);

                if ($buying <= 0 || $selling <= 0) {
                    continue;
                }

                $rows[$code] = [
                    'currency'    => $code,
                    'rate_to_try' => round(($buying + $selling) / 2 / $unit, 6),
                    'date'        => $today,
                    'created_at'  => now(),
                    'updated_at'  => now(),
                ];
            }

            $this->info('TCMB: ' . count($rows) . ' kur alındı.');
        } catch (\Throwable $e) {
            $this->error('TCMB hatası: ' . $e->getMessage());
        }

        // ── 2. Altın (XAU) — USD/troy oz → TRY/gram ─────────────────────────
        try {
            $goldResp = Http::withoutVerifying()
                ->timeout(10)
                ->get(self::GOLD_URL);

            if ($goldResp->ok()) {
                $xauUsd = (float) $goldResp->json('price'); // $/troy oz
                $usdTry = $rows['USD']['rate_to_try'] ?? null;

                if ($xauUsd > 0 && $usdTry) {
                    // 1 troy oz = 31.1035 gram
                    $xauTry = ($xauUsd / 31.1035) * $usdTry;

                    $rows['XAU'] = [
                        'currency'    => 'XAU',
                        'rate_to_try' => round($xauTry, 4),
                        'date'        => $today,
                        'created_at'  => now(),
                        'updated_at'  => now(),
                    ];

                    $this->info(sprintf(
                        'Altın: $%.2f/oz → ₺%.2f/gram',
                        $xauUsd,
                        $xauTry
                    ));
                }
            }
        } catch (\Throwable $e) {
            $this->warn('Altın fiyatı alınamadı: ' . $e->getMessage());
        }

        // ── 3. DB upsert ─────────────────────────────────────────────────────
        foreach ($rows as $row) {
            DB::table('exchange_rates')->upsert(
                $row,
                ['currency', 'date'],
                ['rate_to_try', 'updated_at']
            );
        }

        $this->info(count($rows) . ' kur exchange_rates tablosuna yazıldı (' . $today . ').');

        return self::SUCCESS;
    }
}
