<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class CardController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        $cards = DB::table('cards as c')
            ->join('accounts as a', 'a.id', '=', 'c.account_id')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('c.user_id', $user->id)
            ->select(
                'c.*',
                'b.name as bank_name',
                'b.logo as bank_logo',
                'b.slug as bank_slug'
            )
            ->orderByRaw("FIELD(c.type,'credit','debit')")
            ->orderBy('b.name')
            ->get();

        $totalDebt  = $cards->where('type', 'credit')->sum('current_debt');
        $totalLimit = $cards->where('type', 'credit')->sum('credit_limit');
        $totalUsage = $totalLimit > 0 ? round($totalDebt / $totalLimit * 100) : 0;

        // Recent card transactions (last 30 days — cards don't have direct tx link in this schema,
        // so we pull from transactions table via account_id)
        $recentTx = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subDays(30))
            ->select('t.posted_at', 't.amount', 't.description', 't.merchant_name')
            ->orderByDesc('t.posted_at')
            ->limit(10)
            ->get();

        return view('cards.index', compact('cards', 'totalDebt', 'totalLimit', 'totalUsage', 'recentTx'));
    }
}
