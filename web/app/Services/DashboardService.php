<?php

namespace App\Services;

use App\Models\Account;
use App\Models\AgentInsight;
use App\Models\BankConnection;
use App\Models\Card;
use App\Models\InflationCategoryRate;
use App\Models\InflationRate;
use App\Models\Loan;
use App\Models\Transaction;
use App\Models\User;
use App\Services\PersonalInflationService;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class DashboardService
{
    public function getSummary(User $user): array
    {
        $totalBalance  = Account::where('user_id', $user->id)->sum('balance');
        $totalCardDebt = Card::where('user_id', $user->id)->sum('current_debt');
        $totalLoanBal  = Loan::where('user_id', $user->id)->sum('current_balance');
        $healthScore   = DB::table('financial_health_scores')
            ->where('user_id', $user->id)
            ->orderByDesc('calculated_at')
            ->value('score');

        return [
            'total_balance'   => (float) $totalBalance,
            'total_card_debt' => (float) $totalCardDebt,
            'total_loan'      => (float) $totalLoanBal,
            'net_worth'       => (float) $totalBalance - (float) $totalCardDebt - (float) $totalLoanBal,
            'health_score'    => $healthScore ? (int) $healthScore : null,
        ];
    }

    /** Returns smart financial alerts: upcoming payments, high card usage */
    public function getSmartAlerts(User $user): array
    {
        $alerts = [];

        // Upcoming loan payments within 15 days
        $loans = DB::table('loans as l')
            ->join('bank_connections as bc', 'bc.id', '=', 'l.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('l.user_id', $user->id)
            ->whereNotNull('l.next_payment_date')
            ->where('l.next_payment_date', '>=', now()->toDateString())
            ->where('l.next_payment_date', '<=', now()->addDays(15)->toDateString())
            ->select('l.next_payment_date', 'l.next_payment_amount', 'b.name as bank_name')
            ->orderBy('l.next_payment_date')
            ->get();

        foreach ($loans as $loan) {
            $daysLeft = (int) round(Carbon::now()->startOfDay()->diffInDays(
                Carbon::parse($loan->next_payment_date)->startOfDay(), false
            ));
            $alerts[] = [
                'type'  => $daysLeft <= 3 ? 'danger' : 'warning',
                'icon'  => 'tabler-file-invoice',
                'title' => $daysLeft === 0 ? 'Bugün kredi ödemesi var' : ($daysLeft . ' gün sonra kredi ödemesi'),
                'body'  => $loan->bank_name . ' — ₺' . number_format((float) $loan->next_payment_amount, 0, ',', '.'),
                'link'  => route('loans.index'),
            ];
        }

        // High credit card usage
        $cards = DB::table('cards as c')
            ->join('accounts as a', 'a.id', '=', 'c.account_id')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('c.user_id', $user->id)
            ->where('c.type', 'credit')
            ->where('c.credit_limit', '>', 0)
            ->select('c.current_debt', 'c.credit_limit', 'b.name as bank_name')
            ->get();

        foreach ($cards as $card) {
            $usage = min(100, (int) round((float) $card->current_debt / (float) $card->credit_limit * 100));
            if ($usage >= 65) {
                $alerts[] = [
                    'type'  => $usage >= 80 ? 'danger' : 'warning',
                    'icon'  => 'tabler-credit-card',
                    'title' => 'Kart limiti %' . $usage . ' kullanıldı',
                    'body'  => $card->bank_name . ' — ₺' . number_format((float) $card->current_debt, 0, ',', '.') . ' borç',
                    'link'  => route('cards.index'),
                ];
            }
        }

        return array_slice($alerts, 0, 4);
    }

    /** Returns 6-month cash flow: array of { month, income, expense } */
    public function getCashFlowData(User $user, int $months = 6): array
    {
        $start = Carbon::now()->startOfMonth()->subMonths($months - 1);

        $rows = Transaction::select(
                DB::raw("DATE_FORMAT(posted_at, '%Y-%m') as month"),
                DB::raw('SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as income'),
                DB::raw('SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as expense')
            )
            ->whereHas('account', fn ($q) => $q->where('user_id', $user->id))
            ->where('posted_at', '>=', $start)
            ->groupBy('month')
            ->orderBy('month')
            ->get();

        // Fill gaps with zeros for missing months
        $result = [];
        for ($i = $months - 1; $i >= 0; $i--) {
            $key = Carbon::now()->startOfMonth()->subMonths($i)->format('Y-m');
            $row = $rows->firstWhere('month', $key);
            $result[] = [
                'month'   => $key,
                'income'  => $row ? round((float) $row->income, 2) : 0,
                'expense' => $row ? round((float) $row->expense, 2) : 0,
            ];
        }

        return $result;
    }

    /** Returns top-N category spending last 30 days for donut chart */
    public function getCategorySpending(User $user, int $days = 30, int $limit = 8): array
    {
        $since = Carbon::now()->subDays($days);

        $rows = Transaction::select('categories.name', DB::raw('SUM(ABS(amount)) as total'))
            ->join('categories', 'transactions.category_id', '=', 'categories.id')
            ->whereHas('account', fn ($q) => $q->where('user_id', $user->id))
            ->where('transactions.posted_at', '>=', $since)
            ->where('transactions.amount', '<', 0)
            ->whereNotNull('transactions.category_id')
            ->groupBy('categories.id', 'categories.name')
            ->orderByDesc('total')
            ->limit($limit)
            ->get();

        return $rows->map(fn ($r) => [
            'category' => $r->name,
            'total'    => round((float) $r->total, 2),
        ])->all();
    }

    /** Returns 10 most recent transactions */
    public function getRecentTransactions(User $user, int $limit = 10): Collection
    {
        return Transaction::with('account.bankConnection.bank', 'category')
            ->whereHas('account', fn ($q) => $q->where('user_id', $user->id))
            ->orderByDesc('posted_at')
            ->limit($limit)
            ->get();
    }

    /** Returns user's bank connections with accounts */
    public function getBankConnections(User $user): Collection
    {
        return BankConnection::with(['bank', 'accounts'])
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->get();
    }

    /** Returns personal vs TÜFE inflation for last 6 months */
    public function getInflationComparison(User $user): array
    {
        // inflation_rates is global (no user_id) — get last 6 months of TÜFE headline rates
        $tufeRows = InflationRate::where('source', 'tuik')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->limit(6)->get();

        // Fallback: derive from inflation_category_rates (genel slug = headline)
        if ($tufeRows->isEmpty()) {
            $catRows = InflationCategoryRate::where('tuik_category_slug', 'genel')
                ->orderByDesc('period_year')->orderByDesc('period_month')
                ->limit(6)->get();

            if ($catRows->isEmpty()) {
                return [];
            }

            $tufeRows = $catRows->map(fn ($r) => (object) [
                'period_year'          => $r->period_year,
                'period_month'         => $r->period_month,
                'headline_annual_rate' => $r->annual_change_rate,
            ]);
        }

        // Compute current personal inflation once and reuse for all months shown
        $personalRate = null;
        try {
            $personalResult = app(PersonalInflationService::class)->calculate($user);
            $personalRate   = isset($personalResult['personal_rate']) ? (float) $personalResult['personal_rate'] : null;
        } catch (\Throwable) {}

        $result = [];
        foreach ($tufeRows as $row) {
            $period   = "{$row->period_year}-" . str_pad($row->period_month, 2, '0', STR_PAD_LEFT);
            $result[] = [
                'month'    => $period,
                'personal' => $personalRate !== null ? round($personalRate, 2) : null,
                'tufe'     => round((float) $row->headline_annual_rate, 2),
            ];
        }

        return array_reverse($result);
    }

    /**
     * Returns the current personal inflation snapshot.
     * ['personal_rate', 'tufe_rate', 'diff', 'breakdown', ...]
     */
    public function getPersonalInflation(User $user): array
    {
        $tufeRate = (float) (InflationCategoryRate::where('tuik_category_slug', 'genel')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->value('annual_change_rate') ?? 37.86);

        try {
            $result = app(PersonalInflationService::class)->calculate($user);
            if (! isset($result['tufe_rate'])) {
                $result['tufe_rate'] = $tufeRate;
            }
            return $result;
        } catch (\Throwable) {
            return [
                'personal_rate' => null,
                'tufe_rate'     => $tufeRate,
                'diff'          => null,
                'breakdown'     => [],
                'period'        => null,
            ];
        }
    }

    /** Returns latest health score record with component breakdown */
    public function getHealthScoreDetails(User $user): ?object
    {
        return DB::table('financial_health_scores')
            ->where('user_id', $user->id)
            ->orderByDesc('calculated_at')
            ->first();
    }

    /** Returns current month budget utilization — top 4 by % used */
    public function getBudgetSummary(User $user, int $limit = 4): array
    {
        $period  = now()->format('Y-m');
        $budgets = DB::table('budgets as b')
            ->leftJoin('categories as c', 'c.id', '=', 'b.category_id')
            ->where('b.user_id', $user->id)
            ->where('b.period', $period)
            ->select('b.id', 'b.amount', 'b.category_id', 'c.name as category_name')
            ->get();

        if ($budgets->isEmpty()) return [];

        $actualByCategory = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->startOfMonth())
            ->whereNotNull('t.category_id')
            ->select('t.category_id', DB::raw('SUM(ABS(t.amount)) as spent'))
            ->groupBy('t.category_id')
            ->pluck('spent', 'category_id');

        return $budgets->map(function ($b) use ($actualByCategory) {
            $spent = (float) ($actualByCategory[$b->category_id] ?? 0);
            $pct   = $b->amount > 0 ? min(100, round($spent / (float) $b->amount * 100)) : 0;
            return [
                'name'       => $b->category_name ?? 'Diğer',
                'amount'     => (float) $b->amount,
                'spent'      => $spent,
                'remaining'  => max(0, (float) $b->amount - $spent),
                'pct'        => $pct,
                'over_budget'=> $spent > (float) $b->amount,
            ];
        })
        ->sortByDesc('pct')
        ->take($limit)
        ->values()
        ->all();
    }

    /** Returns up to 3 recent undismissed AI insights (filters out empty / error-body insights) */
    public function getRecentInsights(User $user, int $limit = 3): Collection
    {
        return AgentInsight::where('user_id', $user->id)
            ->where('is_dismissed', false)
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->whereNotNull('title')
            ->where('title', '!=', '')
            ->whereNotNull('body')
            ->where('body', '!=', '')
            ->where('body', 'not like', '%hata oluştu%')
            ->where('body', 'not like', '%rate-limited%')
            ->where('body', 'not like', '%API error%')
            ->where('body', 'not like', '%503%')
            ->where('body', 'not like', '%429%')
            ->where('body', 'not like', '%yoğun talep%')
            ->where('body', 'not like', '%baş finansal asistan%')
            ->orderByDesc('importance')
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();
    }
}
