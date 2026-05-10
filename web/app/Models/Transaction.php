<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Transaction extends Model
{
    use HasUuids, SoftDeletes;

    protected $keyType = 'string';
    public    $incrementing = false;

    protected $fillable = [
        'account_id', 'card_id', 'external_id', 'posted_at',
        'amount', 'currency', 'try_amount', 'description', 'raw_description',
        'merchant_name', 'merchant_category', 'category_id', 'subcategory_id',
        'location', 'channel', 'is_recurring', 'parent_transaction_id',
        'installment_no', 'installment_total',
        'classified_by_agent_at', 'anomaly_score', 'raw_payload',
    ];

    protected $casts = [
        'posted_at'               => 'datetime',
        'amount'                  => 'decimal:2',
        'try_amount'              => 'decimal:2',
        'anomaly_score'           => 'decimal:2',
        'is_recurring'            => 'boolean',
        'raw_payload'             => 'array',
        'classified_by_agent_at'  => 'datetime',
    ];

    public function account(): BelongsTo
    {
        return $this->belongsTo(Account::class);
    }

    public function card(): BelongsTo
    {
        return $this->belongsTo(Card::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }
}
