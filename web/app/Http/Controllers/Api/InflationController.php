<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PersonalInflationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InflationController extends Controller
{
    public function __construct(private readonly PersonalInflationService $service) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        try {
            $personal = $this->service->calculate($user);
        } catch (\Throwable) {
            $personal = null;
        }

        // inflation_rates columns: period_year, period_month, headline_annual_rate
        $tufeHistory = DB::table('inflation_rates')
            ->orderByDesc('period_year')
            ->orderByDesc('period_month')
            ->limit(12)
            ->get(['period_year', 'period_month', 'headline_annual_rate'])
            ->map(fn ($r) => [
                'period'       => sprintf('%04d-%02d', $r->period_year, $r->period_month),
                'annual_rate'  => (float) $r->headline_annual_rate,
                'monthly_rate' => null,
            ]);

        // inflation_category_rates columns: period_year, period_month, tuik_category_slug, annual_change_rate
        $categoryRates = DB::table('inflation_category_rates')
            ->orderByDesc('period_year')
            ->orderByDesc('period_month')
            ->limit(100)
            ->get()
            ->groupBy('tuik_category_slug')
            ->map(fn ($rows) => $rows->sortByDesc('period_year')->sortByDesc('period_month')->first())
            ->map(fn ($r) => [
                'category' => $r->tuik_category_slug,
                'rate'     => (float) $r->annual_change_rate,
                'period'   => sprintf('%04d-%02d', $r->period_year, $r->period_month),
            ])
            ->values();

        return response()->json([
            'personal_rate'  => $personal ? (float) $personal['personal_rate'] : null,
            'tufe_rate'      => $personal ? (float) $personal['tufe_rate'] : null,
            'diff'           => $personal ? (float) $personal['diff'] : null,
            'breakdown'      => $personal ? $personal['breakdown'] : [],
            'period'         => $personal ? $personal['period'] : null,
            'tufe_history'   => $tufeHistory,
            'category_rates' => $categoryRates,
        ]);
    }
}
