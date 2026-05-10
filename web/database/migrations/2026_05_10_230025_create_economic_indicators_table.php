<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('economic_indicators', function (Blueprint $table) {
            $table->id();
            $table->string('period'); // YYYY-MM or YYYY-Q1
            $table->string('type'); // tufe, unemployment, gdp_growth, industrial_production, consumer_confidence, population
            $table->decimal('value', 12, 4);
            $table->string('trend')->nullable(); // up, down, flat
            $table->timestamp('fetched_at');
            $table->json('raw_payload')->nullable();
            $table->timestamps();

            $table->unique(['period', 'type']);
            $table->index('type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('economic_indicators');
    }
};
