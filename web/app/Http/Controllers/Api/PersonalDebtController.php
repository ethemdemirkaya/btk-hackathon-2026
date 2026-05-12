<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PersonalDebtController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $debts = DB::table('personal_debts')
            ->where('user_id', $userId)
            ->orderBy('is_settled')
            ->orderByDesc('created_at')
            ->get();

        $givenActive    = (float) $debts->where('direction', 'given')->where('is_settled', false)->sum('amount');
        $receivedActive = (float) $debts->where('direction', 'received')->where('is_settled', false)->sum('amount');

        return response()->json([
            'debts' => $debts->values(),
            'stats' => [
                'given_active'    => $givenActive,
                'received_active' => $receivedActive,
                'net_position'    => $givenActive - $receivedActive,
                'settled_count'   => $debts->where('is_settled', true)->count(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'contact_name' => 'required|string|max:120',
            'amount'       => 'required|numeric|min:0.01',
            'direction'    => 'required|in:given,received',
            'note'         => 'nullable|string|max:500',
        ]);

        $id = DB::table('personal_debts')->insertGetId([
            'user_id'        => $request->user()->id,
            'transaction_id' => null,
            'contact_name'   => $data['contact_name'],
            'amount'         => $data['amount'],
            'direction'      => $data['direction'],
            'note'           => $data['note'] ?? null,
            'is_settled'     => false,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        $debt = DB::table('personal_debts')->where('id', $id)->first();

        return response()->json(['debt' => $debt], 201);
    }

    public function settle(Request $request, int $id): JsonResponse
    {
        $affected = DB::table('personal_debts')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->update(['is_settled' => true, 'settled_at' => now(), 'updated_at' => now()]);

        if (! $affected) {
            return response()->json(['message' => 'Borç bulunamadı.'], 404);
        }

        return response()->json(['message' => 'Borç kapatıldı.']);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $affected = DB::table('personal_debts')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->delete();

        if (! $affected) {
            return response()->json(['message' => 'Borç bulunamadı.'], 404);
        }

        return response()->json(['message' => 'Borç silindi.']);
    }
}
