<?php

namespace App\Http\Controllers;

use App\Models\FxAlert;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class FxAlertController extends Controller
{
    /** Currencies shown in the rate overview cards and alert form. */
    private const TRACKED = ['USD', 'EUR', 'GBP', 'XAU'];

    public function index(Request $request): View
    {
        $user = $request->user();

        // ── Latest exchange rates for tracked currencies ─────────────────────
        $rates = DB::table('exchange_rates')
            ->whereIn('currency', self::TRACKED)
            ->orderByDesc('date')
            ->get()
            ->unique('currency')
            ->keyBy('currency');

        // ── User's alerts + triggered state ──────────────────────────────────
        $alerts = FxAlert::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(function (FxAlert $alert) use ($rates) {
                // Determine the currency key in the rates collection
                $rateKey = $alert->currency === 'GOLD' ? 'XAU' : $alert->currency;
                $rate    = isset($rates[$rateKey]) ? (float) $rates[$rateKey]->rate_to_try : null;

                $alert->current_rate = $rate;
                $alert->is_triggered = $rate !== null && (
                    ($alert->condition === 'above' && $rate >= (float) $alert->threshold) ||
                    ($alert->condition === 'below' && $rate <= (float) $alert->threshold)
                );

                return $alert;
            });

        return view('fx-alerts.index', compact('alerts', 'rates'));
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
