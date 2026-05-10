<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('bank_connection_id')->constrained()->cascadeOnDelete();
            $table->string('external_id');
            $table->string('account_type'); // checking, savings, investment
            $table->string('iban', 34)->nullable();
            $table->string('currency', 3)->default('TRY');
            $table->decimal('balance', 15, 2)->default(0);
            $table->decimal('available_balance', 15, 2)->default(0);
            $table->string('nickname')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['bank_connection_id', 'external_id']);
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('accounts');
    }
};
