<?php

namespace App\Http\Controllers;

use App\Models\PortfolioAsset;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;
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

        // ── 2. Latest exchange rates (one row per currency) ──────────────────
        $rates = DB::table('exchange_rates')
            ->whereIn('currency', ['USD', 'EUR', 'GBP', 'XAU', 'GOLD', 'BTC'])
            ->orderByDesc('date')
            ->get()
            ->unique('currency')
            ->keyBy('currency');

        // ── 3 & 4. Enrich each asset with live pricing & P&L ────────────────
        $assets = $assets->map(function (PortfolioAsset $asset) use ($rates) {
            $qty      = (float) $asset->quantity;
            $buyPrice = (float) $asset->buy_price_try;
            $buyValue = $qty * $buyPrice;

            // Determine current price per unit in TRY
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

        // ── 5. Portfolio totals ──────────────────────────────────────────────
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

        // ── 6. Chart data — grouped by asset_type ───────────────────────────
        $grouped   = $assets->groupBy('asset_type');
        $chartData = $grouped->map(function ($group, $type) {
            return [
                'label' => PortfolioAsset::typeLabel($type),
                'value' => round($group->sum('current_value_try'), 2),
            ];
        })->values()->filter(fn ($d) => $d['value'] > 0)->values();

        return view('investments.index', compact('assets', 'totals', 'chartData', 'rates'));
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
     * Resolve the current TRY price per unit for an asset type.
     * Falls back to the original buy price if no live rate is available.
     */
    private function resolveCurrentPrice(string $type, $rates, float $buyPrice): float
    {
        $xauRate  = isset($rates['XAU'])  ? (float) $rates['XAU']->rate_to_try  : null;
        $goldRate = isset($rates['GOLD']) ? (float) $rates['GOLD']->rate_to_try : null;
        $gramGold = $xauRate ?? $goldRate;

        return match ($type) {
            'gold_gram'     => $gramGold ?? $buyPrice,
            'gold_quarter'  => $gramGold !== null ? $gramGold * 6.6 : $buyPrice,
            'gold_republic' => $gramGold !== null ? $gramGold * 7.2 : $buyPrice,
            'usd'           => isset($rates['USD']) ? (float) $rates['USD']->rate_to_try : $buyPrice,
            'eur'           => isset($rates['EUR']) ? (float) $rates['EUR']->rate_to_try : $buyPrice,
            'gbp'           => isset($rates['GBP']) ? (float) $rates['GBP']->rate_to_try : $buyPrice,
            'btc'           => isset($rates['BTC']) ? (float) $rates['BTC']->rate_to_try : $buyPrice,
            // ETH, bist, fund, mevduat, other — no live feed, use buy price
            default         => $buyPrice,
        };
    }
}
