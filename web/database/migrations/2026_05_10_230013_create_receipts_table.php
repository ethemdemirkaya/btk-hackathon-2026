<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('receipts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('transaction_id')->nullable();
            $table->string('image_path');
            $table->text('ocr_raw_text')->nullable();
            $table->json('ocr_extracted')->nullable();    // structured OCR output
            $table->string('merchant_name')->nullable();
            $table->decimal('total_amount', 15, 2)->nullable();
            $table->decimal('vat_amount', 15, 2)->nullable();
            $table->json('items')->nullable();            // line items
            $table->timestamp('purchased_at')->nullable();
            $table->date('warranty_until')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('receipts');
    }
};
