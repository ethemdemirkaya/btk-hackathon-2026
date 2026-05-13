<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AgentInsight;
use App\Models\AgentMessage;
use App\Models\AgentRun;
use App\Services\Agents\Orchestrator\OrchestratorAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AgentChatController extends Controller
{
    public function __construct(private readonly OrchestratorAgent $orchestrator) {}

    public function send(Request $request): JsonResponse
    {
        $data = $request->validate([
            'message'    => 'required|string|max:2000',
            'session_id' => 'nullable|string|max:100',
        ]);

        $user      = $request->user();
        $sessionId = $data['session_id'] ?? 'mobile-' . $user->id . '-' . now()->format('Ymd');

        $run = AgentRun::create([
            'user_id'    => $user->id,
            'session_id' => $sessionId,
            'status'     => 'running',
            'started_at' => now(),
        ]);

        AgentMessage::create([
            'agent_run_id' => $run->id,
            'role'         => 'user',
            'content'      => $data['message'],
        ]);

        try {
            $response = $this->orchestrator->handle($user, $data['message'], $sessionId);

            AgentMessage::create([
                'agent_run_id' => $run->id,
                'role'         => 'assistant',
                'content'      => $response['reply'] ?? '',
                'metadata'     => json_encode(['agents_used' => $response['agents_used'] ?? []]),
            ]);

            $run->update([
                'status'     => 'completed',
                'ended_at'   => now(),
                'duration_ms'=> now()->diffInMilliseconds($run->started_at),
            ]);

            return response()->json([
                'reply'       => $response['reply'] ?? '',
                'agents_used' => $response['agents_used'] ?? [],
                'session_id'  => $sessionId,
                'run_id'      => $run->id,
            ]);
        } catch (\Throwable $e) {
            $run->update(['status' => 'failed', 'ended_at' => now()]);

            return response()->json([
                'error'   => 'Ajan yanıt veremedi.',
                'details' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    public function history(Request $request): JsonResponse
    {
        $user      = $request->user();
        $sessionId = $request->input('session_id');

        $query = AgentRun::with('messages')
            ->where('user_id', $user->id)
            ->orderByDesc('started_at');

        if ($sessionId) {
            $query->where('session_id', $sessionId);
        }

        $runs = $query->limit(20)->get()->map(fn ($run) => [
            'run_id'      => $run->id,
            'session_id'  => $run->session_id,
            'status'      => $run->status,
            'started_at'  => $run->started_at?->toIso8601String(),
            'messages'    => $run->messages->map(fn ($m) => [
                'role'    => $m->role,
                'content' => $m->content,
                'at'      => $m->created_at?->toIso8601String(),
            ]),
        ]);

        return response()->json(['runs' => $runs]);
    }

    public function insights(Request $request): JsonResponse
    {
        $insights = AgentInsight::where('user_id', $request->user()->id)
            ->where('is_dismissed', false)
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->orderByDesc('importance')
            ->orderByDesc('created_at')
            ->limit(10)
            ->get()
            ->map(fn ($i) => [
                'id'          => $i->id,
                'type'        => $i->type ?? 'info',
                'title'       => $i->title ?? '',
                'body'        => $i->body ?? '',
                'action_link' => $i->action_link,
                'importance'  => match(true) {
                    $i->importance >= 8 => 'critical',
                    $i->importance >= 6 => 'high',
                    $i->importance >= 4 => 'medium',
                    default             => 'low',
                },
                'created_at'  => $i->created_at?->toIso8601String(),
            ]);

        return response()->json(['insights' => $insights]);
    }

    public function dismissInsight(Request $request, AgentInsight $insight): JsonResponse
    {
        abort_if($insight->user_id !== $request->user()->id, 403);
        $insight->update(['is_dismissed' => true]);

        return response()->json(['message' => 'Öngörü kapatıldı.']);
    }
}
