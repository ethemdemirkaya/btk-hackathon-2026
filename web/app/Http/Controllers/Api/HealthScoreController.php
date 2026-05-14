<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinancialHealthScore;
use App\Services\FinancialHealthScoreService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HealthScoreController extends Controller
{
    public function __construct(
        private readonly FinancialHealthScoreService $service,
    ) {}

    /** Returns the live score for the authenticated user (always recomputes). */
    public function show(Request $request): JsonResponse
    {
        $user   = $request->user();
        $record = $this->service->getOrCompute($user);

        // Last 12 months of stored scores for the trend sparkline
        $trend = FinancialHealthScore::where('user_id', $user->id)
            ->where('calculated_at', '>=', now()->subMonths(12))
            ->orderBy('calculated_at')
            ->get(['score', 'calculated_at'])
            ->map(fn ($r) => [
                'score' => (int) $r->score,
                'at'    => $r->calculated_at?->toIso8601String(),
            ])
            ->values();

        return response()->json([
            'score'         => $record->score,
            'components'    => [
                'debt_ratio'          => $record->debt_ratio_score,
                'savings_rate'        => $record->savings_rate_score,
                'emergency_fund'      => $record->emergency_fund_score,
                'expense_consistency' => $record->expense_consistency_score,
            ],
            'details'       => $record->details ?? $record->components ?? [],
            'calculated_at' => $record->calculated_at?->toIso8601String(),
            'trend'         => $trend,
        ]);
    }
}
