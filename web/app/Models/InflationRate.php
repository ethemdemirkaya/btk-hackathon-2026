<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InflationRate extends Model
{
    protected $fillable = [
        'user_id', 'period_year', 'period_month',
        'source', 'annual_rate', 'monthly_rate', 'fetched_at',
    ];

    protected $casts = [
        'annual_rate'  => 'decimal:4',
        'monthly_rate' => 'decimal:4',
        'fetched_at'   => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
