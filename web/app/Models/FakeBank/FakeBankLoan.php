<?php

namespace App\Models\FakeBank;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FakeBankLoan extends Model
{
    protected $fillable = [
        'bank_slug', 'fake_customer_id', 'external_id', 'type',
        'principal', 'current_balance', 'interest_rate',
        'total_installments', 'paid_installments',
        'next_payment_date', 'next_payment_amount',
    ];

    protected $casts = [
        'principal'            => 'decimal:2',
        'current_balance'      => 'decimal:2',
        'interest_rate'        => 'decimal:4',
        'next_payment_date'    => 'date',
        'next_payment_amount'  => 'decimal:2',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(FakeBankCustomer::class, 'fake_customer_id');
    }
}
