<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('agent_insights', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('agent_name');
            $table->string('type'); // warning, tip, opportunity, anomaly
            $table->string('title');
            $table->text('body');
            $table->string('action_link')->nullable();
            $table->unsignedTinyInteger('importance')->default(5); // 1-10
            $table->boolean('is_read')->default(false);
            $table->boolean('is_dismissed')->default(false);
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'is_read', 'is_dismissed']);
            $table->index(['user_id', 'expires_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('agent_insights');
    }
};
