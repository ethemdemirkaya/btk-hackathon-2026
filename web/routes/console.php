<?php

use App\Console\Commands\FetchTuikDataCommand;
use App\Console\Commands\FetchExchangeRatesCommand;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// TÜİK enflasyon verisi her gün 06:00'da çekilir
Schedule::command(FetchTuikDataCommand::class)->dailyAt('06:00');

// TCMB döviz kurları + altın fiyatı — hafta içi 15:45'te (TCMB 15:30'da yayınlar)
Schedule::command(FetchExchangeRatesCommand::class)->weekdays()->dailyAt('15:45');
