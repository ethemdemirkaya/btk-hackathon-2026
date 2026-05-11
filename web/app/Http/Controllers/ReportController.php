<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\View\View;

class ReportController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        // 6-month cash flow for chart
        $cashFlow = collect();
        for ($i = 5; $i >= 0; $i--) {
            $month = now()->subMonths($i);
            $label = $month->locale('tr')->isoFormat('MMM YY');
            $key   = $month->format('Y-m');

            $row = DB::table('transactions as t')
                ->join('accounts as a', 'a.id', '=', 't.account_id')
                ->where('a.user_id', $user->id)
                ->whereRaw("DATE_FORMAT(t.posted_at, '%Y-%m') = ?", [$key])
                ->selectRaw('SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) as income')
                ->selectRaw('SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END) as expense')
                ->first();

            $cashFlow->push([
                'label'   => $label,
                'income'  => (float) ($row->income ?? 0),
                'expense' => (float) ($row->expense ?? 0),
                'net'     => (float) ($row->income ?? 0) - (float) ($row->expense ?? 0),
            ]);
        }

        // Summary stats
        $totalIncome  = $cashFlow->sum('income');
        $totalExpense = $cashFlow->sum('expense');
        $totalNet     = $totalIncome - $totalExpense;
        $bestMonth    = $cashFlow->sortByDesc('net')->first();
        $worstMonth   = $cashFlow->sortBy('net')->first();

        // Top categories (last 6 months)
        $categoryBreakdown = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subMonths(6))
            ->groupBy('t.merchant_category')
            ->selectRaw('t.merchant_category, SUM(ABS(t.amount)) as total, COUNT(*) as cnt')
            ->orderByDesc('total')
            ->limit(8)
            ->get();

        // Available months (for PDF picker)
        $availableMonths = collect();
        for ($i = 11; $i >= 0; $i--) {
            $m = now()->subMonths($i);
            $availableMonths->push([
                'value' => $m->format('Y-m'),
                'label' => $m->locale('tr')->isoFormat('MMMM YYYY'),
            ]);
        }

        // Transaction count
        $txCount = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.posted_at', '>=', now()->subMonths(6))
            ->count();

        return view('reports.index', compact(
            'cashFlow', 'totalIncome', 'totalExpense', 'totalNet',
            'bestMonth', 'worstMonth', 'categoryBreakdown', 'availableMonths', 'txCount'
        ));
    }

    public function generate(Request $request)
    {
        $request->validate([
            'month' => 'nullable|date_format:Y-m',
        ]);

        $user  = $request->user();
        $month = $request->input('month')
            ? Carbon::createFromFormat('Y-m', $request->input('month'))->startOfMonth()
            : Carbon::now()->startOfMonth();

        $periodStart = $month->copy()->startOfMonth();
        $periodEnd   = $month->copy()->endOfMonth();
        $periodLabel = $month->locale('tr')->isoFormat('MMMM YYYY');

        // ── Accounts & balances ──────────────────────────────────────────
        $accounts = DB::table('accounts as a')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('a.user_id', $user->id)
            ->select('a.iban', 'a.account_type', 'a.balance', 'b.name as bank_name')
            ->get();

        $totalBalance = $accounts->sum('balance');

        // ── Cards & debt ─────────────────────────────────────────────────
        $cards = DB::table('cards')->where('user_id', $user->id)->get();
        $totalCardDebt = $cards->sum('current_debt');

        // ── Monthly transactions ─────────────────────────────────────────
        $transactions = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
            ->select('t.posted_at', 't.amount', 't.description', 't.merchant_name',
                     't.merchant_category', DB::raw("'account' as source"))
            ->orderBy('t.posted_at', 'desc')
            ->limit(50)
            ->get();

        $income   = $transactions->where('amount', '>', 0)->sum('amount');
        $expense  = abs($transactions->where('amount', '<', 0)->sum('amount'));
        $netFlow  = $income - $expense;

        // ── Category breakdown ───────────────────────────────────────────
        $categoryBreakdown = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
            ->groupBy('t.merchant_category')
            ->select('t.merchant_category', DB::raw('SUM(ABS(t.amount)) as total'))
            ->orderByDesc('total')
            ->limit(8)
            ->get();

        // ── Health score ─────────────────────────────────────────────────
        $healthScore = DB::table('financial_health_scores')
            ->where('user_id', $user->id)
            ->orderByDesc('calculated_at')
            ->first();

        // ── Personal inflation ───────────────────────────────────────────
        try {
            $piResult = app(\App\Services\PersonalInflationService::class)->calculate($user);
            $personalInflation = (float) ($piResult['personal_rate'] ?? $piResult['tufe_rate'] ?? 37.86);
        } catch (\Throwable) {
            $personalInflation = (float) (DB::table('inflation_category_rates')
                ->where('tuik_category_slug', 'genel')
                ->orderByDesc('period_year')->orderByDesc('period_month')
                ->value('annual_change_rate') ?? 37.86);
        }

        // ── Loans ────────────────────────────────────────────────────────
        $loans = DB::table('loans')->where('user_id', $user->id)->get();

        // ── Top merchants ─────────────────────────────────────────────────
        $topMerchants = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
            ->whereNotNull('t.merchant_name')
            ->groupBy('t.merchant_name')
            ->select('t.merchant_name', DB::raw('SUM(ABS(t.amount)) as total'), DB::raw('COUNT(*) as cnt'))
            ->orderByDesc('total')
            ->limit(5)
            ->get();

        // ── Active Goals ──────────────────────────────────────────────────
        $goals = DB::table('goals')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->whereNull('deleted_at')
            ->orderByDesc('target_amount')
            ->get();

        // ── Active Budgets (with per-period spending) ─────────────────────
        $budgets = DB::table('budgets as b')
            ->join('categories as c', 'c.id', '=', 'b.category_id')
            ->where('b.user_id', $user->id)
            ->select('b.id', 'b.amount', 'b.period', 'b.alert_threshold', 'b.category_id', 'c.name as category_name')
            ->get()
            ->map(function ($bgt) use ($user, $periodStart, $periodEnd) {
                $spent = DB::table('transactions as t')
                    ->join('accounts as a', 'a.id', '=', 't.account_id')
                    ->where('a.user_id', $user->id)
                    ->where('t.amount', '<', 0)
                    ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
                    ->sum(DB::raw('ABS(t.amount)'));
                $bgt->spent = (float) $spent;
                return $bgt;
            });

        // ── Active Subscriptions ──────────────────────────────────────────
        $subscriptions = DB::table('subscriptions')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->whereNull('deleted_at')
            ->orderBy('name')
            ->get();

        $data = compact(
            'user', 'periodLabel', 'periodStart', 'periodEnd',
            'accounts', 'totalBalance', 'cards', 'totalCardDebt',
            'transactions', 'income', 'expense', 'netFlow',
            'categoryBreakdown', 'healthScore', 'personalInflation',
            'loans', 'topMerchants', 'goals', 'budgets', 'subscriptions'
        );

        $pdf = Pdf::loadView('reports.monthly', $data)
            ->setPaper('a4', 'portrait')
            ->setOption('isHtml5ParserEnabled', true)
            ->setOption('isPhpEnabled', false)
            ->setOption('defaultFont', 'dejavusans');

        $filename = 'paranette-rapor-' . $month->format('Y-m') . '.pdf';

        return $pdf->download($filename);
    }
}
