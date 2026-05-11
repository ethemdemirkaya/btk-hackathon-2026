<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BillResource;
use App\Models\Bill;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BillController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $bills = Bill::where('user_id', $request->user()->id)
            ->orderBy('due_day')
            ->get();

        return response()->json([
            'bills'              => BillResource::collection($bills),
            'total_monthly_est'  => (float) $bills->sum('average_amount'),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'           => 'required|string|max:255',
            'type'           => 'required|string',
            'provider'       => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:100',
            'average_amount' => 'required|numeric|min:0',
            'due_day'        => 'nullable|integer|min:1|max:31',
            'is_autopay'     => 'boolean',
        ]);

        $bill = Bill::create(['user_id' => $request->user()->id] + $data);

        return response()->json(['bill' => new BillResource($bill)], 201);
    }

    public function update(Request $request, Bill $bill): JsonResponse
    {
        abort_if($bill->user_id !== $request->user()->id, 403);

        $data = $request->validate([
            'name'           => 'sometimes|string|max:255',
            'provider'       => 'sometimes|nullable|string|max:255',
            'account_number' => 'sometimes|nullable|string|max:100',
            'average_amount' => 'sometimes|numeric|min:0',
            'due_day'        => 'sometimes|nullable|integer|min:1|max:31',
            'is_autopay'     => 'sometimes|boolean',
        ]);

        $bill->update($data);

        return response()->json(['bill' => new BillResource($bill)]);
    }

    public function destroy(Request $request, Bill $bill): JsonResponse
    {
        abort_if($bill->user_id !== $request->user()->id, 403);
        $bill->delete();

        return response()->json(['message' => 'Fatura silindi.']);
    }
}
