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

    public function aiSuggest(Request $request)
    {
        $spending = DB::table('transactions as t')
            ->join('accounts as a', 't.account_id', '=', 'a.id')
            ->join('categories as c', 't.category_id', '=', 'c.id')
            ->where('a.user_id', auth()->id())
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subMonths(3))
            ->groupBy('c.id', 'c.name', 'c.slug')
            ->select(
                'c.id as category_id',
                'c.name as category_name',
                'c.slug',
                DB::raw('ABS(SUM(t.amount)) / 3 as monthly_avg')
            )
            ->orderByDesc('monthly_avg')
            ->get();

        if ($spending->isEmpty()) {
            return response()->json(['error' => 'Son 3 ayda harcama verisi bulunamadı.'], 422);
        }

        $existingCategoryIds = DB::table('budgets')
            ->where('user_id', auth()->id())
            ->where('period', now()->format('Y-m'))
            ->pluck('category_id')
            ->toArray();

        $suggestions = $spending
            ->filter(fn($row) => ! in_array($row->category_id, $existingCategoryIds))
            ->values()
            ->map(function ($row) {
                $raw       = (float) $row->monthly_avg * 1.05;
                $suggested = round($raw / 50) * 50;
                if ($suggested < 50) $suggested = 50;

                return [
                    'category_id'   => $row->category_id,
                    'category_name' => $row->category_name,
                    'monthly_avg'   => round($row->monthly_avg, 2),
                    'suggested'     => (int) $suggested,
                ];
            });

        return response()->json(['suggestions' => $suggestions]);
    }

    public function aiApply(Request $request)
    {
        $data = $request->validate([
            'suggestions'               => 'required|array|min:1',
            'suggestions.*.category_id' => 'required|integer|exists:categories,id',
            'suggestions.*.amount'      => 'required|numeric|min:1',
        ]);

        $period  = now()->format('Y-m');
        $userId  = $request->user()->id;
        $created = 0;

        foreach ($data['suggestions'] as $item) {
            $categoryId = (int) $item['category_id'];
            $amount     = (float) $item['amount'];

            // Skip if budget already exists for this category this month
            $exists = DB::table('budgets')
                ->where('user_id', $userId)
                ->where('category_id', $categoryId)
                ->where('period', $period)
                ->exists();

            if ($exists) continue;

            DB::table('budgets')->insert([
                'user_id'         => $userId,
                'category_id'     => $categoryId,
                'amount'          => $amount,
                'alert_threshold' => 80,
                'period'          => $period,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);
            $created++;
        }

        $message = $created > 0
            ? "AI önerisi ile {$created} bütçe kategorisi oluşturuldu."
            : 'Seçilen kategoriler için bu ay zaten bütçe mevcut.';

        if ($request->wantsJson() || $request->ajax()) {
            return response()->json(['status' => 'ok', 'message' => $message, 'created' => $created]);
        }

        return redirect()->route('budgets.index')->with('success', $message);
    }
}
