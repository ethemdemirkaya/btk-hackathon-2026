<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('account_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type'); // credit, debit, prepaid
            $table->string('masked_number', 19); // **** **** **** 1234
            $table->unsignedTinyInteger('expiry_month');
            $table->unsignedSmallInteger('expiry_year');
            $table->string('holder_name');
            $table->decimal('credit_limit', 15, 2)->nullable();
            $table->decimal('current_debt', 15, 2)->default(0);
            $table->decimal('available_limit', 15, 2)->nullable();
            $table->unsignedTinyInteger('statement_day')->nullable(); // 1-31
            $table->unsignedTinyInteger('due_day')->nullable();       // 1-31
            $table->timestamps();
            $table->softDeletes();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cards');
    }
};
