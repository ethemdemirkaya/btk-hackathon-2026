<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinancialHealthScore extends Model
{
    protected $fillable = [
        'user_id', 'score', 'debt_ratio_score', 'savings_rate_score',
        'expense_consistency_score', 'emergency_fund_score',
        'details', 'calculated_at',
    ];

    protected $casts = [
        'score'                    => 'integer',
        'debt_ratio_score'         => 'integer',
        'savings_rate_score'       => 'integer',
        'expense_consistency_score'=> 'integer',
        'emergency_fund_score'     => 'integer',
        'details'                  => 'array',
        'calculated_at'            => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
