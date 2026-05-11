<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('financial_health_scores', function (Blueprint $table) {
            $table->unsignedTinyInteger('debt_ratio_score')->default(0)->after('score');
            $table->unsignedTinyInteger('savings_rate_score')->default(0)->after('debt_ratio_score');
            $table->unsignedTinyInteger('emergency_fund_score')->default(0)->after('savings_rate_score');
            $table->unsignedTinyInteger('expense_consistency_score')->default(0)->after('emergency_fund_score');
            $table->json('details')->nullable()->after('expense_consistency_score');
        });
    }

    public function down(): void
    {
        Schema::table('financial_health_scores', function (Blueprint $table) {
            $table->dropColumn([
                'debt_ratio_score', 'savings_rate_score',
                'emergency_fund_score', 'expense_consistency_score', 'details',
            ]);
        });
    }
};
