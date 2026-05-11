<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CardResource;
use App\Models\Card;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $connectionIds = DB::table('bank_connections')
            ->where('user_id', $request->user()->id)
            ->pluck('id');

        $cards = Card::whereIn('bank_connection_id', $connectionIds)
            ->get();

        $totalDebt  = $cards->sum('current_debt');
        $totalLimit = $cards->sum('credit_limit');

        return response()->json([
            'cards'       => CardResource::collection($cards),
            'total_debt'  => (float) $totalDebt,
            'total_limit' => (float) $totalLimit,
            'utilization' => $totalLimit > 0 ? round($totalDebt / $totalLimit * 100, 1) : 0,
        ]);
    }
}
