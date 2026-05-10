<?php

namespace App\Services;

use App\Models\FinancialHealthScore;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Finansal Sağlık Skoru — 0–100 puan
 *
 * Bileşenler (her biri 25 puan):
 *  1. Borç Oranı (Debt Ratio)        — aylık borç ödemeleri / aylık gelir
 *  2. Tasarruf Oranı (Savings Rate)  — aylık net tasarruf / aylık gelir
 *  3. Harcama Tutarlılığı            — aylık harcama değişkenliği (CV)
 *  4. Acil Fon (Emergency Fund)      — toplam bakiye / aylık ortalama gider
 */
class FinancialHealthService
{
    public function calculate(User $user): FinancialHealthScore
    {
        $monthlyIncome = (float) ($user->monthly_income ?? 0);
        $details       = [];

        // ── 1. Borç Oranı ──────────────────────────────────────────────
        $monthlyDebtPayments = $this->getMonthlyDebtPayments($user->id);
        $debtRatioScore      = $this->scoreDebtRatio($monthlyDebtPayments, $monthlyIncome, $details);

        // ── 2. Tasarruf Oranı ───────────────────────────────────────────
        $avgMonthlyExpense = $this->getAvgMonthlyExpense($user->id);
        $savingsScore      = $this->scoreSavingsRate($monthlyIncome, $avgMonthlyExpense, $details);

        // ── 3. Harcama Tutarlılığı ──────────────────────────────────────
        $consistencyScore = $this->scoreExpenseConsistency($user->id, $details);

        // ── 4. Acil Fon ────────────────────────────────────────────────
        $totalBalance     = DB::table('accounts')->where('user_id', $user->id)->sum('balance');
        $emergencyScore   = $this->scoreEmergencyFund((float) $totalBalance, $avgMonthlyExpense, $details);

        $totalScore = (int) round(
            $debtRatioScore * 0.30 +
            $savingsScore   * 0.30 +
            $consistencyScore * 0.20 +
            $emergencyScore   * 0.20
        );

        $details['summary'] = [
            'debt_ratio_score'          => $debtRatioScore,
            'savings_rate_score'        => $savingsScore,
            'expense_consistency_score' => $consistencyScore,
            'emergency_fund_score'      => $emergencyScore,
            'total'                     => $totalScore,
        ];

        return FinancialHealthScore::updateOrCreate(
            ['user_id' => $user->id],
            [
                'score'                     => $totalScore,
                'debt_ratio_score'          => $debtRatioScore,
                'savings_rate_score'        => $savingsScore,
                'expense_consistency_score' => $consistencyScore,
                'emergency_fund_score'      => $emergencyScore,
                'details'                   => $details,
                'calculated_at'             => now(),
            ]
        );
    }

    public function getLatest(User $user): ?FinancialHealthScore
    {
        return FinancialHealthScore::where('user_id', $user->id)
            ->orderByDesc('calculated_at')
            ->first();
    }

    // ──────────────────────────────────────────────────────────────────────

    private function scoreDebtRatio(float $monthlyDebt, float $income, array &$details): int
    {
        if ($income <= 0) {
            $details['debt_ratio'] = ['score' => 50, 'note' => 'Gelir tanımsız'];
            return 50;
        }

        $ratio = $monthlyDebt / $income;
        // Ideal: < 20%, OK: < 35%, Warning: < 50%, Danger: > 50%
        $score = match (true) {
            $ratio <= 0.10 => 100,
            $ratio <= 0.20 => 85,
            $ratio <= 0.30 => 70,
            $ratio <= 0.40 => 50,
            $ratio <= 0.50 => 30,
            default        => 10,
        };

        $details['debt_ratio'] = [
            'monthly_debt'  => round($monthlyDebt, 2),
            'monthly_income'=> round($income, 2),
            'ratio_pct'     => round($ratio * 100, 1),
            'score'         => $score,
        ];

        return $score;
    }

    private function scoreSavingsRate(float $income, float $avgExpense, array &$details): int
    {
        if ($income <= 0) {
            $details['savings_rate'] = ['score' => 50, 'note' => 'Gelir tanımsız'];
            return 50;
        }

        $netSavings  = $income - $avgExpense;
        $savingsRate = $netSavings / $income;

        // Ideal: > 20%, OK: 10–20%, Low: 5–10%, Negative: < 0
        $score = match (true) {
            $savingsRate >= 0.25 => 100,
            $savingsRate >= 0.20 => 90,
            $savingsRate >= 0.15 => 75,
            $savingsRate >= 0.10 => 60,
            $savingsRate >= 0.05 => 45,
            $savingsRate >= 0    => 25,
            default              => 5,
        };

        $details['savings_rate'] = [
            'avg_monthly_expense' => round($avgExpense, 2),
            'monthly_income'      => round($income, 2),
            'net_savings'         => round($netSavings, 2),
            'savings_rate_pct'    => round($savingsRate * 100, 1),
            'score'               => $score,
        ];

        return $score;
    }

