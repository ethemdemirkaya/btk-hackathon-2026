<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Maps seeded transaction merchant names to category IDs.
 * Run after UserBankConnectionSeeder so transactions exist.
 */
class TransactionCategorySeeder extends Seeder
{
    // merchant name keyword (case-insensitive) => category slug
    private const MAP = [
        'migros'           => 'market',
        'carrefoursa'      => 'market',
        'a101'             => 'market',
        'bim'              => 'market',
        'şok market'       => 'market',
        'sok market'       => 'market',
        'özdilek'          => 'market',
        'ozdilek'          => 'market',

        'sushi lab'        => 'restoran-kafe',
        'dürümcü'          => 'restoran-kafe',
        'durumcu'          => 'restoran-kafe',
        'köfteci'          => 'restoran-kafe',
        'kofteci'          => 'restoran-kafe',
        'popeyes'          => 'restoran-kafe',
        'nusret'           => 'restoran-kafe',
        'pide'             => 'restoran-kafe',
        'burger'           => 'restoran-kafe',
        'pizza'            => 'restoran-kafe',
        'bahçe'            => 'restoran-kafe',
        'bahce'            => 'restoran-kafe',
        'starbucks'        => 'restoran-kafe',
        'gloria jeans'     => 'restoran-kafe',
        'kahve dünyası'    => 'restoran-kafe',
        'kahve dunyasi'    => 'restoran-kafe',
        'caribou'          => 'restoran-kafe',
        'espresso lab'     => 'restoran-kafe',

        'iett'             => 'toplu-tasima',
        'beltur'           => 'toplu-tasima',
        'dolmuş'           => 'toplu-tasima',
        'dolmus'           => 'toplu-tasima',
        'uber'             => 'taksi-servis',
        'bitaksi'          => 'taksi-servis',

        'bp akaryakıt'     => 'yakit',
        'bp akaryakit'     => 'yakit',
        'shell'            => 'yakit',
        'total enerji'     => 'yakit',
        'opet'             => 'yakit',

        'netflix'          => 'dijital-abonelik',
        'spotify'          => 'dijital-abonelik',
        'youtube premium'  => 'dijital-abonelik',
        'icloud'           => 'dijital-abonelik',
        'gym'              => 'spor',

        'igdas'            => 'dogalgaz',
        'İgdaş'            => 'dogalgaz',
        'tedas'            => 'elektrik',
        'tedaş'            => 'elektrik',
        'iski'             => 'su',
        'İski'             => 'su',
        'türk telekom'     => 'internet',
        'turk telekom'     => 'internet',

        'amazon'           => 'diger',
        'trendyol'         => 'giyim-aksesuar',
        'hepsiburada'      => 'diger',
        'n11'              => 'diger',
        'gittigidiyor'     => 'diger',
    ];

    public function run(): void
    {
        // Build slug → id map
        $slugToId = DB::table('categories')
            ->pluck('id', 'slug')
            ->toArray();

        $updated = 0;

        foreach (self::MAP as $keyword => $slug) {
            $categoryId = $slugToId[$slug] ?? null;
            if (! $categoryId) continue;

            $affected = DB::table('transactions')
                ->whereNull('category_id')
                ->whereNotNull('merchant_name')
                ->whereRaw('LOWER(merchant_name) LIKE ?', ['%' . mb_strtolower($keyword) . '%'])
                ->update(['category_id' => $categoryId]);

            $updated += $affected;
        }

        $this->command->info("✓ TransactionCategorySeeder: {$updated} işlem kategorize edildi.");
    }
}
