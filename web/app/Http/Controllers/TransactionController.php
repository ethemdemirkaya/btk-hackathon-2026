<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class TransactionController extends Controller
{
    public function index(Request $request): View
    {
        $user  = $request->user();
        $query = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('a.user_id', $user->id)
            ->select(
                't.id', 't.posted_at', 't.amount', 't.description',
                't.merchant_name', 't.merchant_category', 't.channel',
                'b.name as bank_name', 'b.logo as bank_logo',
                'a.account_type'
            );

        if ($search = $request->input('q')) {
            $query->where(function ($q) use ($search) {
                $q->where('t.description', 'like', "%{$search}%")
                  ->orWhere('t.merchant_name', 'like', "%{$search}%");
            });
        }

        $type = $request->input('type');
        if ($type === 'income')  $query->where('t.amount', '>', 0);
        if ($type === 'expense') $query->where('t.amount', '<', 0);

        if ($from = $request->input('from')) $query->whereDate('t.posted_at', '>=', $from);
        if ($to   = $request->input('to'))   $query->whereDate('t.posted_at', '<=', $to);

        $transactions = $query->orderByDesc('t.posted_at')->paginate(30)->withQueryString();

        // Summary stats (no filters)
        $stats = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.posted_at', '>=', now()->startOfMonth())
            ->selectRaw('SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) as income')
            ->selectRaw('SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END) as expense')
            ->selectRaw('COUNT(*) as total_count')
            ->first();

        return view('transactions.index', compact('transactions', 'stats'));
    }
}
