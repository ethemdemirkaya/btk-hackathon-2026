<?php

namespace App\Http\Controllers;

use App\Services\PersonalInflationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class InflationController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        // Latest TÜİK category rates
        $latestPeriod = DB::table('inflation_category_rates')
            ->selectRaw('period_year, period_month')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->first();

        $categoryRates = collect();
        $headline = 37.86;
        $periodLabel = 'Nisan 2025';

        if ($latestPeriod) {
            $categoryRates = DB::table('inflation_category_rates')
                ->where('period_year', $latestPeriod->period_year)
                ->where('period_month', $latestPeriod->period_month)
                ->whereNotIn('tuik_category_slug', ['genel'])
                ->orderByDesc('annual_change_rate')
                ->get();

            $generalRate = DB::table('inflation_category_rates')
                ->where('period_year', $latestPeriod->period_year)
                ->where('period_month', $latestPeriod->period_month)
                ->where('tuik_category_slug', 'genel')
                ->value('annual_change_rate');

            if ($generalRate) $headline = (float) $generalRate;

            $monthNames = ['', 'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
                           'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
            $periodLabel = ($monthNames[$latestPeriod->period_month] ?? '') . ' ' . $latestPeriod->period_year;
        }

        // Historical headline inflation (last 12 months from category rates)
        $historical = DB::table('inflation_category_rates')
            ->where('tuik_category_slug', 'genel')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->limit(12)
            ->get(['period_year', 'period_month', 'annual_change_rate'])
            ->reverse()->values();

        // Calculate personal inflation using PersonalInflationService
        try {
            $personalResult = app(PersonalInflationService::class)->calculate($user);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('PersonalInflation calculation failed', ['error' => $e->getMessage()]);
            $personalResult = ['personal_rate' => null, 'diff' => 0.0, 'total_spending' => 0, 'breakdown' => []];
        }
        $personalRate    = $personalResult['personal_rate'] ?? $headline;
        $personalDelta   = isset($personalResult['diff']) ? $personalResult['diff'] : 0.0;
        $totalSpend      = $personalResult['total_spending'] ?? 0;

        // Build personal breakdown from service result
        $personalBreakdown = [];
        foreach ($personalResult['breakdown'] ?? [] as $b) {
            $personalBreakdown[] = [
                'slug'   => $b['tuik_slug'],
                'amount' => round($b['weight_pct'] / 100 * $totalSpend, 0),
                'weight' => $b['weight_pct'],
                'rate'   => $b['tuik_rate'],
                'impact' => round($b['contribution'], 2),
            ];
        }

        $topImpact = $personalBreakdown[0] ?? null;

        return view('inflation.index', compact(
            'categoryRates', 'headline', 'periodLabel', 'historical',
            'personalRate', 'personalDelta', 'personalBreakdown', 'topImpact',
            'totalSpend'
        ));
    }

}
