<?php

namespace App\Console\Commands;

use App\Services\TuikApiService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class FetchTuikDataCommand extends Command
{
    protected $signature   = 'tuik:fetch {--month= : YYYY-MM biçiminde ay (varsayılan: geçen ay)}';
    protected $description = 'TÜİK EVDS API\'den TÜFE enflasyon verilerini çeker ve kaydeder';

    public function handle(TuikApiService $tuikService): int
    {
        $monthInput = $this->option('month');

        if ($monthInput) {
            try {
                $period = Carbon::createFromFormat('Y-m', $monthInput)->startOfMonth();
            } catch (\Throwable) {
                $this->error("Geçersiz ay formatı: {$monthInput}. Beklenen: YYYY-MM");
                return self::FAILURE;
            }
        } else {
            $period = Carbon::now()->subMonth()->startOfMonth();
        }

        $this->info("TÜİK verisi çekiliyor: " . $period->format('Y-m') . "...");

        $result = $tuikService->fetchAndStore($period);

        if ($result['success']) {
            $source = match ($result['source']) {
                'api'      => '<info>EVDS API</info>',
                'fallback' => '<comment>yerleşik yedek veri (API anahtarı yok)</comment>',
                'cache'    => '<comment>önbellek (24 saatlik cache)</comment>',
                default    => $result['source'],
            };

            $this->line("  ✓ Dönem: {$result['period']}  Kaynak: {$source}");
            $this->line("  ✓ Manşet TÜFE: %" . $tuikService->getLatestHeadlineRate());
            return self::SUCCESS;
        }

        $this->error('TÜİK veri çekimi başarısız.');
        return self::FAILURE;
    }
}
