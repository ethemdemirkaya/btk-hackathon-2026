<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Card extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'account_id', 'type', 'masked_number',
        'expiry_month', 'expiry_year', 'holder_name',
        'credit_limit', 'current_debt', 'available_limit',
        'statement_day', 'due_day',
    ];

    protected $casts = [
        'credit_limit'   => 'decimal:2',
        'current_debt'   => 'decimal:2',
        'available_limit'=> 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function account(): BelongsTo
    {
        return $this->belongsTo(Account::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
