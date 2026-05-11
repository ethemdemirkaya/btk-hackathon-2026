<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LoanResource;
use App\Models\Loan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LoanController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $loans = Loan::with('bankConnection.bank')
            ->where('user_id', $request->user()->id)
            ->orderBy('next_payment_date')
            ->get();

        $totalBalance    = $loans->sum('current_balance');
        $nextPaymentSum  = $loans->where('next_payment_date', '!=', null)
            ->whereBetween('next_payment_date', [now()->toDateString(), now()->addDays(30)->toDateString()])
            ->sum('next_payment_amount');

        return response()->json([
            'loans'              => LoanResource::collection($loans),
            'total_balance'      => (float) $totalBalance,
            'due_next_30_days'   => (float) $nextPaymentSum,
        ]);
    }
}
