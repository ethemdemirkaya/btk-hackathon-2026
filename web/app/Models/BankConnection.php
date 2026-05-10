<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Crypt;

class BankConnection extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'bank_id', 'encrypted_credentials',
        'last_sync_at', 'status', 'webhook_secret',
    ];

    protected $casts = [
        'last_sync_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function bank(): BelongsTo
    {
        return $this->belongsTo(Bank::class);
    }

    public function accounts(): HasMany
    {
        return $this->hasMany(Account::class);
    }

    public function loans(): HasMany
    {
        return $this->hasMany(Loan::class);
    }

    public function getCredentials(): array
    {
        if (! $this->encrypted_credentials) {
            return [];
        }

        return json_decode(Crypt::decryptString($this->encrypted_credentials), true) ?? [];
    }

    public function setCredentials(array $credentials): void
    {
        $this->encrypted_credentials = Crypt::encryptString(json_encode($credentials));
    }
}
