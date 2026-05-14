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

// Yahoo Finance canlı kurlar (USD, EUR, GBP, XAU, BTC, ETH) — her 15 dakikada bir
Schedule::command(FetchExchangeRatesCommand::class)->everyFifteenMinutes();
