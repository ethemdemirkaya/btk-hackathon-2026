<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // TÜİK'in 14 kategorili horizontalBar graph'ından gelen veri
        Schema::create('inflation_category_rates', function (Blueprint $table) {
            $table->id();
            $table->unsignedSmallInteger('period_year');
            $table->unsignedTinyInteger('period_month'); // 1-12
            // saglik, diger, finans, lokanta, genel, mobilya, giyim,
            // alkol, gida, konut, egitim, eglence, haberlesme, ulastirma
            $table->string('tuik_category_slug', 30);
            $table->decimal('annual_change_rate', 8, 4);
            $table->timestamp('fetched_at');
            $table->timestamps();

            $table->unique(['period_year', 'period_month', 'tuik_category_slug'], 'icr_period_category_unique');
            $table->index('tuik_category_slug');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inflation_category_rates');
    }
};
