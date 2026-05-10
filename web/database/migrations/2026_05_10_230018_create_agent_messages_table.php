<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('agent_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('session_id', 64);
            $table->string('role'); // user, assistant, system, tool
            $table->longText('content');
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'session_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('agent_messages');
    }
};
