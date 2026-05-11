<?php

namespace App\Services;

use App\Models\Account;
use App\Models\AgentInsight;
use App\Models\BankConnection;
use App\Models\Card;
use App\Models\Loan;
use App\Models\Transaction;
use App\Models\User;
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

    /** Returns personal vs TÜFE inflation for last 3 months per category */
    public function getInflationComparison(User $user): array
    {
        $rows = DB::table('inflation_rates as ir')
            ->select('ir.reference_month', 'ir.annual_rate')
            ->where('ir.user_id', $user->id)
            ->orderByDesc('ir.reference_month')
            ->limit(6)
            ->get();

        $tufe = DB::table('inflation_category_rates as icr')
            ->select('icr.reference_month', DB::raw('AVG(icr.annual_rate) as rate'))
            ->groupBy('icr.reference_month')
            ->orderByDesc('icr.reference_month')
            ->limit(6)
            ->get()
            ->keyBy('reference_month');

        return $rows->map(fn ($r) => [
            'month'    => $r->reference_month,
            'personal' => round((float) $r->annual_rate, 2),
            'tufe'     => round((float) ($tufe->get($r->reference_month)?->rate ?? 0), 2),
        ])->values()->all();
    }

    /** Returns up to 3 recent undismissed AI insights */
    public function getRecentInsights(User $user, int $limit = 3): Collection
    {
        return AgentInsight::where('user_id', $user->id)
            ->where('is_dismissed', false)
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->orderByDesc('importance')
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();
    }
}
