<?php

namespace App\Models\FakeBank;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FakeBankCustomer extends Model
{
    protected $fillable = [
        'bank_slug', 'customer_id', 'tckn', 'name', 'email',
        'password_hash', 'api_credentials',
    ];

    protected $casts = [
        'api_credentials' => 'array',
    ];

    public function accounts(): HasMany
    {
        return $this->hasMany(FakeBankAccount::class, 'fake_customer_id');
    }

    public function cards(): HasMany
    {
        return $this->hasMany(FakeBankCard::class, 'fake_customer_id');
    }

    public function loans(): HasMany
    {
        return $this->hasMany(FakeBankLoan::class, 'fake_customer_id');
    }

    public function oauthTokens(): HasMany
    {
        return $this->hasMany(FakeBankOauthToken::class, 'fake_customer_id');
    }
}
