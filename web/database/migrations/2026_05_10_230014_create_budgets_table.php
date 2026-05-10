<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('budgets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained()->cascadeOnDelete();
            $table->string('period'); // monthly, weekly, yearly
            $table->decimal('amount', 15, 2);
            $table->decimal('alert_threshold', 5, 2)->default(80); // % of budget
            $table->timestamps();

            $table->unique(['user_id', 'category_id', 'period']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('budgets');
    }
};
