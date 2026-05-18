<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PortfolioAsset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class InvestmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $assets = PortfolioAsset::where('user_id', $user->id)
            ->orderBy('asset_type')
            ->orderBy('created_at')
            ->get();

        $rates = $this->getLatestRates();

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
        $data = Cache::remember('inv_live_rates_v3', 55, function () {
            try {
                return $this->fetchSparkRates();
            } catch (\Throwable) {
                return $this->dbLiveRates();
            }
        });

        return response()->json($data);
    }

    private function fetchSparkRates(): array
    {
        $resp = Http::withHeaders([
            'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept'     => 'application/json',
        ])->withoutVerifying()->timeout(12)->get('https://query1.finance.yahoo.com/v7/finance/spark', [
            'symbols'           => 'USDTRY=X,EURTRY=X,GBPTRY=X,GC=F,BTC-USD,ETH-USD',
            'range'             => '1d',
            'interval'          => '5m',
            'indicators'        => 'close',
            'includeTimestamps' => 'false',
            'includePrePost'    => 'false',
        ]);

        if (! $resp->ok()) throw new \RuntimeException('Yahoo spark HTTP ' . $resp->status());

        $by = collect($resp->json('spark.result') ?? [])
            ->filter(fn ($r) => ! empty($r['response'][0]['meta']['regularMarketPrice']))
            ->keyBy('symbol');

        if ($by->isEmpty()) throw new \RuntimeException('Yahoo: empty result');

        $usdMeta = $by->get('USDTRY=X')['response'][0]['meta'] ?? null;
        if (! $usdMeta) throw new \RuntimeException('Yahoo: USDTRY missing');
        $usdTry = (float) $usdMeta['regularMarketPrice'];
        if (! $usdTry) throw new \RuntimeException('Yahoo: USDTRY zero');

        $symbolMap = ['USD' => 'USDTRY=X', 'EUR' => 'EURTRY=X', 'GBP' => 'GBPTRY=X'];
        $rates = [];

        foreach ($symbolMap as $code => $sym) {
            $meta = $by->get($sym)['response'][0]['meta'] ?? null;
            if ($meta) {
                $rates[$code] = ['rate' => round((float) $meta['regularMarketPrice'], 4), 'symbol' => $sym];
            }
        }

        // Altın: GC=F USD/oz → TRY/gram
        $gcMeta = $by->get('GC=F')['response'][0]['meta'] ?? null;
        if ($gcMeta) {
            $goldUsd = (float) ($gcMeta['regularMarketPrice'] ?? 0);
            $rates['XAU'] = ['rate' => round(($goldUsd / 31.1035) * $usdTry, 2), 'symbol' => 'GC=F'];
        }

        // Kripto: USD fiyat × USDTRY
        foreach (['BTC' => 'BTC-USD', 'ETH' => 'ETH-USD'] as $code => $sym) {
            $meta = $by->get($sym)['response'][0]['meta'] ?? null;
            if ($meta) {
                $usdPrice = (float) ($meta['regularMarketPrice'] ?? 0);
                $rates[$code] = ['rate' => round($usdPrice * $usdTry, 2), 'symbol' => $sym];
            }
        }

        return ['rates' => $rates, 'updated_at' => now()->toIso8601String(), 'source' => 'yahoo'];
    }

    private function dbLiveRates(): array
    {
        $currencies = ['USD', 'EUR', 'GBP', 'XAU', 'BTC', 'ETH'];
        $dbRates    = DB::table('exchange_rates')
            ->whereIn('currency', $currencies)
            ->orderByDesc('date')
            ->orderByDesc('updated_at')
            ->get()
            ->unique('currency')
            ->keyBy('currency');

        $symbolMap = ['USD' => 'USDTRY=X', 'EUR' => 'EURTRY=X', 'GBP' => 'GBPTRY=X',
                      'XAU' => 'GC=F', 'BTC' => 'BTC-USD', 'ETH' => 'ETH-USD'];
        $rates     = [];
        $updatedAt = null;

        foreach ($currencies as $currency) {
            if (isset($dbRates[$currency])) {
                $row = $dbRates[$currency];
                $rates[$currency] = [
                    'rate'   => (float) $row->rate_to_try,
                    'symbol' => $symbolMap[$currency] ?? $currency,
                ];
                $ts = $row->updated_at ?? $row->date;
                if ($updatedAt === null || $ts > $updatedAt) $updatedAt = $ts;
            }
        }

        return ['rates' => $rates, 'updated_at' => $updatedAt, 'source' => 'db'];
    }

    private function getLatestRates(): array
    {
        $cached = Cache::get('inv_live_rates_v3');
        if ($cached && ! empty($cached['rates'])) {
            return collect($cached['rates'])->map(fn ($r) => (float) ($r['rate'] ?? 0))->all();
        }

        try {
            $live = $this->fetchSparkRates();
            return collect($live['rates'])->map(fn ($r) => (float) ($r['rate'] ?? 0))->all();
        } catch (\Throwable) {
            return DB::table('exchange_rates')
                ->whereIn('currency', ['USD', 'EUR', 'GBP', 'XAU', 'GOLD', 'BTC', 'ETH'])
                ->orderByDesc('date')
                ->get()
                ->unique('currency')
                ->pluck('rate_to_try', 'currency')
                ->map(fn ($r) => (float) $r)
                ->all();
        }
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

    private function resolveCurrentPrice(string $type, array $rates, float $buyPrice): float
    {
        $gramGold = $rates['XAU'] ?? $rates['GOLD'] ?? null;

        return match ($type) {
            'gold_gram'     => $gramGold ?? $buyPrice,
            'gold_quarter'  => $gramGold !== null ? $gramGold * 6.6  : $buyPrice,
            'gold_republic' => $gramGold !== null ? $gramGold * 7.2  : $buyPrice,
            'usd'           => $rates['USD'] ?? $buyPrice,
            'eur'           => $rates['EUR'] ?? $buyPrice,
            'gbp'           => $rates['GBP'] ?? $buyPrice,
            'btc'           => $rates['BTC'] ?? $buyPrice,
            'eth'           => $rates['ETH'] ?? $buyPrice,
            default         => $buyPrice,
        };
    }
}
