<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('anomalies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('transaction_id')->nullable();
            $table->string('type'); // unusual_amount, new_merchant, unusual_time, duplicate
            $table->decimal('score', 5, 2); // 0-100
            $table->text('reason');
            $table->string('status')->default('open'); // open, reviewed, dismissed
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('anomalies');
    }
};
