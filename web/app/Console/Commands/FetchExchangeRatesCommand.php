<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FetchExchangeRatesCommand extends Command
{
    protected $signature   = 'rates:fetch';
    protected $description = 'Fetch live exchange rates from Yahoo Finance (no API key required)';

    private const TROY_OZ_TO_GRAM = 31.1035;

    // Yahoo Finance symbol → internal currency key
    private const SYMBOLS = [
        'USDTRY=X' => 'USD',
        'EURTRY=X' => 'EUR',
        'GBPTRY=X' => 'GBP',
        'CHFTRY=X' => 'CHF',
        'JPYTRY=X' => 'JPY',
        'AUDTRY=X' => 'AUD',
        'GC=F'     => null, // Altın vadeli (USD/oz) → USDTRY ile TRY/gram'a çevrilir
        'BTC-USD'  => null, // special: multiply by USDTRY
        'ETH-USD'  => null, // special: multiply by USDTRY
    ];

    public function handle(): int
    {
        $today = now()->toDateString();
        $rows  = [];

        // ── 1. Fetch all symbols from Yahoo Finance ───────────────────────────
        foreach (self::SYMBOLS as $symbol => $_) {
            $price = $this->fetchYahooPrice($symbol);

            if ($price === null) {
                $this->warn("Skipped {$symbol}: could not fetch price.");
                continue;
            }

            switch ($symbol) {
                case 'USDTRY=X':
                    $rows['USD'] = $this->makeRow('USD', $price, $today);
                    $this->info(sprintf('USD/TRY: %.4f', $price));
                    break;

                case 'EURTRY=X':
                    $rows['EUR'] = $this->makeRow('EUR', $price, $today);
                    $this->info(sprintf('EUR/TRY: %.4f', $price));
                    break;

                case 'GBPTRY=X':
                    $rows['GBP'] = $this->makeRow('GBP', $price, $today);
                    $this->info(sprintf('GBP/TRY: %.4f', $price));
                    break;

                case 'CHFTRY=X':
                    $rows['CHF'] = $this->makeRow('CHF', $price, $today);
                    $this->info(sprintf('CHF/TRY: %.4f', $price));
                    break;

                case 'JPYTRY=X':
                    // Store raw 1 JPY rate; display layer multiplies by 100
                    $rows['JPY'] = $this->makeRow('JPY', $price, $today);
                    $this->info(sprintf('JPY/TRY: %.6f', $price));
                    break;

                case 'AUDTRY=X':
                    $rows['AUD'] = $this->makeRow('AUD', $price, $today);
                    $this->info(sprintf('AUD/TRY: %.4f', $price));
                    break;

                case 'GC=F':
                    // Altın vadeli (COMEX) USD/oz → USDTRY ile TRY/gram'a çevir
                    $usdTryNow = isset($rows['USD']) ? (float) $rows['USD']['rate_to_try'] : null;
                    if ($usdTryNow) {
                        $gramTry      = ($price / self::TROY_OZ_TO_GRAM) * $usdTryNow;
                        $rows['XAU']  = $this->makeRow('XAU',  round($gramTry, 4), $today);
                        $rows['GOLD'] = $this->makeRow('GOLD', round($gramTry, 4), $today);
                        $this->info(sprintf('GC=F: $%.2f/oz × %.4f = ₺%.4f/gram', $price, $usdTryNow, $gramTry));
                    } else {
                        $this->warn('GC=F skipped: USD/TRY rate unavailable.');
                    }
                    break;

                case 'BTC-USD':
                    // Will be processed after USD rate is known
                    $rows['_BTC_USD'] = $price;
                    break;

                case 'ETH-USD':
                    // Will be processed after USD rate is known
                    $rows['_ETH_USD'] = $price;
                    break;
            }
        }

        // ── 2. Convert BTC/ETH from USD to TRY ───────────────────────────────
        $usdTry = isset($rows['USD']) ? (float) $rows['USD']['rate_to_try'] : null;

        if (isset($rows['_BTC_USD'])) {
            $btcUsd = $rows['_BTC_USD'];
            unset($rows['_BTC_USD']);

            if ($usdTry !== null) {
                $btcTry = $btcUsd * $usdTry;
                $rows['BTC'] = $this->makeRow('BTC', round($btcTry, 2), $today);
                $this->info(sprintf('BTC: $%.2f × %.4f = ₺%.2f', $btcUsd, $usdTry, $btcTry));
            } else {
                $this->warn('BTC skipped: USD/TRY rate unavailable.');
            }
        }

        if (isset($rows['_ETH_USD'])) {
            $ethUsd = $rows['_ETH_USD'];
            unset($rows['_ETH_USD']);

            if ($usdTry !== null) {
                $ethTry = $ethUsd * $usdTry;
                $rows['ETH'] = $this->makeRow('ETH', round($ethTry, 2), $today);
                $this->info(sprintf('ETH: $%.2f × %.4f = ₺%.2f', $ethUsd, $usdTry, $ethTry));
            } else {
                $this->warn('ETH skipped: USD/TRY rate unavailable.');
            }
        }

        // ── 3. Upsert into exchange_rates ─────────────────────────────────────
        $written = 0;
        foreach ($rows as $row) {
            if (! is_array($row)) {
                continue; // skip leftover scalar temp values
            }

            DB::table('exchange_rates')->upsert(
                $row,
                ['currency', 'date'],
                ['rate_to_try', 'updated_at']
            );
            $written++;
        }

        $this->info("{$written} rate(s) written to exchange_rates ({$today}).");
        Log::info("rates:fetch completed: {$written} rates written for {$today}.");

        return self::SUCCESS;
    }

    /**
     * Fetch the current price for a Yahoo Finance symbol.
     * Returns null on any HTTP or parse error.
     */
    private function fetchYahooPrice(string $symbol): ?float
    {
        $url = "https://query1.finance.yahoo.com/v8/finance/chart/{$symbol}";

        try {
            $response = Http::withoutVerifying()
                ->timeout(10)
                ->withHeaders([
                    'User-Agent' => 'Mozilla/5.0 (compatible; Paranette/1.0)',
                    'Accept'     => 'application/json',
                ])
                ->get($url, [
                    'interval' => '1m',
                    'range'    => '1d',
                ]);

            if (! $response->ok()) {
                Log::warning("Yahoo Finance HTTP error for {$symbol}: " . $response->status());
                return null;
            }

            $json = $response->json();

            // Try regularMarketPrice from meta first (most reliable)
            $price = $json['chart']['result'][0]['meta']['regularMarketPrice'] ?? null;

            if ($price !== null) {
                return (float) $price;
            }

            // Fallback: last close from indicators
            $closes = $json['chart']['result'][0]['indicators']['quote'][0]['close'] ?? [];
            $closes = array_filter($closes, fn($v) => $v !== null);

            if (! empty($closes)) {
                return (float) end($closes);
            }

            Log::warning("Yahoo Finance: no price found in response for {$symbol}.");
            return null;
        } catch (\Throwable $e) {
            Log::error("Yahoo Finance fetch error for {$symbol}: " . $e->getMessage());
            return null;
        }
    }

    private function makeRow(string $currency, float $rate, string $date): array
    {
        return [
            'currency'    => $currency,
            'rate_to_try' => $rate,
            'date'        => $date,
            'created_at'  => now(),
            'updated_at'  => now(),
        ];
    }
}
