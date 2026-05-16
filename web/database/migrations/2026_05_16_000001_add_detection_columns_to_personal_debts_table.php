<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('personal_debts', function (Blueprint $table) {
            $table->boolean('is_auto_detected')->default(false)->after('is_settled');
            $table->uuid('repayment_transaction_id')->nullable()->after('transaction_id');
            $table->decimal('profit_amount', 15, 2)->nullable()->after('amount');
        });
    }

    public function down(): void
    {
        Schema::table('personal_debts', function (Blueprint $table) {
            $table->dropColumn(['is_auto_detected', 'repayment_transaction_id', 'profit_amount']);
        });
    }
};
