<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inflation_rates', function (Blueprint $table) {
            $table->id();
            $table->unsignedSmallInteger('period_year');
            $table->unsignedTinyInteger('period_month'); // 1-12
            $table->decimal('headline_annual_rate', 8, 4); // yıllık TÜFE
            $table->string('source')->default('tuik');
            $table->timestamp('fetched_at');
            $table->json('raw_payload')->nullable();
            $table->timestamps();

            $table->unique(['period_year', 'period_month', 'source']);
            $table->index(['period_year', 'period_month']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inflation_rates');
    }
};
