<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('card_statements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('card_id')->constrained()->cascadeOnDelete();
            $table->date('period_start');
            $table->date('period_end');
            $table->decimal('statement_amount', 15, 2);
            $table->decimal('minimum_payment', 15, 2);
            $table->date('due_date');
            $table->decimal('paid_amount', 15, 2)->default(0);
            $table->boolean('is_paid')->default(false);
            $table->timestamps();

            $table->index(['card_id', 'period_start']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('card_statements');
    }
};
