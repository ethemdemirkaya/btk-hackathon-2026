<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Receipt extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id',
        'transaction_id',
        'image_path',
        'ocr_raw_text',
        'ocr_extracted',
        'merchant_name',
        'total_amount',
        'vat_amount',
        'items',
        'purchased_at',
        'warranty_until',
    ];

    protected $casts = [
        'ocr_extracted' => 'array',
        'items'         => 'array',
        'purchased_at'  => 'datetime',
        'total_amount'  => 'decimal:2',
        'vat_amount'    => 'decimal:2',
    ];

    // Manual accessor so DB strings 'null'/''/null all return PHP null gracefully.
    public function getWarrantyUntilAttribute(mixed $value): ?\Carbon\Carbon
    {
        if ($value === null || $value === '' || strtolower((string) $value) === 'null') {
            return null;
        }
        try {
            return \Carbon\Carbon::parse($value);
        } catch (\Throwable) {
            return null;
        }
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getCategoryLabelAttribute(): string
    {
        return $this->ocr_extracted['category'] ?? 'Diğer';
    }
}
