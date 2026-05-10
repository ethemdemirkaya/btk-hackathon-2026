<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('icon')->nullable();
            $table->string('color', 7)->nullable(); // hex
            $table->boolean('is_essential')->default(false);
            // TÜİK'in 14 kategorisine mapping için
            $table->string('tuik_category_slug')->nullable();
            $table->timestamps();

            $table->index('tuik_category_slug');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
