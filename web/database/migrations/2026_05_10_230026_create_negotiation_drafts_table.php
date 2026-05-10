<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('negotiation_drafts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('target'); // bank_fee, subscription, bill
            $table->string('recipient_name')->nullable();
            $table->string('subject');
            $table->longText('body');
            $table->string('status')->default('draft'); // draft, sent, accepted, rejected
            $table->uuid('generated_by_agent_id')->nullable();
            $table->timestamps();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('negotiation_drafts');
    }
};