    private function scoreExpenseConsistency(int $userId, array &$details): int
    {
        // Coefficient of Variation of monthly expenses (lower = more consistent = better)
        $monthlyExpenses = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->select(
                DB::raw("DATE_FORMAT(t.posted_at, '%Y-%m') as month"),
                DB::raw('SUM(ABS(t.amount)) as total')
            )
            ->where('a.user_id', $userId)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subMonths(6))
            ->groupBy('month')
            ->get()
            ->pluck('total')
            ->map(fn ($v) => (float) $v);

        if ($monthlyExpenses->count() < 2) {
            $details['expense_consistency'] = ['score' => 60, 'note' => 'Yetersiz veri'];
            return 60;
        }

        $mean = $monthlyExpenses->avg();
        $std  = sqrt($monthlyExpenses->map(fn ($v) => ($v - $mean) ** 2)->avg());
        $cv   = $mean > 0 ? $std / $mean : 0;

        // CV < 0.10 = very consistent, CV > 0.40 = very erratic
        $score = match (true) {
            $cv <= 0.10 => 100,
            $cv <= 0.15 => 85,
            $cv <= 0.20 => 70,
            $cv <= 0.30 => 55,
            $cv <= 0.40 => 35,
            default     => 15,
        };

        $details['expense_consistency'] = [
            'months_analyzed'   => $monthlyExpenses->count(),
            'avg_monthly'       => round($mean, 2),
            'std_dev'           => round($std, 2),
            'coefficient_of_var'=> round($cv, 3),
            'score'             => $score,
        ];

        return $score;
    }

    private function scoreEmergencyFund(float $totalBalance, float $avgMonthlyExpense, array &$details): int
    {
        if ($avgMonthlyExpense <= 0) {
            $details['emergency_fund'] = ['score' => 50, 'note' => 'Gider verisi yok'];
            return 50;
        }

        $monthsCovered = $totalBalance / $avgMonthlyExpense;

        // Ideal: 6+ months, OK: 3–6, Low: 1–3, None: < 1
        $score = match (true) {
            $monthsCovered >= 6.0 => 100,
            $monthsCovered >= 4.0 => 85,
            $monthsCovered >= 3.0 => 70,
            $monthsCovered >= 2.0 => 55,
            $monthsCovered >= 1.0 => 35,
            default               => 10,
        };

        $details['emergency_fund'] = [
            'total_balance'   => round($totalBalance, 2),
            'avg_monthly_exp' => round($avgMonthlyExpense, 2),
            'months_covered'  => round($monthsCovered, 1),
            'score'           => $score,
        ];

        return $score;
    }

    private function getMonthlyDebtPayments(int $userId): float
    {
        // Kart borcu + kredi taksiti (aylık)
        $cardDebt  = (float) DB::table('cards')->where('user_id', $userId)->sum('current_debt') / 12;
        $loanPaymt = (float) DB::table('loans')
            ->join('bank_connections as bc', 'bc.id', '=', 'loans.bank_connection_id')
            ->where('bc.user_id', $userId)
            ->sum('loans.next_payment_amount');

        return $cardDebt + $loanPaymt;
    }

    private function getAvgMonthlyExpense(int $userId): float
    {
        $row = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->select(DB::raw('AVG(monthly_total) as avg_expense'))
            ->fromSub(
                DB::table('transactions as t2')
                    ->join('accounts as a2', 'a2.id', '=', 't2.account_id')
                    ->select(
                        DB::raw("DATE_FORMAT(t2.posted_at, '%Y-%m') as month"),
                        DB::raw('SUM(ABS(t2.amount)) as monthly_total')
                    )
                    ->where('a2.user_id', $userId)
                    ->where('t2.amount', '<', 0)
                    ->where('t2.posted_at', '>=', now()->subMonths(3))
                    ->groupBy('month'),
                'monthly_sums'
            )
            ->first();

        return $row ? (float) $row->avg_expense : 0;
    }
}
