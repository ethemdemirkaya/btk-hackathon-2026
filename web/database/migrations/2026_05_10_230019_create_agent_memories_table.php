<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('agent_memories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // preference, pattern, fact
            $table->text('content');
            $table->unsignedTinyInteger('importance')->default(5); // 1-10
            $table->timestamp('last_recalled_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'importance']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('agent_memories');
    }
};
