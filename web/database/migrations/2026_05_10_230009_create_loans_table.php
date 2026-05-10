<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('bank_connection_id')->constrained()->cascadeOnDelete();
            $table->string('external_id');
            $table->string('type'); // personal, mortgage, vehicle, commercial
            $table->decimal('principal', 15, 2);
            $table->decimal('current_balance', 15, 2);
            $table->decimal('interest_rate', 8, 4); // yıllık %
            $table->unsignedSmallInteger('total_installments');
            $table->unsignedSmallInteger('paid_installments')->default(0);
            $table->date('next_payment_date')->nullable();
            $table->decimal('next_payment_amount', 15, 2)->nullable();
            $table->date('started_at');
            $table->date('ends_at');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['bank_connection_id', 'external_id']);
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loans');
    }
};
