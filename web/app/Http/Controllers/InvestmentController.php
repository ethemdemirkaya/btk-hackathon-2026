<?php

namespace App\Http\Controllers;

use App\Models\PortfolioAsset;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\View\View;

class InvestmentController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        // ── 1. Fetch portfolio assets ────────────────────────────────────────
        $assets = PortfolioAsset::where('user_id', $user->id)
            ->orderBy('asset_type')
            ->orderBy('created_at')
            ->get();

        // ── 2. Live rates (cache → Yahoo spark → DB fallback) ────────────────
        $rates = $this->getLatestRates();

        // ── 3. Enrich each asset with current pricing & P&L ─────────────────
        $assets = $assets->map(function (PortfolioAsset $asset) use ($rates) {
            $qty      = (float) $asset->quantity;
            $buyPrice = (float) $asset->buy_price_try;
            $buyValue = $qty * $buyPrice;

            $currentPrice = $this->resolveCurrentPrice($asset->asset_type, $rates, $buyPrice);
            $currentValue = $qty * $currentPrice;

            $gainLoss    = $currentValue - $buyValue;
            $gainLossPct = $buyValue > 0
                ? round(($gainLoss / $buyValue) * 100, 2)
                : 0.0;

            $asset->current_price_try = round($currentPrice, 2);
            $asset->current_value_try = round($currentValue, 2);
            $asset->buy_value_try     = round($buyValue, 2);
            $asset->gain_loss_try     = round($gainLoss, 2);
            $asset->gain_loss_pct     = $gainLossPct;
            $asset->type_label        = PortfolioAsset::typeLabel($asset->asset_type);
            $asset->type_icon         = PortfolioAsset::typeIcon($asset->asset_type);
            $asset->type_color        = PortfolioAsset::typeColor($asset->asset_type);

            return $asset;
        });

        // ── 4. Portfolio totals ──────────────────────────────────────────────
        $totalCurrentValue = $assets->sum('current_value_try');
        $totalBuyValue     = $assets->sum('buy_value_try');
        $totalGainLoss     = $totalCurrentValue - $totalBuyValue;
        $totalGainLossPct  = $totalBuyValue > 0
            ? round(($totalGainLoss / $totalBuyValue) * 100, 2)
            : 0.0;

        $totals = [
            'current_value' => $totalCurrentValue,
            'buy_value'     => $totalBuyValue,
            'gain_loss'     => $totalGainLoss,
            'gain_loss_pct' => $totalGainLossPct,
        ];

        // ── 5. Chart data — grouped by asset_type ───────────────────────────
        $grouped   = $assets->groupBy('asset_type');
        $chartData = $grouped->map(function ($group, $type) {
            return [
                'label' => PortfolioAsset::typeLabel($type),
                'value' => round($group->sum('current_value_try'), 2),
            ];
        })->values()->filter(fn ($d) => $d['value'] > 0)->values();

        return view('investments.index', compact('assets', 'totals', 'chartData'));
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'asset_type'    => 'required|in:gold_gram,gold_quarter,gold_republic,usd,eur,gbp,btc,eth,bist,fund,mevduat,other',
            'name'          => 'required|string|max:120',
            'quantity'      => 'required|numeric|min:0.0001',
            'buy_price_try' => 'required|numeric|min:0.01',
            'buy_date'      => 'required|date',
            'notes'         => 'nullable|string|max:1000',
        ]);

        $data['user_id'] = $request->user()->id;

        PortfolioAsset::create($data);

        return redirect()->route('investments.index')
            ->with('success', 'Varlık portföye eklendi.');
    }

    public function destroy(int $id): RedirectResponse
    {
        $asset = PortfolioAsset::where('id', $id)
            ->where('user_id', auth()->id())
            ->firstOrFail();

        $asset->delete();

        return redirect()->route('investments.index')
            ->with('success', 'Varlık portföyden silindi.');
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    /**
     * Returns float rates keyed by currency code (e.g. ['USD' => 38.5, 'XAU' => 4200.0]).
     * Priority: shared 55-second cache → live Yahoo spark → DB fallback.
     */
    private function getLatestRates(): array
    {
        // Shared cache key with Api\InvestmentController
        $cached = Cache::get('inv_live_rates_v3');
        if ($cached && ! empty($cached['rates'])) {
            return collect($cached['rates'])
                ->map(fn ($r) => (float) ($r['rate'] ?? 0))
                ->all();
        }

        try {
            $live = $this->fetchSparkRates();
            Cache::put('inv_live_rates_v3', $live, 55);
            return collect($live['rates'])
                ->map(fn ($r) => (float) ($r['rate'] ?? 0))
                ->all();
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

    /** Yahoo Finance spark API — same endpoint used by Api\InvestmentController. */
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

        // Gold: GC=F USD/oz → TRY/gram
        $gcMeta = $by->get('GC=F')['response'][0]['meta'] ?? null;
        if ($gcMeta) {
            $goldUsd      = (float) ($gcMeta['regularMarketPrice'] ?? 0);
            $rates['XAU'] = ['rate' => round(($goldUsd / 31.1035) * $usdTry, 2), 'symbol' => 'GC=F'];
        }

        // Crypto: USD price × USDTRY
        foreach (['BTC' => 'BTC-USD', 'ETH' => 'ETH-USD'] as $code => $sym) {
            $meta = $by->get($sym)['response'][0]['meta'] ?? null;
            if ($meta) {
                $usdPrice     = (float) ($meta['regularMarketPrice'] ?? 0);
                $rates[$code] = ['rate' => round($usdPrice * $usdTry, 2), 'symbol' => $sym];
            }
        }

        return ['rates' => $rates, 'updated_at' => now()->toIso8601String(), 'source' => 'yahoo'];
    }

    /**
     * Resolve the current TRY price per unit for an asset type.
     * $rates is keyed by currency code => float TRY value.
     */
    private function resolveCurrentPrice(string $type, array $rates, float $buyPrice): float
    {
        $gramGold = $rates['XAU'] ?? $rates['GOLD'] ?? null;

        return match ($type) {
            'gold_gram'     => $gramGold ?? $buyPrice,
            'gold_quarter'  => $gramGold !== null ? $gramGold * 6.6 : $buyPrice,
            'gold_republic' => $gramGold !== null ? $gramGold * 7.2 : $buyPrice,
            'usd'           => $rates['USD'] ?? $buyPrice,
            'eur'           => $rates['EUR'] ?? $buyPrice,
            'gbp'           => $rates['GBP'] ?? $buyPrice,
            'btc'           => $rates['BTC'] ?? $buyPrice,
            'eth'           => $rates['ETH'] ?? $buyPrice,
            default         => $buyPrice,
        };
    }
}
