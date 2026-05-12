<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinancialHealthScore;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DecisionSimulatorController extends Controller
{
    public function current(Request $request): JsonResponse
    {
        $user = $request->user();

        $monthlyIncome    = (float) ($user->monthly_income ?? 0);
        $totalBalance     = (float) DB::table('accounts')->where('user_id', $user->id)->sum('balance');
        $totalCardDebt    = (float) DB::table('cards')->where('user_id', $user->id)->sum('current_debt');
        $totalLoanBalance = (float) DB::table('loans')->where('user_id', $user->id)->sum('current_balance');

        $sub = DB::table('transactions as t2')
            ->join('accounts as a2', 'a2.id', '=', 't2.account_id')
            ->select(
                DB::raw("DATE_FORMAT(t2.posted_at, '%Y-%m') as month"),
                DB::raw('SUM(ABS(t2.amount)) as monthly_total')
            )
            ->where('a2.user_id', $user->id)
            ->where('t2.amount', '<', 0)
            ->where('t2.posted_at', '>=', now()->subMonths(3))
            ->groupBy('month');

        $avgMonthlyExpense = (float) DB::table($sub, 'monthly_sums')->avg('monthly_total') ?? 0;

        $healthScore = FinancialHealthScore::where('user_id', $user->id)
            ->orderByDesc('calculated_at')
            ->first();

        $personalInflation = (float) (DB::table('inflation_category_rates')
            ->where('tuik_category_slug', 'genel')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->value('annual_change_rate') ?? 38.0);

        return response()->json([
            'monthly_income'      => round($monthlyIncome, 2),
            'avg_monthly_expense' => round($avgMonthlyExpense, 2),
            'monthly_savings'     => round($monthlyIncome - $avgMonthlyExpense, 2),
            'savings_rate'        => $monthlyIncome > 0
                ? round(($monthlyIncome - $avgMonthlyExpense) / $monthlyIncome * 100, 1)
                : 0,
            'total_balance'       => round($totalBalance, 2),
            'total_card_debt'     => round($totalCardDebt, 2),
            'total_loan'          => round($totalLoanBalance, 2),
            'health_score'        => $healthScore?->score ?? 0,
            'personal_inflation'  => round($personalInflation, 2),
            'months_emergency'    => $avgMonthlyExpense > 0
                ? round($totalBalance / $avgMonthlyExpense, 1)
                : 0,
        ]);
    }

    public function calculate(Request $request): JsonResponse
    {
        $request->validate([
            'income_change_pct'   => 'required|numeric|min:-50|max:200',
            'expense_change_pct'  => 'required|numeric|min:-50|max:100',
            'inflation_rate'      => 'required|numeric|min:0|max:100',
            'months_horizon'      => 'required|integer|min:1|max:60',
            'monthly_income'      => 'required|numeric|min:0',
            'avg_monthly_expense' => 'required|numeric|min:0',
            'total_balance'       => 'required|numeric',
            'total_card_debt'     => 'required|numeric|min:0',
        ]);

        $baseIncome  = (float) $request->monthly_income;
        $baseExpense = (float) $request->avg_monthly_expense;
        $balance     = (float) $request->total_balance;
        $cardDebt    = (float) $request->total_card_debt;
        $incomePct   = (float) $request->income_change_pct  / 100;
        $expensePct  = (float) $request->expense_change_pct / 100;
        $inflation   = (float) $request->inflation_rate     / 100;
        $months      = (int)   $request->months_horizon;

        $newIncome   = $baseIncome  * (1 + $incomePct);
        $newExpense  = $baseExpense * (1 + $expensePct);
        $newSavings  = $newIncome - $newExpense;
        $savingsRate = $newIncome > 0 ? $newSavings / $newIncome : 0;

        $monthlyInflation = $inflation / 12;
        $projections      = [];
        $runningBalance   = $balance;
        $runningDebt      = $cardDebt;

        for ($m = 1; $m <= $months; $m++) {
            $runningBalance += max(0, $newSavings);
            $runningDebt     = max(0, $runningDebt - max(0, min($newSavings * 0.3, $runningDebt)));
            $realBalance     = $runningBalance / ((1 + $monthlyInflation) ** $m);

            $projections[] = [
                'month'        => $m,
                'balance'      => round($runningBalance, 0),
                'real_balance' => round($realBalance, 0),
                'card_debt'    => round($runningDebt, 0),
            ];
        }

        $debtRatioScore  = $this->scoreDebtRatio(($cardDebt * 0.02) / max($newIncome, 1));
        $savingsScore    = $this->scoreSavingsRate($savingsRate);
        $emergencyMonths = $newExpense > 0 ? $balance / $newExpense : 0;
        $emergencyScore  = $this->scoreEmergency($emergencyMonths);
        $estimatedScore  = (int) round($debtRatioScore * 0.30 + $savingsScore * 0.30 + 60 * 0.20 + $emergencyScore * 0.20);

        $finalBalance = $projections[count($projections) - 1]['balance'] ?? $balance;
        $realFinal    = $projections[count($projections) - 1]['real_balance'] ?? $balance;

        return response()->json([
            'projections'        => $projections,
            'new_income'         => round($newIncome, 2),
            'new_expense'        => round($newExpense, 2),
            'new_savings'        => round($newSavings, 2),
            'savings_rate_pct'   => round($savingsRate * 100, 1),
            'estimated_score'    => $estimatedScore,
            'final_balance'      => $finalBalance,
            'real_final_balance' => $realFinal,
            'inflation_loss'     => round($finalBalance - $realFinal, 0),
            'months_emergency'   => $newExpense > 0 ? round($finalBalance / $newExpense, 1) : 0,
        ]);
    }

    private function scoreDebtRatio(float $ratio): int
    {
        return match (true) {
            $ratio <= 0.10 => 100, $ratio <= 0.20 => 85, $ratio <= 0.30 => 70,
            $ratio <= 0.40 => 50,  $ratio <= 0.50 => 30, default         => 10,
        };
    }

    private function scoreSavingsRate(float $rate): int
    {
        return match (true) {
            $rate >= 0.25 => 100, $rate >= 0.20 => 90, $rate >= 0.15 => 75,
            $rate >= 0.10 => 60,  $rate >= 0.05 => 45, $rate >= 0    => 25, default => 5,
        };
    }

    private function scoreEmergency(float $months): int
    {
        return match (true) {
            $months >= 6 => 100, $months >= 4 => 85, $months >= 3 => 70,
            $months >= 2 => 55,  $months >= 1 => 35, default       => 10,
        };
    }
}
