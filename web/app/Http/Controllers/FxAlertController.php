<?php

namespace App\Http\Controllers;

use App\Models\FxAlert;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class FxAlertController extends Controller
{
    /** Currencies shown in the rate overview cards and alert form. */
    private const TRACKED = ['USD', 'EUR', 'GBP', 'XAU', 'CHF', 'JPY', 'AUD'];

    private const LABELS = [
        'USD' => ['name' => 'Amerikan Doları',   'flag' => '🇺🇸', 'symbol' => '$'],
        'EUR' => ['name' => 'Euro',               'flag' => '🇪🇺', 'symbol' => '€'],
        'GBP' => ['name' => 'İngiliz Sterlini',  'flag' => '🇬🇧', 'symbol' => '£'],
        'XAU' => ['name' => 'Altın (gram)',       'flag' => '🥇', 'symbol' => 'g'],
        'CHF' => ['name' => 'İsviçre Frangı',    'flag' => '🇨🇭', 'symbol' => '₣'],
        'JPY' => ['name' => 'Japon Yeni (100)',   'flag' => '🇯🇵', 'symbol' => '¥'],
        'AUD' => ['name' => 'Avustralya Doları',  'flag' => '🇦🇺', 'symbol' => 'A$'],
    ];

    public function index(Request $request): View
    {
        $user = $request->user();

        $ratesData = $this->buildRatesPayload();

        // ── User's alerts + triggered state ──────────────────────────────────
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

    /** JSON endpoint — called by the JS auto-refresh every 60 s. */
    public function liveRates(): JsonResponse
    {
        return response()->json([
            'fetched_at' => now()->format('d.m.Y H:i'),
            'rates'      => $this->buildRatesPayload(),
        ]);
    }

    /** Build enriched rates array with history & change %. */
    private function buildRatesPayload(): array
    {
        $days = 30;
        $since = now()->subDays($days)->toDateString();

        // Last 30 days per currency, oldest first
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

            $rate     = (float) $latest->rate_to_try;
            $prevRate = $previous ? (float) $previous->rate_to_try : $rate;
            $change   = $rate - $prevRate;
            $changePct = $prevRate > 0 ? round(($change / $prevRate) * 100, 2) : 0;

            $payload[$code] = [
                'currency'   => $code,
                'name'       => self::LABELS[$code]['name']  ?? $code,
                'flag'       => self::LABELS[$code]['flag']  ?? '',
                'symbol'     => self::LABELS[$code]['symbol'] ?? '',
                'rate'       => $rate,
                'prev_rate'  => $prevRate,
                'change'     => round($change, 4),
                'change_pct' => $changePct,
                'date'       => $latest->date,
                'history'    => $rows->pluck('rate_to_try')->map(fn($v) => round((float)$v, 4))->values()->toArray(),
                'labels'     => $rows->pluck('date')->values()->toArray(),
            ];
        }

        return $payload;
    }

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
        $alert = FxAlert::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $alert->delete();

        return redirect()->route('fx-alerts.index')
            ->with('success', 'Alarm silindi.');
    }
}
