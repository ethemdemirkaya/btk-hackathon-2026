<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class GoalController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        $goals = DB::table('goals')
            ->where('user_id', $user->id)
            ->whereIn('status', ['active', 'completed'])
            ->orderBy('target_date')
            ->get()
            ->map(function ($g) {
                $g->pct = $g->target_amount > 0
                    ? min(100, round((float)$g->current_amount / (float)$g->target_amount * 100))
                    : 0;
                $g->remaining = max(0, (float)$g->target_amount - (float)$g->current_amount);
                $g->months_left = $g->target_date
                    ? max(0, (int) round(now()->diffInMonths(\Carbon\Carbon::parse($g->target_date), false)))
                    : null;
                return $g;
            });

        return view('goals.index', compact('goals'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'                 => 'required|string|max:200',
            'target_amount'        => 'required|numeric|min:1',
            'current_amount'       => 'nullable|numeric|min:0',
            'target_date'          => 'nullable|date|after:today',
            'monthly_contribution' => 'nullable|numeric|min:0',
        ]);

        DB::table('goals')->insert(array_merge($data, [
            'user_id'        => $request->user()->id,
            'current_amount' => $data['current_amount'] ?? 0,
            'status'         => 'active',
            'created_at'     => now(),
            'updated_at'     => now(),
        ]));

        return redirect()->route('goals.index')->with('success', 'Hedef eklendi.');
    }

    public function addFunds(Request $request, int $id)
    {
        $request->validate(['amount' => 'required|numeric|min:0.01']);
        $goal = DB::table('goals')->where('id', $id)->where('user_id', $request->user()->id)->first();

        abort_unless($goal, 403);

        $newAmount = (float)$goal->current_amount + (float)$request->amount;
        $status    = $newAmount >= (float)$goal->target_amount ? 'completed' : 'active';

        DB::table('goals')->where('id', $id)->update([
            'current_amount' => $newAmount,
            'status'         => $status,
            'updated_at'     => now(),
        ]);

        return redirect()->route('goals.index')
            ->with('success', $status === 'completed' ? 'Tebrikler! Hedefe ulaştınız.' : 'Ödeme eklendi.');
    }

    public function destroy(Request $request, int $id)
    {
        DB::table('goals')->where('id', $id)->where('user_id', $request->user()->id)->delete();

        if ($request->wantsJson()) return response()->json(['success' => true]);
        return redirect()->route('goals.index')->with('success', 'Hedef silindi.');
    }

    /**
     * Suggest a monthly contribution amount based on the user's average
     * monthly savings over the last 3 months and the goal's remaining amount.
     */
    public function suggestContribution(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $goal = DB::table('goals')->where('id', $id)->where('user_id', $user->id)->first();
        abort_unless($goal, 404);

        // Avg monthly net savings (last 3 months)
        $sub = DB::table('transactions as t2')
            ->join('accounts as a2', 'a2.id', '=', 't2.account_id')
            ->select(
                DB::raw("DATE_FORMAT(t2.posted_at, '%Y-%m') as month"),
                DB::raw('SUM(t2.amount) as net')
            )
            ->where('a2.user_id', $user->id)
            ->where('t2.posted_at', '>=', now()->subMonths(3))
            ->groupBy('month');

        $avgSavings = (float) DB::table($sub, 'monthly_sums')->avg('net') ?? 0;

        $remaining   = max(0, (float)$goal->target_amount - (float)$goal->current_amount);
        $monthsLeft  = $goal->target_date
            ? max(1, (int) ceil(now()->diffInMonths(\Carbon\Carbon::parse($goal->target_date), false)))
            : 12;

        // Suggested = ceiling of (remaining / months_left), but no more than avg savings
        $suggested   = $remaining > 0 ? ceil($remaining / $monthsLeft) : 0;
        $affordable  = $avgSavings > 0 ? min($suggested, $avgSavings * 0.4) : $suggested;
        $affordable  = max(1, round($affordable, -2)); // round to nearest 100

        return response()->json([
            'suggested'       => $suggested,
            'affordable'      => $affordable,
            'avg_savings'     => round($avgSavings, 0),
            'months_left'     => $monthsLeft,
            'remaining'       => $remaining,
        ]);
    }
}
