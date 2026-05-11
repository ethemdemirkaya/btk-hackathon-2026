<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BudgetResource;
use App\Models\Budget;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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
}
