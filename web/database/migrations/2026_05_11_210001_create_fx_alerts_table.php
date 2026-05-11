<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fx_alerts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('currency', 10); // USD, EUR, GOLD, etc.
            $table->enum('condition', ['above', 'below']); // alert when rate goes above/below
            $table->decimal('threshold', 15, 4); // the rate threshold in TRY
            $table->boolean('is_active')->default(true);
            $table->timestamp('triggered_at')->nullable(); // when it was last triggered
            $table->timestamps();
            $table->index(['user_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fx_alerts');
    }
};
