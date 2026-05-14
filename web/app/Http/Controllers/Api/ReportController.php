<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FinancialHealthScoreService;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function __construct(
        private readonly FinancialHealthScoreService $healthScoreService,
    ) {}

    public function summary(Request $request): JsonResponse
    {
        $request->validate(['month' => 'nullable|date_format:Y-m']);

        $user  = $request->user();
        $month = $request->input('month')
            ? Carbon::createFromFormat('Y-m', $request->input('month'))->startOfMonth()
            : Carbon::now()->startOfMonth();

        $periodStart = $month->copy()->startOfMonth();
        $periodEnd   = $month->copy()->endOfMonth();

        // 6-month cash flow
        $cashFlow = collect();
        for ($i = 5; $i >= 0; $i--) {
            $m   = now()->subMonths($i);
            $key = $m->format('Y-m');

            $row = DB::table('transactions as t')
                ->join('accounts as a', 'a.id', '=', 't.account_id')
                ->where('a.user_id', $user->id)
                ->whereRaw("DATE_FORMAT(t.posted_at, '%Y-%m') = ?", [$key])
                ->selectRaw('SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) as income')
                ->selectRaw('SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END) as expense')
                ->first();

            $cashFlow->push([
                'month'   => $key,
                'income'  => (float) ($row->income  ?? 0),
                'expense' => (float) ($row->expense ?? 0),
                'net'     => (float) ($row->income  ?? 0) - (float) ($row->expense ?? 0),
            ]);
        }

        // Monthly transactions summary
        $monthRow = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
            ->selectRaw('SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) as income')
            ->selectRaw('SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END) as expense')
            ->selectRaw('COUNT(*) as tx_count')
            ->first();

        // Category breakdown
        $categories = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
            ->groupBy('t.merchant_category')
            ->select('t.merchant_category', DB::raw('SUM(ABS(t.amount)) as total'), DB::raw('COUNT(*) as cnt'))
            ->orderByDesc('total')
            ->limit(8)
            ->get();

        // Top merchants
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

        $healthScoreRecord = $this->healthScoreService->getOrCompute($user, 60);

        return response()->json([
            'period'           => $month->format('Y-m'),
            'income'           => (float) ($monthRow->income  ?? 0),
            'expense'          => (float) ($monthRow->expense ?? 0),
            'net_flow'         => (float) ($monthRow->income  ?? 0) - (float) ($monthRow->expense ?? 0),
            'tx_count'         => (int) ($monthRow->tx_count ?? 0),
            'cash_flow'        => $cashFlow->values(),
            'categories'       => $categories->values(),
            'top_merchants'    => $topMerchants->values(),
            'health_score'     => (int) $healthScoreRecord->score,
        ]);
    }

    public function pdf(Request $request): Response
    {
        $request->validate(['month' => 'nullable|date_format:Y-m']);

        $user  = $request->user();
        $month = $request->input('month')
            ? Carbon::createFromFormat('Y-m', $request->input('month'))->startOfMonth()
            : Carbon::now()->startOfMonth();

        $periodStart = $month->copy()->startOfMonth();
        $periodEnd   = $month->copy()->endOfMonth();
        $periodLabel = $month->locale('tr')->isoFormat('MMMM YYYY');

        $accounts = DB::table('accounts as a')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('a.user_id', $user->id)
            ->select('a.iban', 'a.account_type', 'a.balance', 'b.name as bank_name')
            ->get();

        $cards         = DB::table('cards')->where('user_id', $user->id)->get();
        $totalBalance  = $accounts->sum('balance');
        $totalCardDebt = $cards->sum('current_debt');

        $transactions = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
            ->select('t.posted_at', 't.amount', 't.description', 't.merchant_name', 't.merchant_category')
            ->orderBy('t.posted_at', 'desc')
            ->limit(50)
            ->get();

        $income  = $transactions->where('amount', '>', 0)->sum('amount');
        $expense = abs($transactions->where('amount', '<', 0)->sum('amount'));
        $netFlow = $income - $expense;

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

        $healthScore = $this->healthScoreService->getOrCompute($user, 60);

        $personalInflation = (float) (DB::table('inflation_category_rates')
            ->where('tuik_category_slug', 'genel')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->value('annual_change_rate') ?? 37.86);

        $loans         = DB::table('loans')->where('user_id', $user->id)->get();
        $goals         = DB::table('goals')->where('user_id', $user->id)->where('status', 'active')->whereNull('deleted_at')->get();
        $subscriptions = DB::table('subscriptions')->where('user_id', $user->id)->where('status', 'active')->whereNull('deleted_at')->get();
        $topMerchants  = DB::table('transactions as t')
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

        $budgets = DB::table('budgets as b')
            ->join('categories as c', 'c.id', '=', 'b.category_id')
            ->where('b.user_id', $user->id)
            ->select('b.id', 'b.amount', 'b.period', 'b.alert_threshold', 'c.name as category_name')
            ->get()
            ->map(function ($bgt) use ($user, $periodStart, $periodEnd) {
                $bgt->spent = (float) DB::table('transactions as t')
                    ->join('accounts as a', 'a.id', '=', 't.account_id')
                    ->where('a.user_id', $user->id)
                    ->where('t.amount', '<', 0)
                    ->whereBetween('t.posted_at', [$periodStart, $periodEnd])
                    ->sum(DB::raw('ABS(t.amount)'));
                return $bgt;
            });

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
