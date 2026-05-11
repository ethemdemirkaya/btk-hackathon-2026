<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PortfolioAsset extends Model
{
    protected $fillable = [
        'user_id',
        'asset_type',
        'name',
        'quantity',
        'buy_price_try',
        'buy_date',
        'notes',
    ];

    protected $casts = [
        'buy_date'      => 'date',
        'quantity'      => 'decimal:8',
        'buy_price_try' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Total purchase cost in TRY.
     */
    public function buyValueTry(): float
    {
        return (float) $this->quantity * (float) $this->buy_price_try;
    }

    /**
     * Human-readable Turkish label for the asset type.
     */
    public static function typeLabel(string $type): string
    {
        return match ($type) {
            'gold_gram'      => 'Altın (gram)',
            'gold_quarter'   => 'Çeyrek Altın',
            'gold_republic'  => 'Cumhuriyet Altını',
            'usd'            => 'Amerikan Doları (USD)',
            'eur'            => 'Euro (EUR)',
            'gbp'            => 'İngiliz Sterlini (GBP)',
            'btc'            => 'Bitcoin (BTC)',
            'eth'            => 'Ethereum (ETH)',
            'bist'           => 'Hisse Senedi (BIST)',
            'fund'           => 'Yatırım Fonu',
            'mevduat'        => 'Vadeli Mevduat',
            'other'          => 'Diğer',
            default          => ucfirst($type),
        };
    }

    /**
     * Tabler icon class for the asset type.
     */
    public static function typeIcon(string $type): string
    {
        return match ($type) {
            'gold_gram', 'gold_quarter', 'gold_republic' => 'tabler-coins',
            'usd'      => 'tabler-currency-dollar',
            'eur'      => 'tabler-currency-euro',
            'gbp'      => 'tabler-currency-pound',
            'btc', 'eth' => 'tabler-currency-bitcoin',
            'bist'     => 'tabler-chart-candle',
            'fund'     => 'tabler-chart-area',
            'mevduat'  => 'tabler-piggy-bank',
            default    => 'tabler-briefcase',
        };
    }

    /**
     * Bootstrap color label for the asset type.
     */
    public static function typeColor(string $type): string
    {
        return match ($type) {
            'gold_gram', 'gold_quarter', 'gold_republic' => 'warning',
            'usd'      => 'success',
            'eur'      => 'primary',
            'gbp'      => 'info',
            'btc'      => 'danger',
            'eth'      => 'secondary',
            'bist'     => 'primary',
            'fund'     => 'info',
            'mevduat'  => 'success',
            default    => 'secondary',
        };
    }
}
