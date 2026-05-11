<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('personal_debts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('transaction_id')->nullable()->index();
            $table->string('contact_name');
            $table->decimal('amount', 15, 2);
            $table->enum('direction', ['given', 'received']); // given=borç verdim, received=borç aldım
            $table->text('note')->nullable();
            $table->boolean('is_settled')->default(false);
            $table->timestamp('settled_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'is_settled']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_debts');
    }
};
