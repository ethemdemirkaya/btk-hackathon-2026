<?php

namespace App\Http\Controllers;

use App\Models\FxAlert;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\View\View;

class FxAlertController extends Controller
{
    private const TRACKED = ['USD', 'EUR', 'GBP', 'XAU', 'CHF', 'JPY', 'AUD'];

    private const LABELS = [
        'USD' => ['name' => 'Amerikan Doları',  'flag' => '🇺🇸', 'symbol' => '$',  'color' => 'success'],
        'EUR' => ['name' => 'Euro',              'flag' => '🇪🇺', 'symbol' => '€',  'color' => 'primary'],
        'GBP' => ['name' => 'İngiliz Sterlini', 'flag' => '🇬🇧', 'symbol' => '£',  'color' => 'warning'],
        'XAU' => ['name' => 'Gram Altın',        'flag' => '🥇',  'symbol' => 'g',  'color' => 'danger'],
        'CHF' => ['name' => 'İsviçre Frangı',   'flag' => '🇨🇭', 'symbol' => '₣',  'color' => 'info'],
        'JPY' => ['name' => 'Japon Yeni (100)', 'flag' => '🇯🇵', 'symbol' => '¥',  'color' => 'secondary'],
        'AUD' => ['name' => 'Avustralya Doları', 'flag' => '🇦🇺', 'symbol' => 'A$', 'color' => 'dark'],
    ];

    // ── Pages ─────────────────────────────────────────────────────────

    public function index(Request $request): View
    {
        $user      = $request->user();
        $ratesData = $this->buildRatesPayload();

        $alerts = FxAlert::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(function (FxAlert $alert) use ($ratesData) {
                $key  = $alert->currency === 'GOLD' ? 'XAU' : $alert->currency;
                $rate = $ratesData[$key]['rate'] ?? null;

                $alert->current_rate = $rate;
                $alert->is_triggered = $rate !== null && (
                    ($alert->condition === 'above' && $rate >= (float) $alert->threshold) ||
                    ($alert->condition === 'below' && $rate <= (float) $alert->threshold)
                );

                return $alert;
            });

        $labels = self::LABELS;

        return view('fx-alerts.index', compact('alerts', 'ratesData', 'labels'));
    }

    // ── JSON endpoints ────────────────────────────────────────────────

    /**
     * Live rates — tries Yahoo Finance, falls back to open.er-api.com,
     * falls back to yesterday's DB data.  Cached 55 s.
     */
    public function marketRates(): JsonResponse
    {
        $data = Cache::remember('fx_live_v2', 55, function () {
            try {
                return ['source' => 'yahoo', 'rates' => $this->fetchYahoo()];
            } catch (\Throwable) {
                try {
                    return ['source' => 'open-er', 'rates' => $this->fetchOpenER()];
                } catch (\Throwable) {
                    return ['source' => 'db', 'rates' => $this->dbRates()];
                }
            }
        });

        return response()->json(array_merge($data, [
            'at'   => now()->format('H:i:s'),
            'date' => now()->format('d.m.Y'),
        ]));
    }

    /** Legacy endpoint kept for backwards compatibility. */
    public function liveRates(): JsonResponse
    {
        return response()->json([
            'fetched_at' => now()->format('d.m.Y H:i'),
            'rates'      => $this->buildRatesPayload(),
        ]);
    }

    // ── CRUD ──────────────────────────────────────────────────────────

    public function store(Request $request)
    {
        $data = $request->validate([
            'currency'  => 'required|string|max:10',
            'condition' => 'required|in:above,below',
            'threshold' => 'required|numeric|min:0.01',
        ]);

        $data['user_id'] = $request->user()->id;
        FxAlert::create($data);

        return redirect()->route('fx-alerts.index')
            ->with('success', 'Kur alarmı eklendi.');
    }

    public function destroy(Request $request, int $id)
    {
        FxAlert::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail()
            ->delete();

        return redirect()->route('fx-alerts.index')
            ->with('success', 'Alarm silindi.');
    }

    // ── Private: live fetchers ────────────────────────────────────────

    private function fetchYahoo(): array
    {
        $fxMap  = ['USD' => 'USDTRY=X', 'EUR' => 'EURTRY=X', 'GBP' => 'GBPTRY=X',
                   'CHF' => 'CHFTRY=X', 'JPY' => 'JPYTRY=X', 'AUD' => 'AUDTRY=X'];
        $symbols = implode(',', array_values($fxMap)) . ',GC=F';

        $resp = Http::withHeaders([
            'User-Agent'      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept'          => 'application/json',
            'Accept-Language' => 'en-US,en;q=0.9',
        ])->timeout(10)->get('https://query2.finance.yahoo.com/v7/finance/quote', [
            'symbols' => $symbols,
            'lang'    => 'en-US',
            'region'  => 'US',
        ]);

        if (! $resp->ok()) {
            throw new \RuntimeException('Yahoo HTTP ' . $resp->status());
        }

        $by = collect($resp->json('quoteResponse.result') ?? [])->keyBy('symbol');

        if ($by->isEmpty()) {
            throw new \RuntimeException('Yahoo: empty result');
        }

        $usdTry = (float) ($by->get('USDTRY=X')['regularMarketPrice'] ?? 0);
        if (! $usdTry) {
            throw new \RuntimeException('Yahoo: USDTRY missing');
        }

        $result = [];

        foreach ($fxMap as $code => $sym) {
            $q = $by->get($sym);
            if (! $q) {
                continue;
            }

            $rate = (float) ($q['regularMarketPrice']        ?? 0);
            $chg  = (float) ($q['regularMarketChange']       ?? 0);
            $pct  = (float) ($q['regularMarketChangePercent'] ?? 0);

            // JPY is stored/returned per 1 JPY; multiply by 100 for display parity with TCMB
            if ($code === 'JPY') {
                $rate = round($rate * 100, 4);
                $chg  = round($chg  * 100, 4);
            }

            $result[$code] = [
                'rate'       => round($rate, 4),
                'change'     => round($chg,  4),
                'change_pct' => round($pct,  2),
            ];
        }

        // Gold: GC=F = USD / troy oz → TRY / gram
        $gc = $by->get('GC=F');
        if ($gc && $usdTry) {
            $goldUsd = (float) ($gc['regularMarketPrice']         ?? 0);
            $goldPct = (float) ($gc['regularMarketChangePercent'] ?? 0);
            $goldChg = (float) ($gc['regularMarketChange']        ?? 0);
            $result['XAU'] = [
                'rate'       => round(($goldUsd / 31.1035) * $usdTry, 2),
                'change'     => round(($goldChg / 31.1035) * $usdTry, 2),
                'change_pct' => round($goldPct, 2),
            ];
        }

        return $this->withMeta($result);
    }

