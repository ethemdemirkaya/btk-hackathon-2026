<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Bank extends Model
{
    protected $fillable = [
        'name', 'slug', 'logo', 'api_base_url', 'auth_type', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function connections(): HasMany
    {
        return $this->hasMany(BankConnection::class);
    }
}
