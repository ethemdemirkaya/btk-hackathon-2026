<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class BudgetController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        $budgets = DB::table('budgets as b')
            ->leftJoin('categories as c', 'c.id', '=', 'b.category_id')
            ->where('b.user_id', $user->id)
            ->where('b.period', now()->format('Y-m'))
            ->select('b.*', 'c.name as category_name', 'c.icon as category_icon')
            ->get();

        // Actual spending this month per category
        $actualByCategory = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->startOfMonth())
            ->whereNotNull('t.category_id')
            ->select('t.category_id', DB::raw('SUM(ABS(t.amount)) as spent'))
            ->groupBy('t.category_id')
            ->pluck('spent', 'category_id');

        // Enrich budgets with actual spending
        $budgets = $budgets->map(function ($b) use ($actualByCategory) {
            $spent = (float) ($actualByCategory[$b->category_id] ?? 0);
            $b->spent = $spent;
            $b->remaining = max(0, (float)$b->amount - $spent);
            $b->pct = $b->amount > 0 ? min(100, round($spent / $b->amount * 100)) : 0;
            $b->over_budget = $spent > (float) $b->amount;
            return $b;
        });

        $categories = DB::table('categories')->whereNull('parent_id')->get();
        $currentMonth = now()->format('Y-m');

        return view('budgets.index', compact('budgets', 'categories', 'currentMonth'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'category_id'     => 'required|integer|exists:categories,id',
            'amount'          => 'required|numeric|min:1',
            'alert_threshold' => 'nullable|numeric|min:1|max:100',
        ]);

        $period = now()->format('Y-m');

        DB::table('budgets')->updateOrInsert(
            ['user_id' => $request->user()->id, 'category_id' => $data['category_id'], 'period' => $period],
            array_merge($data, [
                'user_id'    => $request->user()->id,
                'period'     => $period,
                'created_at' => now(),
                'updated_at' => now(),
            ])
        );

        return redirect()->route('budgets.index')->with('success', 'Bütçe kaydedildi.');
    }

    public function destroy(Request $request, int $id)
    {
        DB::table('budgets')->where('id', $id)->where('user_id', $request->user()->id)->delete();

        if ($request->wantsJson()) return response()->json(['success' => true]);
        return redirect()->route('budgets.index')->with('success', 'Bütçe silindi.');
    }
}
