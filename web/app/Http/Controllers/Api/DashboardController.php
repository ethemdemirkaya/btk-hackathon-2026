<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DashboardService;
use App\Services\FinancialHealthScoreService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function __construct(
        private readonly DashboardService $service,
        private readonly FinancialHealthScoreService $healthScorer,
    ) {}

    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();

        try {
            $this->healthScorer->getOrCompute($user);

            $summary          = $this->service->getSummary($user);
            $cashFlow         = $this->service->getCashFlowData($user);
            $categorySpend    = $this->service->getCategorySpending($user);
            $personalInflation= $this->service->getPersonalInflation($user);
            $smartAlerts      = $this->service->getSmartAlerts($user);
            $budgetSummary    = $this->service->getBudgetSummary($user);
            $healthDetails    = $this->service->getHealthScoreDetails($user);
            $macroIndicators  = DB::table('economic_indicators')
                ->orderByDesc('fetched_at')->limit(6)->get()->keyBy('type');
        } catch (\Throwable) {
            $summary          = ['total_balance' => 0, 'total_card_debt' => 0, 'total_loan' => 0, 'net_worth' => 0, 'health_score' => null];
            $cashFlow         = [];
            $categorySpend    = [];
            $personalInflation= ['personal_rate' => null, 'tufe_rate' => 37.86, 'diff' => null, 'breakdown' => [], 'period' => null];
            $smartAlerts      = [];
            $budgetSummary    = [];
            $healthDetails    = null;
            $macroIndicators  = collect();
        }

        return response()->json([
            'summary'          => $summary,
            'cash_flow'        => $cashFlow,
            'category_spend'   => $categorySpend,
            'personal_inflation' => $personalInflation,
            'smart_alerts'     => $smartAlerts,
            'budget_summary'   => $budgetSummary,
            'health_score'     => $healthDetails ? [
                'score'                      => $healthDetails->score,
                'debt_ratio_score'           => $healthDetails->debt_ratio_score,
                'savings_rate_score'         => $healthDetails->savings_rate_score,
                'emergency_fund_score'       => $healthDetails->emergency_fund_score,
                'expense_consistency_score'  => $healthDetails->expense_consistency_score,
                'calculated_at'              => $healthDetails->calculated_at,
            ] : null,
            'macro_indicators' => $macroIndicators->values(),
        ]);
    }
}
