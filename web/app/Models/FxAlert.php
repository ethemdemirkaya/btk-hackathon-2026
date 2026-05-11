<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FxAlert extends Model
{
    protected $fillable = [
        'user_id',
        'currency',
        'condition',
        'threshold',
        'is_active',
        'triggered_at',
    ];

    protected $casts = [
        'threshold'    => 'decimal:4',
        'is_active'    => 'boolean',
        'triggered_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
