<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\GoalResource;
use App\Models\Goal;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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

    public function update(Request $request, Goal $goal): JsonResponse
    {
        abort_if($goal->user_id !== $request->user()->id, 403);

        $data = $request->validate([
            'name'                 => 'required|string|max:255',
            'target_amount'        => 'required|numeric|min:1',
            'current_amount'       => 'nullable|numeric|min:0',
            'target_date'          => 'nullable|date',
            'monthly_contribution' => 'nullable|numeric|min:0',
        ]);

        $goal->update($data);

        return response()->json(['goal' => new GoalResource($goal)]);
    }

    public function destroy(Request $request, Goal $goal): JsonResponse
    {
        abort_if($goal->user_id !== $request->user()->id, 403);
        $goal->delete();

        return response()->json(['message' => 'Hedef silindi.']);
    }

    public function suggest(Request $request, Goal $goal): JsonResponse
    {
        abort_if($goal->user_id !== $request->user()->id, 403);

        $user = $request->user();

        $sub = DB::table('transactions as t2')
            ->join('accounts as a2', 'a2.id', '=', 't2.account_id')
            ->select(
                DB::raw("DATE_FORMAT(t2.posted_at, '%Y-%m') as month"),
                DB::raw('SUM(t2.amount) as net')
            )
            ->where('a2.user_id', $user->id)
            ->where('t2.posted_at', '>=', now()->subMonths(3))
            ->groupBy('month');

        $avgSavings = (float) DB::table($sub, 'monthly_sums')->avg('net') ?? 0;

        $remaining  = max(0, (float) $goal->target_amount - (float) $goal->current_amount);
        $monthsLeft = $goal->target_date
            ? max(1, (int) ceil(now()->diffInMonths(Carbon::parse($goal->target_date), false)))
            : 12;

        $suggested  = $remaining > 0 ? ceil($remaining / $monthsLeft) : 0;
        $affordable = $avgSavings > 0 ? min($suggested, $avgSavings * 0.4) : $suggested;
        $affordable = max(1, round($affordable, -2));

        // ── AI strategy advice ─────────────────────────────────────────────
        $aiAdvice    = null;
        $aiStrategy  = null;
        $aiRisks     = [];
        $aiQuickWins = [];
        try {
            $gemini  = app(\App\Services\Gemini\GeminiClient::class);
            $prompt  = <<<PROMPT
            Kullanıcının finansal hedefi:
            - Hedef adı: {$goal->name}
            - Hedef tutar: ₺{$goal->target_amount}
            - Mevcut birikim: ₺{$goal->current_amount}
            - Kalan tutar: ₺{$remaining}
            - Kalan ay sayısı: {$monthsLeft}
            - Ortalama aylık tasarruf: ₺{$avgSavings}
            - Önerilen aylık katkı: ₺{$suggested}
            - Karşılanabilir aylık katkı: ₺{$affordable}

            Bu hedefe ulaşmak için kişiselleştirilmiş strateji, riskler ve hızlı kazanımlar sun.
            PROMPT;

            $schema = [
                'type'       => 'object',
                'properties' => [
                    'advice'     => ['type' => 'string'],
                    'strategy'   => ['type' => 'string'],
                    'risks'      => ['type' => 'array', 'items' => ['type' => 'string']],
                    'quick_wins' => ['type' => 'array', 'items' => ['type' => 'string']],
                ],
                'required' => ['advice', 'strategy'],
            ];

            $result      = $gemini->generate(
                \App\Services\Gemini\GeminiModelEnum::FLASH,
                [['role' => 'user', 'parts' => [['text' => $prompt]]]],
                'Sen bir kişisel finans danışmanısın. Türkçe, somut ve uygulanabilir hedef stratejileri sun. Sadece JSON döndür.',
                $schema,
                0.7,
            );
            $aiAdvice    = $result['content']['advice']      ?? null;
            $aiStrategy  = $result['content']['strategy']    ?? null;
            $aiRisks     = $result['content']['risks']       ?? [];
            $aiQuickWins = $result['content']['quick_wins']  ?? [];
        } catch (\Throwable) {}

        return response()->json([
            'suggested'      => $suggested,
            'affordable'     => $affordable,
            'avg_savings'    => round($avgSavings, 0),
            'months_left'    => $monthsLeft,
            'remaining'      => $remaining,
            'ai_advice'      => $aiAdvice,
            'ai_strategy'    => $aiStrategy,
            'ai_risks'       => $aiRisks,
            'ai_quick_wins'  => $aiQuickWins,
        ]);
    }
}
