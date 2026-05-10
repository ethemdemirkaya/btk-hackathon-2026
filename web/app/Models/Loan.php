<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Loan extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'bank_connection_id', 'external_id', 'type',
        'principal', 'current_balance', 'interest_rate',
        'total_installments', 'paid_installments',
        'next_payment_date', 'next_payment_amount',
        'started_at', 'ends_at',
    ];

    protected $casts = [
        'principal'           => 'decimal:2',
        'current_balance'     => 'decimal:2',
        'interest_rate'       => 'decimal:4',
        'next_payment_date'   => 'date',
        'next_payment_amount' => 'decimal:2',
        'started_at'          => 'date',
        'ends_at'             => 'date',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function bankConnection(): BelongsTo
    {
        return $this->belongsTo(BankConnection::class);
    }
}
