<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class SubscriptionController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        $subscriptions = DB::table('subscriptions')
            ->where('user_id', $user->id)
            ->whereNull('cancelled_at')
            ->orderBy('next_billing_date')
            ->get();

        $totalMonthly = $subscriptions->where('billing_cycle', 'monthly')->sum('amount')
            + $subscriptions->where('billing_cycle', 'yearly')->sum(fn($s) => $s->amount / 12)
            + $subscriptions->where('billing_cycle', 'weekly')->sum(fn($s) => $s->amount * 4.33);

        // Auto-detect subscription candidates from recurring transactions
        $candidates = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subMonths(4))
            ->whereRaw("t.description REGEXP '(Spotify|Netflix|Apple|Amazon|YouTube|Disney|Microsoft|Adobe|iCloud|Gym|Spor Salonu|Üyelik|Abonelik|Prime)'")
            ->select('t.description', 't.merchant_name',
                DB::raw('AVG(ABS(t.amount)) as avg_amount'),
                DB::raw('COUNT(*) as occurrences'))
            ->groupBy('t.description', 't.merchant_name')
            ->having('occurrences', '>=', 2)
            ->orderByDesc('avg_amount')
            ->get();

        return view('subscriptions.index', compact('subscriptions', 'totalMonthly', 'candidates'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'              => 'required|string|max:200',
            'merchant_name'     => 'nullable|string|max:200',
            'amount'            => 'required|numeric|min:0',
            'billing_cycle'     => 'required|in:monthly,yearly,weekly',
            'next_billing_date' => 'required|date',
        ]);

        DB::table('subscriptions')->insert(array_merge($data, [
            'user_id'       => $request->user()->id,
            'status'        => 'active',
            'auto_detected' => false,
            'created_at'    => now(),
            'updated_at'    => now(),
        ]));

        return redirect()->route('subscriptions.index')->with('success', 'Abonelik eklendi.');
    }

    public function destroy(Request $request, int $id)
    {
        DB::table('subscriptions')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->update(['cancelled_at' => now(), 'status' => 'cancelled', 'updated_at' => now()]);

        if ($request->wantsJson()) return response()->json(['success' => true]);
        return redirect()->route('subscriptions.index')->with('success', 'Abonelik iptal edildi.');
    }
}
