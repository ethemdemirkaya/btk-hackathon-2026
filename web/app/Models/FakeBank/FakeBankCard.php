<?php

namespace App\Models\FakeBank;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FakeBankCard extends Model
{
    protected $fillable = [
        'bank_slug', 'fake_customer_id', 'fake_account_id', 'type',
        'masked_number', 'full_number_encrypted', 'expiry', 'holder_name',
        'credit_limit', 'current_debt', 'statement_day', 'due_day',
    ];

    protected $casts = [
        'credit_limit' => 'decimal:2',
        'current_debt' => 'decimal:2',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(FakeBankCustomer::class, 'fake_customer_id');
    }

    public function account(): BelongsTo
    {
        return $this->belongsTo(FakeBankAccount::class, 'fake_account_id');
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(FakeBankTransaction::class, 'fake_card_id');
    }
}
