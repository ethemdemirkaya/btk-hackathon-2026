<?php

namespace App\Http\Controllers;

use App\Models\AgentInsight;
use App\Models\AgentMessage;
use App\Models\AgentRun;
use App\Services\Agents\Orchestrator\OrchestratorAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AgentChatController extends Controller
{
    public function index(Request $request)
    {
        $user       = $request->user();
        $sessionId  = $request->query('session') ?: Str::uuid()->toString();

        $history = AgentMessage::where('user_id', $user->id)
            ->where('session_id', $sessionId)
            ->orderBy('created_at')
            ->get();

        $recentRuns = AgentRun::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        $insights = AgentInsight::where('user_id', $user->id)
            ->where('is_dismissed', false)
            ->orderByDesc('importance')
            ->limit(5)
            ->get();

        return view('agent-chat.index', compact('sessionId', 'history', 'recentRuns', 'insights'));
    }

    public function send(Request $request): JsonResponse
    {
        $request->validate(['message' => 'required|string|max:2000', 'session_id' => 'required|string']);

        $user      = $request->user();
        $message   = $request->input('message');
        $sessionId = $request->input('session_id');

        AgentMessage::create([
            'user_id'    => $user->id,
            'session_id' => $sessionId,
            'role'       => 'user',
            'content'    => $message,
        ]);

        try {
            $orchestrator = new OrchestratorAgent();
            $result       = $orchestrator->handle($user, $message, $sessionId);

            AgentMessage::create([
                'user_id'    => $user->id,
                'session_id' => $sessionId,
                'role'       => 'assistant',
                'content'    => $result['final'],
                'metadata'   => [
                    'agents_used'        => $result['agents_used'],
                    'specialist_results' => $result['specialist_results'],
                ],
            ]);

            return response()->json([
                'status'             => 'ok',
                'reply'              => $result['final'],
                'agents_used'        => $result['agents_used'],
                'specialist_results' => $result['specialist_results'],
            ]);
        } catch (\Throwable $e) {
            $errorMsg = config('app.debug')
                ? "Hata: {$e->getMessage()}"
                : "Üzgünüm, şu anda yanıt üretemiyorum. Lütfen tekrar deneyin.";

            AgentMessage::create([
                'user_id'    => $user->id,
                'session_id' => $sessionId,
                'role'       => 'assistant',
                'content'    => $errorMsg,
                'metadata'   => ['error' => $e->getMessage()],
            ]);

            return response()->json(['status' => 'error', 'reply' => $errorMsg], 200);
        }
    }

    public function history(Request $request): JsonResponse
    {
        $sessionId = $request->query('session_id');

        if (! $sessionId) {
            return response()->json(['messages' => []]);
        }

        $messages = AgentMessage::where('user_id', $request->user()->id)
            ->where('session_id', $sessionId)
            ->orderBy('created_at')
            ->get(['id', 'role', 'content', 'metadata', 'created_at']);

        return response()->json(['messages' => $messages]);
    }

    public function runs(Request $request): JsonResponse
    {
        $runs = AgentRun::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->limit(20)
            ->get(['id', 'agent_name', 'status', 'model_used', 'tokens_in', 'tokens_out', 'duration_ms', 'started_at']);

        return response()->json(['runs' => $runs]);
    }
}
