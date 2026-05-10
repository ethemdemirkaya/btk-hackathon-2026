<?php

namespace App\Models\FakeBank;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FakeBankTransaction extends Model
{
    protected $fillable = [
        'bank_slug', 'fake_account_id', 'fake_card_id', 'external_id',
        'posted_at', 'amount', 'currency', 'description', 'merchant_name',
        'channel', 'installment_no', 'installment_total',
    ];

    protected $casts = [
        'posted_at' => 'datetime',
        'amount'    => 'decimal:2',
    ];

    public function account(): BelongsTo
    {
        return $this->belongsTo(FakeBankAccount::class, 'fake_account_id');
    }

    public function card(): BelongsTo
    {
        return $this->belongsTo(FakeBankCard::class, 'fake_card_id');
    }
}
