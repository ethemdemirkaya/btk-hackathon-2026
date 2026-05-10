<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('merchant_name')->nullable();
            $table->decimal('amount', 15, 2);
            $table->string('currency', 3)->default('TRY');
            $table->string('billing_cycle'); // monthly, yearly, weekly
            $table->date('next_billing_date')->nullable();
            $table->date('started_at')->nullable();
            $table->date('cancelled_at')->nullable();
            $table->boolean('auto_detected')->default(false);
            $table->string('linked_transaction_pattern')->nullable();
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('status')->default('active'); // active, cancelled, paused
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
