<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class CategorizeTransactions extends Command
{
    protected $signature   = 'tx:categorize {--reset : Reset existing category assignments}';
    protected $description = 'Keyword-based category assignment for uncategorized transactions';

    private array $mappings = [
        2  => ['migros','bim','a101','şok','sok','carrefour','market','grocery','tansaş'],
        3  => ['starbucks','mcdonald','burger king','kfc','subway','pizza hut','cafe','restoran','coffee'],
        4  => ['yemeksepeti','getir','uber eats','trendyol yemek'],
        6  => ['shell','bp','opet','petrol ofisi','lukoil','aytemiz','yakıt'],
        7  => ['iett','metro bus','marmaray','izban','istanbulkart','ankarakart','kentkart'],
        8  => ['uber','bitaksi','taxim'],
        10 => ['enerjisa','ayedas','bedas','elektrık','elektrik faturası'],
        11 => ['iski','aski','istanbul su','su fatura'],
        12 => ['igdaş','igdas','enerya','doğalgaz','dogalgaz'],
        13 => ['turk telekom','superonline','fibernet','ttnet','internet abonelik'],
        14 => ['turkcell','vodafone','türk telekom gsm'],
        16 => ['eczane','pharmacy','ecza'],
        17 => ['hastane','klinik','doktor','hospital','medikal'],
        24 => ['netflix','spotify','apple music','youtube premium','disney','exxen','blutv','mubi'],
        25 => ['lc waikiki','mango','zara','h&m','koton','defacto','bershka','pull & bear','lcw'],
        31 => ['mediamarkt','teknosa','vatan','apple store','samsung store','electronics'],
        34 => ['komisyon','hesap işletim','kart aidat','faiz','maaş komisyon'],
    ];

    public function handle(): int
    {
        if ($this->option('reset')) {
            DB::table('transactions')->update(['category_id' => null]);
            $this->info('Category assignments reset.');
        }

        $txns = DB::table('transactions')
            ->where('amount', '<', 0)
            ->whereNull('category_id')
            ->get();

        $this->info("Transactions to categorize: {$txns->count()}");

        $stats   = [];
        $updated = 0;

        foreach ($txns as $tx) {
            $text = mb_strtolower(
                ($tx->description ?? '') . ' ' .
                ($tx->merchant_name ?? '') . ' ' .
                ($tx->merchant_category ?? '')
            );

            $matched = 37; // Diğer
            foreach ($this->mappings as $catId => $keywords) {
                foreach ($keywords as $kw) {
                    if (str_contains($text, $kw)) {
                        $matched = $catId;
                        break 2;
                    }
                }
            }

            DB::table('transactions')->where('id', $tx->id)->update(['category_id' => $matched]);
            $stats[$matched] = ($stats[$matched] ?? 0) + 1;
            $updated++;
        }

        $this->info("Categorized: {$updated}");

        arsort($stats);
        foreach ($stats as $catId => $count) {
            $name = DB::table('categories')->where('id', $catId)->value('name') ?? "Cat#{$catId}";
            $this->line("  {$name}: {$count}");
        }

        return self::SUCCESS;
    }
}
