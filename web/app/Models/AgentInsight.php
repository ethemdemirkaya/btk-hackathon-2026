<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AgentInsight extends Model
{
    protected $fillable = [
        'user_id', 'agent_name', 'type', 'title', 'body',
        'action_link', 'importance', 'is_read', 'is_dismissed', 'expires_at',
    ];

    protected $casts = [
        'is_read'      => 'boolean',
        'is_dismissed' => 'boolean',
        'expires_at'   => 'datetime',
        'importance'   => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
