<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Subscription extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'name', 'merchant_name', 'amount', 'currency',
        'billing_cycle', 'next_billing_date', 'started_at', 'cancelled_at',
        'auto_detected', 'linked_transaction_pattern', 'category_id', 'status',
    ];

    protected $casts = [
        'amount'               => 'decimal:2',
        'next_billing_date'    => 'date',
        'started_at'           => 'date',
        'cancelled_at'         => 'date',
        'auto_detected'        => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function monthlyEquivalent(): float
    {
        return match ($this->billing_cycle) {
            'weekly'    => (float) $this->amount * 4.33,
            'monthly'   => (float) $this->amount,
            'quarterly' => (float) $this->amount / 3,
            'yearly'    => (float) $this->amount / 12,
            default     => (float) $this->amount,
        };
    }
}
