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

        $tufeHistory = DB::table('inflation_rates')
            ->orderByDesc('period')
            ->limit(12)
            ->get(['period', 'annual_rate', 'monthly_rate'])
            ->map(fn ($r) => [
                'period'       => $r->period,
                'annual_rate'  => (float) $r->annual_rate,
                'monthly_rate' => (float) $r->monthly_rate,
            ]);

        $categoryRates = DB::table('inflation_category_rates')
            ->orderByDesc('period')
            ->limit(30)
            ->get()
            ->groupBy('category')
            ->map(fn ($rows) => $rows->sortByDesc('period')->first())
            ->map(fn ($r) => [
                'category' => $r->category,
                'rate'     => (float) $r->annual_rate,
                'period'   => $r->period,
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
