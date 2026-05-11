<?php

namespace App\Http\Controllers;

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
}
