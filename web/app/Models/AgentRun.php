<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AgentRun extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id', 'parent_run_id', 'agent_name', 'status',
        'input', 'output', 'model_used',
        'tokens_in', 'tokens_out',
        'started_at', 'finished_at', 'duration_ms', 'error_message',
    ];

    protected $casts = [
        'input'       => 'array',
        'output'      => 'array',
        'started_at'  => 'datetime',
        'finished_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function markRunning(): void
    {
        $this->update(['status' => 'running', 'started_at' => now()]);
    }

    public function markCompleted(array $output, int $tokensIn, int $tokensOut, string $model): void
    {
        $started = $this->started_at ?? now();
        $this->update([
            'status'      => 'completed',
            'output'      => $output,
            'model_used'  => $model,
            'tokens_in'   => $tokensIn,
            'tokens_out'  => $tokensOut,
            'finished_at' => now(),
            'duration_ms' => (int) ($started->diffInMilliseconds(now())),
        ]);
    }

    public function markFailed(string $error): void
    {
        $this->update([
            'status'        => 'failed',
            'error_message' => $error,
            'finished_at'   => now(),
        ]);
    }
}
