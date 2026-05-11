<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;

class ReportController extends Controller
{
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
        $expense  = $transactions->where('amount', '<', 0)->sum('amount');
        $netFlow  = $income + $expense;

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

        $data = compact(
            'user', 'periodLabel', 'periodStart', 'periodEnd',
            'accounts', 'totalBalance', 'cards', 'totalCardDebt',
            'transactions', 'income', 'expense', 'netFlow',
            'categoryBreakdown', 'healthScore', 'personalInflation',
            'loans', 'topMerchants'
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
