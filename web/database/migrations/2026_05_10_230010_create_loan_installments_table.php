<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loan_installments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loan_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('installment_no');
            $table->date('due_date');
            $table->decimal('principal_amount', 15, 2);
            $table->decimal('interest_amount', 15, 2);
            $table->decimal('total_amount', 15, 2);
            $table->timestamp('paid_at')->nullable();
            $table->boolean('is_paid')->default(false);
            $table->timestamps();

            $table->unique(['loan_id', 'installment_no']);
            $table->index(['loan_id', 'due_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loan_installments');
    }
};
