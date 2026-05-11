<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('portfolio_assets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('asset_type', [
                'gold_gram', 'gold_quarter', 'gold_republic',
                'usd', 'eur', 'gbp',
                'btc', 'eth',
                'bist', 'fund', 'mevduat', 'other',
            ]);
            $table->string('name', 120); // e.g. "THYAO", "USD", "Altın gram"
            $table->decimal('quantity', 18, 8);     // how many units
            $table->decimal('buy_price_try', 15, 2); // purchase price in TRY per unit
            $table->date('buy_date');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'asset_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('portfolio_assets');
    }
};
