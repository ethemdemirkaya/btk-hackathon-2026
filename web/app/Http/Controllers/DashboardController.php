<?php

namespace App\Http\Controllers;

use App\Services\DashboardService;
use App\Services\FinancialHealthScoreService;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __construct(
        private readonly DashboardService $service,
        private readonly FinancialHealthScoreService $healthScorer,
    ) {}

    public function index(Request $request): View
    {
        $user = $request->user();

        try {
            // Recompute health score if stale (>24 h) or missing
            $this->healthScorer->getOrCompute($user);

            $summary          = $this->service->getSummary($user);
            $cashFlow         = $this->service->getCashFlowData($user);
            $categorySpend    = $this->service->getCategorySpending($user);
            $recentTxns       = $this->service->getRecentTransactions($user);
            $bankConnections  = $this->service->getBankConnections($user);
            $inflationData    = $this->service->getInflationComparison($user);
            $personalInflation= $this->service->getPersonalInflation($user);
            $smartAlerts      = $this->service->getSmartAlerts($user);
            $aiInsights       = $this->service->getRecentInsights($user);
            $budgetSummary    = $this->service->getBudgetSummary($user);
            $healthDetails    = $this->service->getHealthScoreDetails($user);
            $macroIndicators  = \Illuminate\Support\Facades\DB::table('economic_indicators')
                ->orderByDesc('fetched_at')->limit(6)->get()->keyBy('type');
        } catch (\Throwable) {
            // DB not yet migrated or no data — use empty state
            $summary          = ['total_balance' => 0, 'total_card_debt' => 0, 'total_loan' => 0, 'net_worth' => 0, 'health_score' => null];
            $cashFlow         = [];
            $categorySpend    = [];
            $recentTxns       = collect();
            $bankConnections  = collect();
            $inflationData    = [];
            $personalInflation= ['personal_rate' => null, 'tufe_rate' => 37.86, 'diff' => null, 'breakdown' => [], 'period' => null];
            $smartAlerts      = [];
            $aiInsights       = collect();
            $budgetSummary    = [];
            $healthDetails    = null;
            $macroIndicators  = collect();
        }

        return view('dashboard', compact(
            'summary', 'cashFlow', 'categorySpend',
            'recentTxns', 'bankConnections', 'inflationData', 'personalInflation',
            'smartAlerts', 'aiInsights', 'budgetSummary', 'healthDetails', 'macroIndicators'
        ));
    }
}
