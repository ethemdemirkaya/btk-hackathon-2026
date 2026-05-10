<?php

namespace App\Models\FakeBank;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FakeBankOauthToken extends Model
{
    protected $fillable = [
        'bank_slug', 'access_token', 'refresh_token',
        'fake_customer_id', 'scopes', 'expires_at',
    ];

    protected $casts = [
        'scopes'     => 'array',
        'expires_at' => 'datetime',
    ];

    public function fakeBankCustomer(): BelongsTo
    {
        return $this->belongsTo(FakeBankCustomer::class, 'fake_customer_id');
    }
}
