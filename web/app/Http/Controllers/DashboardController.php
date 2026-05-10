<?php

namespace App\Http\Controllers;

use App\Services\DashboardService;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __construct(private readonly DashboardService $service)
    {
    }

    public function index(Request $request): View
    {
        $user = $request->user();

        try {
            $summary         = $this->service->getSummary($user);
            $cashFlow        = $this->service->getCashFlowData($user);
            $categorySpend   = $this->service->getCategorySpending($user);
            $recentTxns      = $this->service->getRecentTransactions($user);
            $bankConnections = $this->service->getBankConnections($user);
            $inflationData   = $this->service->getInflationComparison($user);
        } catch (\Throwable) {
            // DB not yet migrated or no data — use empty state
            $summary         = ['total_balance' => 0, 'total_card_debt' => 0, 'total_loan' => 0, 'health_score' => null];
            $cashFlow        = [];
            $categorySpend   = [];
            $recentTxns      = collect();
            $bankConnections = collect();
            $inflationData   = [];
        }

        return view('dashboard', compact(
            'summary', 'cashFlow', 'categorySpend',
            'recentTxns', 'bankConnections', 'inflationData'
        ));
    }
}
