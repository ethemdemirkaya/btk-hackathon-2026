<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class LoanController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        $loans = DB::table('loans as l')
            ->join('bank_connections as bc', 'bc.id', '=', 'l.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('l.user_id', $user->id)
            ->select('l.*', 'b.name as bank_name', 'b.logo as bank_logo', 'b.slug as bank_slug')
            ->orderBy('l.next_payment_date')
            ->get()
            ->map(function ($loan) {
                $loan->paid_pct = $loan->total_installments > 0
                    ? round($loan->paid_installments / $loan->total_installments * 100)
                    : 0;
                $loan->remaining_installments = $loan->total_installments - $loan->paid_installments;
                return $loan;
            });

        $totalBalance      = $loans->sum('current_balance');
        $totalNextPayment  = $loans->sum('next_payment_amount');
        $nextDue           = $loans->whereNotNull('next_payment_date')
                                   ->sortBy('next_payment_date')
                                   ->first();

        return view('loans.index', compact('loans', 'totalBalance', 'totalNextPayment', 'nextDue'));
    }
}
