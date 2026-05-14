<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BudgetResource;
use App\Models\Budget;
use App\Services\Agents\Specialists\BudgetAdvisorAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Category;

class BudgetController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user   = $request->user();
        $period = $request->input('period', now()->format('Y-m'));

        $accountIds = DB::table('bank_connections')
            ->join('accounts', 'accounts.bank_connection_id', '=', 'bank_connections.id')
            ->where('bank_connections.user_id', $user->id)
            ->pluck('accounts.id');

        $budgets = Budget::with('category')
            ->where('user_id', $user->id)
            ->where('period', $period)
            ->get()
            ->map(function ($budget) use ($accountIds, $period) {
                $spent = DB::table('transactions')
                    ->join('categories', 'categories.id', '=', 'transactions.category_id')
                    ->whereIn('transactions.account_id', $accountIds)
                    ->where('categories.id', $budget->category_id)
                    ->whereRaw("DATE_FORMAT(transactions.posted_at, '%Y-%m') = ?", [$period])
                    ->where('transactions.amount', '<', 0)
                    ->sum(DB::raw('ABS(transactions.amount)'));

                $budget->spent = $spent;

                return $budget;
            });

        return response()->json([
            'period'  => $period,
            'budgets' => BudgetResource::collection($budgets),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_id'     => 'required|integer|exists:categories,id',
            'amount'          => 'required|numeric|min:0',
            'alert_threshold' => 'nullable|numeric|min:0|max:100',
            'period'          => 'nullable|string|regex:/^\d{4}-\d{2}$/',
        ]);

        $period = $data['period'] ?? now()->format('Y-m');

        $budget = Budget::updateOrCreate(
            [
                'user_id'     => $request->user()->id,
                'category_id' => $data['category_id'],
                'period'      => $period,
            ],
            [
                'amount'          => $data['amount'],
                'alert_threshold' => $data['alert_threshold'] ?? 80,
            ]
        );

        $budget->load('category');

        return response()->json(['budget' => new BudgetResource($budget)], 201);
    }

    public function destroy(Request $request, Budget $budget): JsonResponse
    {
        abort_if($budget->user_id !== $request->user()->id, 403);
        $budget->delete();

        return response()->json(['message' => 'Bütçe silindi.']);
    }

    public function aiSuggest(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $spending = DB::table('transactions as t')
            ->join('accounts as a', 't.account_id', '=', 'a.id')
            ->join('categories as c', 't.category_id', '=', 'c.id')
            ->where('a.user_id', $userId)
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
            ->where('user_id', $userId)
            ->where('period', now()->format('Y-m'))
            ->pluck('category_id')
            ->toArray();

        $suggestions = $spending
            ->filter(fn ($row) => ! in_array($row->category_id, $existingCategoryIds))
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

        // ── AI enrichment ──────────────────────────────────────────────────
        $aiSummary = null;
        try {
            $agent    = new BudgetAdvisorAgent($request->user());
            $aiResult = $agent->run([
                'context'    => 'Kullanıcı bütçe önerileri istiyor. Her kategori için somut TL limit ve gerekçe sun.',
                'session_id' => 'budget-suggest-' . $userId,
            ]);
            $aiSummary = $aiResult['summary'] ?? null;
            $aiRecs    = collect($aiResult['recommendations'] ?? [])
                ->keyBy(fn ($r) => mb_strtolower(trim($r['category'] ?? ''), 'UTF-8'));

            $suggestions = $suggestions->map(function ($s) use ($aiRecs) {
                $key = mb_strtolower(trim($s['category_name']), 'UTF-8');
                $ai  = $aiRecs->get($key)
                    ?? $aiRecs->first(fn ($r) =>
                        str_contains(mb_strtolower($r['category'] ?? '', 'UTF-8'), $key) ||
                        str_contains($key, mb_strtolower($r['category'] ?? '', 'UTF-8'))
                    );
                return array_merge((array) $s, [
                    'rationale' => $ai['suggestion'] ?? null,
                    'priority'  => $ai['priority']   ?? 'medium',
                ]);
            });
        } catch (\Throwable) {
            // Silent fallback – serve math-only suggestions
        }

        return response()->json([
            'suggestions' => $suggestions->values(),
            'ai_summary'  => $aiSummary,
        ]);
    }

    public function aiApply(Request $request): JsonResponse
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
            $exists = DB::table('budgets')
                ->where('user_id', $userId)
                ->where('category_id', (int) $item['category_id'])
                ->where('period', $period)
                ->exists();

            if ($exists) continue;

            DB::table('budgets')->insert([
                'user_id'         => $userId,
                'category_id'     => (int) $item['category_id'],
                'amount'          => (float) $item['amount'],
                'alert_threshold' => 80,
                'period'          => $period,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);
            $created++;
        }

        return response()->json([
            'created' => $created,
            'message' => $created > 0
                ? "{$created} bütçe kategorisi oluşturuldu."
                : 'Seçilen kategoriler için bu ay zaten bütçe mevcut.',
        ]);
    }
}
