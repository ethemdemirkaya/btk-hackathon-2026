<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\GoalResource;
use App\Models\Goal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GoalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $goals = Goal::where('user_id', $request->user()->id)
            ->whereIn('status', ['active', 'completed'])
            ->orderBy('status')
            ->orderBy('target_date')
            ->get();

        return response()->json([
            'goals'         => GoalResource::collection($goals),
            'total_saved'   => (float) $goals->sum('current_amount'),
            'total_target'  => (float) $goals->sum('target_amount'),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'                 => 'required|string|max:255',
            'target_amount'        => 'required|numeric|min:1',
            'current_amount'       => 'nullable|numeric|min:0',
            'target_date'          => 'nullable|date|after:today',
            'monthly_contribution' => 'nullable|numeric|min:0',
        ]);

        $goal = Goal::create([
            'user_id' => $request->user()->id,
            'status'  => 'active',
        ] + $data);

        return response()->json(['goal' => new GoalResource($goal)], 201);
    }

    public function addFunds(Request $request, Goal $goal): JsonResponse
    {
        abort_if($goal->user_id !== $request->user()->id, 403);

        $data = $request->validate(['amount' => 'required|numeric|min:0.01']);

        $goal->current_amount = min(
            (float) $goal->target_amount,
            (float) $goal->current_amount + (float) $data['amount']
        );

        if ((float) $goal->current_amount >= (float) $goal->target_amount) {
            $goal->status = 'completed';
        }

        $goal->save();

        return response()->json(['goal' => new GoalResource($goal)]);
    }

    public function destroy(Request $request, Goal $goal): JsonResponse
    {
        abort_if($goal->user_id !== $request->user()->id, 403);
        $goal->delete();

        return response()->json(['message' => 'Hedef silindi.']);
    }
}
