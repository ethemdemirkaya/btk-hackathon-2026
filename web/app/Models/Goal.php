<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Goal extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'name', 'target_amount', 'current_amount',
        'target_date', 'monthly_contribution', 'status',
    ];

    protected $casts = [
        'target_amount'       => 'decimal:2',
        'current_amount'      => 'decimal:2',
        'monthly_contribution'=> 'decimal:2',
        'target_date'         => 'date',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function progressPct(): float
    {
        if ((float) $this->target_amount <= 0) {
            return 0;
        }

        return min(100, round((float) $this->current_amount / (float) $this->target_amount * 100, 1));
    }

    public function remainingAmount(): float
    {
        return max(0, (float) $this->target_amount - (float) $this->current_amount);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
}
