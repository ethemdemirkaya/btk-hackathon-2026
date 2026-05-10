<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 20)->nullable()->after('email');
            $table->date('birth_date')->nullable()->after('phone');
            $table->decimal('monthly_income', 15, 2)->nullable()->after('birth_date');
            $table->boolean('inflation_aware')->default(false)->after('monthly_income');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['phone', 'birth_date', 'monthly_income', 'inflation_aware']);
        });
    }
};
