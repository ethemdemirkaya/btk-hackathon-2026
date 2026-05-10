<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bills', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('type'); // electricity, water, gas, internet, phone
            $table->string('provider')->nullable();
            $table->string('account_number')->nullable();
            $table->decimal('average_amount', 15, 2)->nullable();
            $table->unsignedTinyInteger('due_day')->nullable(); // 1-31
            $table->boolean('is_autopay')->default(false);
            $table->foreignId('autopay_account_id')->nullable()->constrained('accounts')->nullOnDelete();
            $table->timestamp('last_paid_at')->nullable();
            $table->decimal('last_amount', 15, 2)->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bills');
    }
};