    private function fetchOpenER(): array
    {
        // open.er-api.com — free tier, no API key, updates ~hourly
        $resp = Http::timeout(10)->get('https://open.er-api.com/v6/latest/USD');

        if (! $resp->ok()) {
            throw new \RuntimeException('OpenER HTTP ' . $resp->status());
        }

        $er     = $resp->json('rates') ?? [];
        $usdTry = (float) ($er['TRY'] ?? 0);

        if (! $usdTry) {
            throw new \RuntimeException('OpenER: TRY missing');
        }

        $result = [];

        foreach (['USD', 'EUR', 'GBP', 'CHF', 'JPY', 'AUD'] as $code) {
            $usdToCode = $code === 'USD' ? 1.0 : (float) ($er[$code] ?? 0);
            if (! $usdToCode) {
                continue;
            }

            $rate = $usdTry / $usdToCode;

            // Per 100 JPY
            if ($code === 'JPY') {
                $rate = $rate * 100;
            }

            $result[$code] = ['rate' => round($rate, 4), 'change' => 0, 'change_pct' => 0];
        }

        // Gold from gold-api.com
        try {
            $gr = Http::withoutVerifying()->timeout(8)->get('https://api.gold-api.com/price/XAU');
            if ($gr->ok()) {
                $goldUsd    = (float) $gr->json('price');
                $result['XAU'] = [
                    'rate'       => round(($goldUsd / 31.1035) * $usdTry, 2),
                    'change'     => 0,
                    'change_pct' => 0,
                ];
            }
        } catch (\Throwable) {
            // gold optional
        }

        return $this->withMeta($result);
    }

    private function dbRates(): array
    {
        $result = [];
        foreach ($this->buildRatesPayload() as $code => $r) {
            $result[$code] = [
                'currency'   => $code,
                'rate'       => $r['rate'],
                'change'     => $r['change'],
                'change_pct' => $r['change_pct'],
            ];
        }
        return $this->withMeta($result);
    }

    private function withMeta(array $rates): array
    {
        foreach ($rates as $code => &$r) {
            $r = array_merge(['currency' => $code], self::LABELS[$code] ?? [], $r);
        }
        return $rates;
    }

    // ── Private: DB history (sparklines + fallback) ────────────────────

    private function buildRatesPayload(): array
    {
        $since = now()->subDays(30)->toDateString();

        $history = DB::table('exchange_rates')
            ->whereIn('currency', self::TRACKED)
            ->where('date', '>=', $since)
            ->orderBy('date')
            ->get()
            ->groupBy('currency');

        $payload = [];

        foreach (self::TRACKED as $code) {
            $rows     = $history->get($code, collect());
            $latest   = $rows->last();
            $previous = $rows->count() >= 2 ? $rows->slice(-2, 1)->first() : null;

            if (! $latest) {
                continue;
            }

            $rate      = (float) $latest->rate_to_try;
            $prevRate  = $previous ? (float) $previous->rate_to_try : $rate;
            $change    = $rate - $prevRate;
            $changePct = $prevRate > 0 ? round(($change / $prevRate) * 100, 2) : 0;

            // Stored rate for JPY is per 1 JPY; multiply by 100 for display
            $displayRate = $code === 'JPY' ? $rate * 100 : $rate;
            $displayPrev = $code === 'JPY' ? $prevRate * 100 : $prevRate;

            $payload[$code] = [
                'currency'   => $code,
                'name'       => self::LABELS[$code]['name']   ?? $code,
                'flag'       => self::LABELS[$code]['flag']   ?? '',
                'symbol'     => self::LABELS[$code]['symbol'] ?? '',
                'color'      => self::LABELS[$code]['color']  ?? 'secondary',
                'rate'       => round($displayRate, 4),
                'prev_rate'  => round($displayPrev, 4),
                'change'     => round($code === 'JPY' ? $change * 100 : $change, 4),
                'change_pct' => $changePct,
                'date'       => $latest->date,
                'history'    => $rows->pluck('rate_to_try')
                    ->map(fn ($v) => $code === 'JPY'
                        ? round((float) $v * 100, 4)
                        : round((float) $v, 4))
                    ->values()->toArray(),
                'labels'     => $rows->pluck('date')->values()->toArray(),
            ];
        }

        return $payload;
    }
}
