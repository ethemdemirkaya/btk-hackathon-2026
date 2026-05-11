<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Budget extends Model
{
    protected $fillable = [
        'user_id', 'category_id', 'period', 'amount', 'alert_threshold',
    ];

    protected $casts = [
        'amount'          => 'decimal:2',
        'alert_threshold' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function scopeForPeriod($query, string $period)
    {
        return $query->where('period', $period);
    }

    public function scopeCurrentMonth($query)
    {
        return $query->where('period', now()->format('Y-m'));
    }
}
