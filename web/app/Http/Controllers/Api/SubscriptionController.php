<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\SubscriptionResource;
use App\Models\Subscription;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SubscriptionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $subscriptions = Subscription::with('category')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->orderBy('name')
            ->get();

        $totalMonthly = $subscriptions->sum(fn ($s) => $s->monthlyEquivalent());

        // Auto-detect recurring transactions not yet tracked as subscriptions
        $accountIds = DB::table('bank_connections')
            ->join('accounts', 'accounts.bank_connection_id', '=', 'bank_connections.id')
            ->where('bank_connections.user_id', $user->id)
            ->pluck('accounts.id');

        $candidates = Transaction::whereIn('account_id', $accountIds)
            ->where('is_recurring', true)
            ->where('amount', '<', 0)
            ->whereDoesntHave('account', fn ($q) => $q) // placeholder
            ->select('merchant_name', DB::raw('AVG(ABS(amount)) as avg_amount'), DB::raw('COUNT(*) as occurrences'))
            ->groupBy('merchant_name')
            ->having('occurrences', '>=', 2)
            ->whereNotNull('merchant_name')
            ->orderByDesc('occurrences')
            ->limit(10)
            ->get();

        return response()->json([
            'subscriptions'  => SubscriptionResource::collection($subscriptions),
            'total_monthly'  => round($totalMonthly, 2),
            'candidates'     => $candidates->map(fn ($c) => [
                'merchant_name' => $c->merchant_name,
                'avg_amount'    => round((float) $c->avg_amount, 2),
                'occurrences'   => $c->occurrences,
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'              => 'required|string|max:255',
            'merchant_name'     => 'nullable|string|max:255',
            'amount'            => 'required|numeric|min:0',
            'currency'          => 'nullable|string|max:3',
            'billing_cycle'     => 'required|in:weekly,monthly,quarterly,yearly',
            'next_billing_date' => 'nullable|date',
            'started_at'        => 'nullable|date',
            'category_id'       => 'nullable|integer|exists:categories,id',
        ]);

        $sub = Subscription::create([
            'user_id' => $request->user()->id,
            'status'  => 'active',
            'currency'=> $data['currency'] ?? 'TRY',
        ] + $data);

        $sub->load('category');

        return response()->json(['subscription' => new SubscriptionResource($sub)], 201);
    }

    public function update(Request $request, Subscription $subscription): JsonResponse
    {
        abort_if($subscription->user_id !== $request->user()->id, 403);

        $data = $request->validate([
            'name'              => 'sometimes|required|string|max:255',
            'amount'            => 'sometimes|required|numeric|min:0',
            'billing_cycle'     => 'sometimes|required|in:weekly,monthly,quarterly,yearly',
            'next_billing_date' => 'nullable|date',
            'category_id'       => 'nullable|integer|exists:categories,id',
        ]);

        $subscription->update($data);
        $subscription->load('category');

        return response()->json(['subscription' => new SubscriptionResource($subscription)]);
    }

    public function destroy(Request $request, Subscription $subscription): JsonResponse
    {
        abort_if($subscription->user_id !== $request->user()->id, 403);

        $subscription->update(['status' => 'cancelled', 'cancelled_at' => now()]);

        return response()->json(['message' => 'Abonelik iptal edildi.']);
    }
}
