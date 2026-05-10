<?php

namespace App\Models\FakeBank;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FakeBankAccount extends Model
{
    protected $fillable = [
        'bank_slug', 'fake_customer_id', 'external_id', 'account_type',
        'iban', 'currency', 'balance', 'available_balance', 'opened_at',
    ];

    protected $casts = [
        'balance'           => 'decimal:2',
        'available_balance' => 'decimal:2',
        'opened_at'         => 'date',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(FakeBankCustomer::class, 'fake_customer_id');
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(FakeBankTransaction::class, 'fake_account_id');
    }

    public function cards(): HasMany
    {
        return $this->hasMany(FakeBankCard::class, 'fake_account_id');
    }
}
