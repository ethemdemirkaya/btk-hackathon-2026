<?php

namespace App\Http\Controllers;

use App\Models\Goal;
use App\Models\Subscription;
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
            $budgetSummary    = $this->service->getBudgetSummary($user, 8);
            $healthDetails    = $this->service->getHealthScoreDetails($user);
            $macroIndicators  = \Illuminate\Support\Facades\DB::table('economic_indicators')
                ->orderByDesc('fetched_at')->limit(6)->get()->keyBy('type');

            $goalsSummary = Goal::where('user_id', $user->id)
                ->where('status', 'active')
                ->orderByDesc('created_at')
                ->limit(4)
                ->get()
                ->map(fn ($g) => [
                    'id'                  => $g->id,
                    'name'                => $g->name,
                    'target_amount'       => (float) $g->target_amount,
                    'current_amount'      => (float) $g->current_amount,
                    'monthly_contribution'=> (float) ($g->monthly_contribution ?? 0),
                    'target_date'         => $g->target_date,
                    'pct'                 => $g->target_amount > 0
                        ? min(100, (int) round((float) $g->current_amount / (float) $g->target_amount * 100))
                        : 0,
                ]);

            $activeSubscriptions       = Subscription::where('user_id', $user->id)->where('status', 'active')->get();
            $monthlySubscriptionCost   = $activeSubscriptions->sum(fn ($s) => match ($s->billing_cycle) {
                'yearly' => (float) $s->amount / 12,
                'weekly' => (float) $s->amount * 4.33,
                default  => (float) $s->amount,
            });
        } catch (\Throwable) {
            $summary                 = ['total_balance' => 0, 'total_card_debt' => 0, 'total_loan' => 0, 'net_worth' => 0, 'health_score' => null];
            $cashFlow                = [];
            $categorySpend           = [];
            $recentTxns              = collect();
            $bankConnections         = collect();
            $inflationData           = [];
            $personalInflation       = ['personal_rate' => null, 'tufe_rate' => 37.86, 'diff' => null, 'breakdown' => [], 'period' => null];
            $smartAlerts             = [];
            $aiInsights              = collect();
            $budgetSummary           = [];
            $healthDetails           = null;
            $macroIndicators         = collect();
            $goalsSummary            = collect();
            $monthlySubscriptionCost = 0.0;
        }

        return view('dashboard', compact(
            'summary', 'cashFlow', 'categorySpend',
            'recentTxns', 'bankConnections', 'inflationData', 'personalInflation',
            'smartAlerts', 'aiInsights', 'budgetSummary', 'healthDetails', 'macroIndicators',
            'goalsSummary', 'monthlySubscriptionCost'
        ));
    }
}
