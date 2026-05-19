<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FxAlert;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class FxAlertController extends Controller
{
    private const TRACKED = ['USD', 'EUR', 'GBP', 'XAU', 'CHF', 'JPY', 'AUD'];

    private const LABELS = [
        'USD' => ['name' => 'Amerikan Doları',   'symbol' => '$'],
        'EUR' => ['name' => 'Euro',               'symbol' => '€'],
        'GBP' => ['name' => 'İngiliz Sterlini',  'symbol' => '£'],
        'XAU' => ['name' => 'Gram Altın',         'symbol' => 'g'],
        'CHF' => ['name' => 'İsviçre Frangı',    'symbol' => '₣'],
        'JPY' => ['name' => 'Japon Yeni (100)',  'symbol' => '¥'],
        'AUD' => ['name' => 'Avustralya Doları', 'symbol' => 'A$'],
    ];

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        // Canlı kurları önce cache'den al; yoksa Yahoo'dan çek ve cache'e yaz
        $cached = Cache::get('fx_live_v2');
        if ($cached && ! empty($cached['rates'])) {
            $rates = $cached['rates'];
        } else {
            try {
                $rates = $this->fetchYahoo();
                Cache::put('fx_live_v2', ['source' => 'yahoo', 'rates' => $rates], 55);
            } catch (\Throwable) {
                $rates = $this->buildRatesPayload();
            }
        }

        $alerts = FxAlert::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(function (FxAlert $alert) use ($rates) {
                $key  = $alert->currency === 'GOLD' ? 'XAU' : $alert->currency;
                $rate = isset($rates[$key]) ? (float) $rates[$key]['rate'] : null;

                return [
                    'id'           => $alert->id,
                    'currency'     => $alert->currency,
                    'condition'    => $alert->condition,
                    'threshold'    => (float) $alert->threshold,
                    'triggered_at' => $alert->triggered_at,
                    'created_at'   => $alert->created_at?->toIso8601String(),
                    'current_rate' => $rate,
                    'is_triggered' => $rate !== null && (
                        ($alert->condition === 'above' && $rate >= (float) $alert->threshold) ||
                        ($alert->condition === 'below' && $rate <= (float) $alert->threshold)
                    ),
                ];
            });

        return response()->json([
            'alerts' => $alerts->values(),
            'rates'  => $rates,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'currency'  => 'required|string|max:10',
            'condition' => 'required|in:above,below',
            'threshold' => 'required|numeric|min:0.01',
        ]);

        $alert = FxAlert::create(['user_id' => $request->user()->id] + $data);

        return response()->json(['alert' => $alert], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $alert = FxAlert::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $data = $request->validate([
            'currency'  => 'sometimes|string|max:10',
            'condition' => 'sometimes|in:above,below',
            'threshold' => 'sometimes|numeric|min:0.01',
        ]);

        $alert->update($data + ['triggered_at' => null]);

        return response()->json(['alert' => $alert]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $alert = FxAlert::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $alert->delete();

        return response()->json(['message' => 'Alarm silindi.']);
    }

    public function rates(): JsonResponse
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

    private function fetchYahoo(): array
    {
        $fxMap  = ['USD' => 'USDTRY=X', 'EUR' => 'EURTRY=X', 'GBP' => 'GBPTRY=X',
                   'CHF' => 'CHFTRY=X', 'JPY' => 'JPYTRY=X', 'AUD' => 'AUDTRY=X'];
        $symbols = implode(',', array_values($fxMap)) . ',GC=F';

        $resp = Http::withHeaders([
            'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept'     => 'application/json',
        ])->withoutVerifying()->timeout(12)->get('https://query1.finance.yahoo.com/v7/finance/spark', [
            'symbols'           => $symbols,
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

        if ($by->isEmpty()) throw new \RuntimeException('Yahoo: empty spark result');

        $usdMeta = $by->get('USDTRY=X')['response'][0]['meta'] ?? null;
        if (! $usdMeta) throw new \RuntimeException('Yahoo: USDTRY=X missing');
        $usdTry = (float) $usdMeta['regularMarketPrice'];
        if (! $usdTry) throw new \RuntimeException('Yahoo: USDTRY zero');

        $result = [];
        foreach ($fxMap as $code => $sym) {
            $meta = $by->get($sym)['response'][0]['meta'] ?? null;
            if (! $meta) continue;

            $rate      = (float) ($meta['regularMarketPrice']  ?? 0);
            $prevClose = (float) ($meta['chartPreviousClose']  ?? $meta['previousClose'] ?? $rate);
            $chg       = $rate - $prevClose;
            $pct       = $prevClose > 0 ? round(($chg / $prevClose) * 100, 2) : 0.0;

            if ($code === 'JPY') { $rate = round($rate * 100, 4); $chg = round($chg * 100, 4); }

            $result[$code] = ['rate' => round($rate, 4), 'change' => round($chg, 4), 'change_pct' => $pct];
        }

        // Altın: GC=F → USD/troy-oz → TRY/gram
        $gcMeta = $by->get('GC=F')['response'][0]['meta'] ?? null;
        if ($gcMeta && $usdTry) {
            $goldUsd     = (float) ($gcMeta['regularMarketPrice'] ?? 0);
            $goldPrev    = (float) ($gcMeta['chartPreviousClose'] ?? $gcMeta['previousClose'] ?? $goldUsd);
            $goldTry     = ($goldUsd  / 31.1035) * $usdTry;
            $goldPrevTry = ($goldPrev / 31.1035) * $usdTry;
            $goldChg     = $goldTry - $goldPrevTry;
            $goldPct     = $goldPrevTry > 0 ? round(($goldChg / $goldPrevTry) * 100, 2) : 0.0;
            $result['XAU'] = [
                'rate'       => round($goldTry, 2),
                'change'     => round($goldChg, 2),
                'change_pct' => $goldPct,
            ];
        }

        return $this->withMeta($result);
    }

    private function fetchOpenER(): array
    {
        $resp   = Http::timeout(10)->get('https://open.er-api.com/v6/latest/USD');
        if (! $resp->ok()) throw new \RuntimeException('OpenER HTTP ' . $resp->status());

        $er     = $resp->json('rates') ?? [];
        $usdTry = (float) ($er['TRY'] ?? 0);
        if (! $usdTry) throw new \RuntimeException('OpenER: TRY missing');

        $result = [];
        foreach (['USD', 'EUR', 'GBP', 'CHF', 'JPY', 'AUD'] as $code) {
            $usdToCode = $code === 'USD' ? 1.0 : (float) ($er[$code] ?? 0);
            if (! $usdToCode) continue;
            $rate = $usdTry / $usdToCode;
            if ($code === 'JPY') $rate *= 100;
            $result[$code] = ['rate' => round($rate, 4), 'change' => 0, 'change_pct' => 0];
        }

        try {
            $gr = Http::withoutVerifying()->timeout(8)->get('https://api.gold-api.com/price/XAU');
            if ($gr->ok()) {
                $goldUsd       = (float) $gr->json('price');
                $result['XAU'] = ['rate' => round(($goldUsd / 31.1035) * $usdTry, 2), 'change' => 0, 'change_pct' => 0];
            }
        } catch (\Throwable) {}

        return $this->withMeta($result);
    }

    private function dbRates(): array
    {
        return $this->withMeta(
            collect($this->buildRatesPayload())
                ->map(fn ($r, $code) => ['currency' => $code, 'rate' => $r['rate'], 'change' => $r['change'], 'change_pct' => $r['change_pct']])
                ->all()
        );
    }

    private function withMeta(array $rates): array
    {
        foreach ($rates as $code => &$r) {
            $r = array_merge(['currency' => $code], self::LABELS[$code] ?? [], $r);
        }
        return $rates;
    }

    private function buildRatesPayload(): array
    {
        $since   = now()->subDays(30)->toDateString();
        $history = DB::table('exchange_rates')
            ->whereIn('currency', self::TRACKED)
            ->where('date', '>=', $since)
            ->orderBy('date')
            ->get()
            ->groupBy('currency');

        $payload = [];
        foreach (self::TRACKED as $code) {
            $rows    = $history->get($code, collect());
            $latest  = $rows->last();
            $prev    = $rows->count() >= 2 ? $rows->slice(-2, 1)->first() : null;
            if (! $latest) continue;

            $rate      = (float) $latest->rate_to_try;
            $prevRate  = $prev ? (float) $prev->rate_to_try : $rate;
            $change    = $rate - $prevRate;
            $changePct = $prevRate > 0 ? round(($change / $prevRate) * 100, 2) : 0;

            $displayRate = $code === 'JPY' ? $rate * 100 : $rate;

            $payload[$code] = [
                'currency'   => $code,
                'name'       => self::LABELS[$code]['name']   ?? $code,
                'symbol'     => self::LABELS[$code]['symbol'] ?? '',
                'rate'       => round($displayRate, 4),
                'change'     => round($code === 'JPY' ? $change * 100 : $change, 4),
                'change_pct' => $changePct,
                'date'       => $latest->date,
            ];
        }

        return $payload;
    }
}
