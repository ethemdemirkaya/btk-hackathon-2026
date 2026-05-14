<?php

namespace App\Services;

use App\Models\FinancialHealthScore;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class FinancialHealthScoreService
{
    public function computeAndStore(User $user): FinancialHealthScore
    {
        // ── Income: 3-month average ────────────────────────────────────────
        $incomeRows = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '>', 0)
            ->where('t.posted_at', '>=', now()->subMonths(3))
            ->selectRaw("DATE_FORMAT(t.posted_at,'%Y-%m') as month, SUM(t.amount) as total")
            ->groupBy('month')
            ->get();

        $monthlyIncome = $incomeRows->isNotEmpty()
            ? (float) $incomeRows->avg('total')
            : (float) ($user->monthly_income ?? 0);

        // ── Expense: 3-month average ───────────────────────────────────────
        $expenseRows = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subMonths(3))
            ->selectRaw("DATE_FORMAT(t.posted_at,'%Y-%m') as month, SUM(ABS(t.amount)) as total")
            ->groupBy('month')
            ->get();

        $monthlyExpense = $expenseRows->isNotEmpty()
            ? (float) $expenseRows->avg('total')
            : 0;

        // ── Balance & debts ────────────────────────────────────────────────
        $totalBalance  = (float) DB::table('accounts')->where('user_id', $user->id)->sum('balance');
        $totalCardDebt = (float) DB::table('cards')->where('user_id', $user->id)->sum('current_debt');
        $totalLoanBal  = (float) DB::table('loans')->where('user_id', $user->id)->sum('current_balance');
        $totalDebt     = $totalCardDebt + $totalLoanBal;
        $annualIncome  = $monthlyIncome * 12;

        // ── Component scores ───────────────────────────────────────────────
        $debtRatioScore     = $this->scoreDebtRatio($annualIncome > 0 ? $totalDebt / $annualIncome : 1);
        $savingsRateScore   = $this->scoreSavingsRate($monthlyIncome > 0 ? ($monthlyIncome - $monthlyExpense) / $monthlyIncome : 0);
        $emergencyScore     = $this->scoreEmergencyFund($monthlyExpense > 0 ? $totalBalance / $monthlyExpense : 0);
        $consistencyScore   = $this->scoreConsistency($expenseRows->pluck('total')->toArray());

        // Weighted composite (debt 30 %, savings 30 %, emergency 25 %, consistency 15 %)
        $total = (int) round(
            $debtRatioScore   * 0.30 +
            $savingsRateScore * 0.30 +
            $emergencyScore   * 0.25 +
            $consistencyScore * 0.15
        );

        $componentData = [
            'debt_ratio'          => $debtRatioScore,
            'savings_rate'        => $savingsRateScore,
            'emergency_fund'      => $emergencyScore,
            'expense_consistency' => $consistencyScore,
            'monthly_income'      => round($monthlyIncome, 2),
            'monthly_expense'     => round($monthlyExpense, 2),
            'total_balance'       => round($totalBalance, 2),
            'total_debt'          => round($totalDebt, 2),
        ];

        $record = FinancialHealthScore::updateOrCreate(
            ['user_id' => $user->id],
            [
                'score'                     => max(0, min(100, $total)),
                'components'                => $componentData,
                'debt_ratio_score'          => $debtRatioScore,
                'savings_rate_score'        => $savingsRateScore,
                'emergency_fund_score'      => $emergencyScore,
                'expense_consistency_score' => $consistencyScore,
                'details'                   => [
                    'monthly_income'  => round($monthlyIncome, 2),
                    'monthly_expense' => round($monthlyExpense, 2),
                    'total_balance'   => round($totalBalance, 2),
                    'total_debt'      => round($totalDebt, 2),
                ],
                'calculated_at' => now(),
            ]
        );

        return $record;
    }

    /**
     * Recompute on every call so the score is always live.
     * $maxAgeMinutes acts as a short read-through cache only — keeps the cost
     * predictable when the dashboard loads several derived figures in a row.
     */
    public function getOrCompute(User $user, int $maxAgeMinutes = 0): FinancialHealthScore
    {
        if ($maxAgeMinutes > 0) {
            $existing = FinancialHealthScore::where('user_id', $user->id)
                ->where('calculated_at', '>=', now()->subMinutes($maxAgeMinutes))
                ->latest('calculated_at')
                ->first();
            if ($existing) return $existing;
        }

        return $this->computeAndStore($user);
    }

    private function scoreDebtRatio(float $ratio): int
    {
        return match (true) {
            $ratio <= 0.10 => 100,
            $ratio <= 0.20 => 85,
            $ratio <= 0.30 => 70,
            $ratio <= 0.40 => 50,
            $ratio <= 0.60 => 30,
            default        => 10,
        };
    }

    private function scoreSavingsRate(float $rate): int
    {
        return match (true) {
            $rate >= 0.25 => 100,
            $rate >= 0.20 => 90,
            $rate >= 0.15 => 75,
            $rate >= 0.10 => 60,
            $rate >= 0.05 => 45,
            $rate >= 0    => 25,
            default       => 5,
        };
    }

    private function scoreEmergencyFund(float $months): int
    {
        return match (true) {
            $months >= 6 => 100,
            $months >= 4 => 85,
            $months >= 3 => 70,
            $months >= 2 => 55,
            $months >= 1 => 35,
            default      => 10,
        };
    }

    private function scoreConsistency(array $values): int
    {
        if (count($values) < 2) return 70;

        $avg = array_sum($values) / count($values);
        if ($avg <= 0) return 70;

        $variance = array_sum(array_map(fn ($v) => ($v - $avg) ** 2, $values)) / count($values);
        $cv = sqrt($variance) / $avg;

        return match (true) {
            $cv <= 0.10 => 100,
            $cv <= 0.20 => 85,
            $cv <= 0.35 => 70,
            $cv <= 0.50 => 55,
            $cv <= 0.70 => 35,
            default     => 15,
        };
    }
}
