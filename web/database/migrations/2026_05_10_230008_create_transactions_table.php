<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('account_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('card_id')->nullable()->constrained()->nullOnDelete();
            $table->string('external_id')->nullable();
            $table->timestamp('posted_at');
            $table->decimal('amount', 15, 2);
            $table->string('currency', 3)->default('TRY');
            $table->decimal('try_amount', 15, 2);         // TRY karşılığı
            $table->string('description');
            $table->string('raw_description')->nullable();
            $table->string('merchant_name')->nullable();
            $table->string('merchant_category')->nullable();
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('subcategory_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->string('location')->nullable();
            $table->string('channel')->nullable(); // pos, atm, online, transfer
            $table->boolean('is_recurring')->default(false);
            $table->uuid('parent_transaction_id')->nullable();
            $table->unsignedTinyInteger('installment_no')->nullable();
            $table->unsignedTinyInteger('installment_total')->nullable();
            $table->timestamp('classified_by_agent_at')->nullable();
            $table->decimal('anomaly_score', 5, 2)->nullable();
            $table->json('raw_payload')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['account_id', 'posted_at']);
            $table->index(['card_id', 'posted_at']);
            $table->index('posted_at');
            $table->index('is_recurring');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
