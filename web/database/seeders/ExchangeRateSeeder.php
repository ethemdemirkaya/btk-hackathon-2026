<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds 35 days of realistic exchange rate history for May 2026 Turkey market.
 * Used as fallback when live Yahoo / OpenER APIs are unavailable.
 *
 * Rates are approximate mid-market TRY values for the period Apr–May 2026.
 * JPY stored per 1 JPY (display layer multiplies by 100 for "per 100 JPY" view).
 */
class ExchangeRateSeeder extends Seeder
{
    // Base rates (mid-market, May 12 2026)
    private const BASE = [
        'USD' => 38.55,
        'EUR' => 43.20,
        'GBP' => 50.10,
        'XAU' => 4095.00,  // gram gold in TRY (≈ $3 270/oz × 38.55 / 31.1035)
        'CHF' => 44.80,
        'JPY' => 0.2665,   // per 1 JPY
        'AUD' => 24.90,
    ];

    // Daily drift per currency (simulates trending movement)
    private const DRIFT = [
        'USD' => -0.035,
        'EUR' => -0.030,
        'GBP' => -0.025,
        'XAU' => -8.50,
        'CHF' => -0.020,
        'JPY' => -0.0003,
        'AUD' => -0.015,
    ];

    // Max random noise per currency per day
    private const NOISE = [
        'USD' => 0.18,
        'EUR' => 0.22,
        'GBP' => 0.28,
        'XAU' => 45.0,
        'CHF' => 0.20,
        'JPY' => 0.0012,
        'AUD' => 0.14,
    ];

    public function run(): void
    {
        DB::table('exchange_rates')->truncate();

        $today  = Carbon::today();
        $rows   = [];
        $days   = 35;

        // Build 35 days of history ending today
        for ($i = $days - 1; $i >= 0; $i--) {
            $date = $today->copy()->subDays($i)->toDateString();

            foreach (self::BASE as $currency => $base) {
                // Linear drift from $days ago to today
                $drift    = self::DRIFT[$currency] * ($days - 1 - $i);
                $noise    = (mt_rand(-1000, 1000) / 1000) * self::NOISE[$currency];
                $rate     = round($base + $drift + $noise, $currency === 'XAU' ? 2 : 4);

                $rows[] = [
                    'currency'    => $currency,
                    'rate_to_try' => max(0.0001, $rate),
                    'date'        => $date,
                    'created_at'  => now(),
                    'updated_at'  => now(),
                ];
            }
        }

        // Insert in chunks to avoid huge single query
        foreach (array_chunk($rows, 100) as $chunk) {
            DB::table('exchange_rates')->insertOrIgnore($chunk);
        }

        $this->command->info('✓ ExchangeRateSeeder: ' . count($rows) . ' kur kaydı eklendi (' . $days . ' gün × ' . count(self::BASE) . ' döviz).');
    }
}
