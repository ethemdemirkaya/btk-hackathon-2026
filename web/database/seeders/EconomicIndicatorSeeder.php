<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class EconomicIndicatorSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('economic_indicators')->truncate();

        $indicators = [
            // Current period indicators
            ['period' => '2026-04', 'type' => 'tufe',                  'value' => 37.86, 'trend' => 'down'],
            ['period' => '2026-03', 'type' => 'unemployment',          'value' => 8.40,  'trend' => 'flat'],
            ['period' => '2026-01', 'type' => 'gdp_growth',            'value' => 3.20,  'trend' => 'up'],
            ['period' => '2026-03', 'type' => 'industrial_production',  'value' => 4.10,  'trend' => 'up'],
            ['period' => '2026-04', 'type' => 'consumer_confidence',   'value' => 82.40, 'trend' => 'up'],
            ['period' => '2026-01', 'type' => 'population',            'value' => 85.37, 'trend' => 'up'],

            // Historical TUFE for trend chart
            ['period' => '2025-11', 'type' => 'tufe', 'value' => 47.09, 'trend' => 'down'],
            ['period' => '2025-12', 'type' => 'tufe', 'value' => 44.38, 'trend' => 'down'],
            ['period' => '2026-01', 'type' => 'tufe', 'value' => 42.12, 'trend' => 'down'],
            ['period' => '2026-02', 'type' => 'tufe', 'value' => 39.05, 'trend' => 'down'],
            ['period' => '2026-03', 'type' => 'tufe', 'value' => 38.52, 'trend' => 'down'],
        ];

        foreach ($indicators as $ind) {
            DB::table('economic_indicators')->insertOrIgnore(array_merge($ind, [
                'fetched_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }

        $this->command->info('✓ EconomicIndicatorSeeder: ' . count($indicators) . ' gösterge eklendi.');
    }
}
