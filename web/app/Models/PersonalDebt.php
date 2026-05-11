<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PersonalDebt extends Model
{
    protected $fillable = [
        'user_id',
        'transaction_id',
        'contact_name',
        'amount',
        'direction',
        'note',
        'is_settled',
        'settled_at',
    ];

    protected $casts = [
        'amount'     => 'decimal:2',
        'is_settled' => 'boolean',
        'settled_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
