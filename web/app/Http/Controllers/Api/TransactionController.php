<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'type'       => 'nullable|in:income,expense',
            'from'       => 'nullable|date',
            'to'         => 'nullable|date',
            'category'   => 'nullable|string',
            'per_page'   => 'nullable|integer|min:1|max:100',
        ]);

        $userId    = $request->user()->id;
        $accountIds = DB::table('bank_connections')
            ->join('accounts', 'accounts.bank_connection_id', '=', 'bank_connections.id')
            ->where('bank_connections.user_id', $userId)
            ->pluck('accounts.id');

        $query = Transaction::with('category')
            ->whereIn('account_id', $accountIds)
            ->orderByDesc('posted_at');

        if ($request->type === 'income') {
            $query->where('amount', '>=', 0);
        } elseif ($request->type === 'expense') {
            $query->where('amount', '<', 0);
        }

        if ($request->from) {
            $query->whereDate('posted_at', '>=', $request->from);
        }
        if ($request->to) {
            $query->whereDate('posted_at', '<=', $request->to);
        }

        $paginated = $query->paginate($request->input('per_page', 20));

        return response()->json([
            'data'       => TransactionResource::collection($paginated->items()),
            'pagination' => [
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
                'total'        => $paginated->total(),
            ],
        ]);
    }

    public function show(Request $request, Transaction $transaction): JsonResponse
    {
        $userId     = $request->user()->id;
        $ownsRecord = DB::table('bank_connections')
            ->join('accounts', 'accounts.bank_connection_id', '=', 'bank_connections.id')
            ->where('bank_connections.user_id', $userId)
            ->where('accounts.id', $transaction->account_id)
            ->exists();

        abort_unless($ownsRecord, 403);

        $transaction->load(['account.bankConnection.bank', 'category']);

        return response()->json(['transaction' => new TransactionResource($transaction)]);
    }
}
