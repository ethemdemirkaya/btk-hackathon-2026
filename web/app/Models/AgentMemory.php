<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AgentMemory extends Model
{
    protected $fillable = [
        'user_id', 'type', 'content', 'importance', 'last_recalled_at',
    ];

    protected $casts = [
        'importance'      => 'integer',
        'last_recalled_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
