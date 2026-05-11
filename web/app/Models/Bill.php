<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Bill extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'name', 'type', 'provider', 'account_number',
        'average_amount', 'due_day', 'is_autopay', 'autopay_account_id',
        'last_paid_at', 'last_amount',
    ];

    protected $casts = [
        'is_autopay'   => 'boolean',
        'last_paid_at' => 'datetime',
        'average_amount' => 'decimal:2',
        'last_amount'    => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function autopayAccount(): BelongsTo
    {
        return $this->belongsTo(Account::class, 'autopay_account_id');
    }

    public static function typeLabel(string $type): string
    {
        return match ($type) {
            'electricity' => 'Elektrik',
            'water'       => 'Su',
            'gas'         => 'Doğalgaz',
            'internet'    => 'İnternet',
            'phone'       => 'Telefon',
            'rent'        => 'Kira',
            'insurance'   => 'Sigorta',
            'other'       => 'Diğer',
            default       => ucfirst($type),
        };
    }

    public static function typeIcon(string $type): string
    {
        return match ($type) {
            'electricity' => 'tabler-bolt',
            'water'       => 'tabler-droplet',
            'gas'         => 'tabler-flame',
            'internet'    => 'tabler-wifi',
            'phone'       => 'tabler-device-mobile',
            'rent'        => 'tabler-home',
            'insurance'   => 'tabler-shield-check',
            default       => 'tabler-file-invoice',
        };
    }

    public static function typeColor(string $type): string
    {
        return match ($type) {
            'electricity' => 'warning',
            'water'       => 'info',
            'gas'         => 'danger',
            'internet'    => 'primary',
            'phone'       => 'success',
            'rent'        => 'secondary',
            'insurance'   => 'dark',
            default       => 'secondary',
        };
    }
}
