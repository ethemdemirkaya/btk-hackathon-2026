<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PortfolioAsset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InvestmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $assets = PortfolioAsset::where('user_id', $user->id)
            ->orderBy('asset_type')
            ->orderBy('created_at')
            ->get();

        $rates = DB::table('exchange_rates')
            ->whereIn('currency', ['USD', 'EUR', 'GBP', 'XAU', 'GOLD', 'BTC'])
            ->orderByDesc('date')
            ->get()
            ->unique('currency')
            ->keyBy('currency');

        $assets = $assets->map(function (PortfolioAsset $asset) use ($rates) {
            $qty      = (float) $asset->quantity;
            $buyPrice = (float) $asset->buy_price_try;
            $buyValue = $qty * $buyPrice;

            $currentPrice = $this->resolveCurrentPrice($asset->asset_type, $rates, $buyPrice);
            $currentValue = $qty * $currentPrice;
            $gainLoss     = $currentValue - $buyValue;
            $gainLossPct  = $buyValue > 0 ? round(($gainLoss / $buyValue) * 100, 2) : 0.0;

            return [
                'id'                => $asset->id,
                'asset_type'        => $asset->asset_type,
                'type_label'        => PortfolioAsset::typeLabel($asset->asset_type),
                'name'              => $asset->name,
                'quantity'          => (float) $asset->quantity,
                'buy_price_try'     => (float) $asset->buy_price_try,
                'buy_date'          => $asset->buy_date?->toDateString(),
                'notes'             => $asset->notes,
                'current_price_try' => round($currentPrice, 2),
                'current_value_try' => round($currentValue, 2),
                'buy_value_try'     => round($buyValue, 2),
                'gain_loss_try'     => round($gainLoss, 2),
                'gain_loss_pct'     => $gainLossPct,
            ];
        });

        $totalCurrentValue = $assets->sum('current_value_try');
        $totalBuyValue     = $assets->sum('buy_value_try');
        $totalGainLoss     = $totalCurrentValue - $totalBuyValue;

        return response()->json([
            'assets' => $assets->values(),
            'totals' => [
                'current_value'  => round($totalCurrentValue, 2),
                'buy_value'      => round($totalBuyValue, 2),
                'gain_loss'      => round($totalGainLoss, 2),
                'gain_loss_pct'  => $totalBuyValue > 0
                    ? round(($totalGainLoss / $totalBuyValue) * 100, 2)
                    : 0.0,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'asset_type'    => 'required|in:gold_gram,gold_quarter,gold_republic,usd,eur,gbp,btc,eth,bist,fund,mevduat,other',
            'name'          => 'required|string|max:120',
            'quantity'      => 'required|numeric|min:0.0001',
            'buy_price_try' => 'required|numeric|min:0.01',
            'buy_date'      => 'required|date',
            'notes'         => 'nullable|string|max:1000',
        ]);

        $asset = PortfolioAsset::create(['user_id' => $request->user()->id] + $data);

        return response()->json(['asset' => $asset], 201);
    }

    public function liveRates(): JsonResponse
    {
        $currencies = ['USD', 'EUR', 'GBP', 'XAU', 'BTC', 'ETH'];

        $dbRates = DB::table('exchange_rates')
            ->whereIn('currency', $currencies)
            ->orderByDesc('date')
            ->orderByDesc('updated_at')
            ->get()
            ->unique('currency')
            ->keyBy('currency');

        $symbols = [
            'USD' => 'USDTRY=X',
            'EUR' => 'EURTRY=X',
            'GBP' => 'GBPTRY=X',
            'XAU' => 'XAUTRY=X',
            'BTC' => 'BTC-USD',
            'ETH' => 'ETH-USD',
        ];

        $rates     = [];
        $updatedAt = null;

        foreach ($currencies as $currency) {
            if (isset($dbRates[$currency])) {
                $row = $dbRates[$currency];
                $rates[$currency] = [
                    'rate'   => (float) $row->rate_to_try,
                    'symbol' => $symbols[$currency] ?? $currency,
                ];

                $rowUpdatedAt = $row->updated_at ?? $row->date;
                if ($updatedAt === null || $rowUpdatedAt > $updatedAt) {
                    $updatedAt = $rowUpdatedAt;
                }
            }
        }

        return response()->json([
            'rates'      => $rates,
            'updated_at' => $updatedAt,
        ]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $asset = PortfolioAsset::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $data = $request->validate([
            'quantity'      => 'sometimes|numeric|min:0.0001',
            'buy_price_try' => 'sometimes|numeric|min:0.01',
            'buy_date'      => 'sometimes|date',
            'name'          => 'sometimes|string|max:120',
            'notes'         => 'nullable|string|max:1000',
        ]);

        $asset->update($data);

        return response()->json(['asset' => $asset]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $asset = PortfolioAsset::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $asset->delete();

        return response()->json(['message' => 'Varlık silindi.']);
    }

    private function resolveCurrentPrice(string $type, $rates, float $buyPrice): float
    {
        $xauRate  = isset($rates['XAU'])  ? (float) $rates['XAU']->rate_to_try  : null;
        $goldRate = isset($rates['GOLD']) ? (float) $rates['GOLD']->rate_to_try : null;
        $gramGold = $xauRate ?? $goldRate;

        return match ($type) {
            'gold_gram'     => $gramGold ?? $buyPrice,
            'gold_quarter'  => $gramGold !== null ? $gramGold * 6.6  : $buyPrice,
            'gold_republic' => $gramGold !== null ? $gramGold * 7.2  : $buyPrice,
            'usd'           => isset($rates['USD']) ? (float) $rates['USD']->rate_to_try : $buyPrice,
            'eur'           => isset($rates['EUR']) ? (float) $rates['EUR']->rate_to_try : $buyPrice,
            'gbp'           => isset($rates['GBP']) ? (float) $rates['GBP']->rate_to_try : $buyPrice,
            'btc'           => isset($rates['BTC']) ? (float) $rates['BTC']->rate_to_try : $buyPrice,
            default         => $buyPrice,
        };
    }
}
