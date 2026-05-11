<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessAgentJob;
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
        $user      = $request->user();
        $sessionId = $request->query('session') ?: Str::uuid()->toString();

        $history = AgentMessage::where('user_id', $user->id)
            ->where('session_id', $sessionId)
            ->orderBy('created_at')
            ->get();

        $recentRuns = AgentRun::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        // Filter out error-content insights
        $insights = AgentInsight::where('user_id', $user->id)
            ->where('is_dismissed', false)
            ->where(function ($q) {
                $q->whereNull('body')
                  ->orWhere(function ($q2) {
                      $q2->where('body', 'not like', '%hata oluştu%')
                         ->where('body', 'not like', '%rate-limited%')
                         ->where('body', 'not like', '%API error%')
                         ->where('body', 'not like', '%503%')
                         ->where('body', 'not like', '%değerli kullanıcım%')
                         ->where('body', 'not like', '%baş finansal asistan%');
                  });
            })
            ->orderByDesc('importance')
            ->limit(5)
            ->get();

        return view('agent-chat.index', compact('sessionId', 'history', 'recentRuns', 'insights'));
    }

    /**
     * Immediately creates a pending assistant message, dispatches a queue job,
     * and returns {status: 'pending', message_id} so the browser is unblocked.
     */
    public function send(Request $request): JsonResponse
    {
        $request->validate([
            'message'    => 'required|string|max:2000',
            'session_id' => 'required|string',
        ]);

        $user      = $request->user();
        $message   = $request->input('message');
        $sessionId = $request->input('session_id');

        // Release session file lock immediately — lets the user navigate while job runs
        session()->save();

        // Save user message
        AgentMessage::create([
            'user_id'    => $user->id,
            'session_id' => $sessionId,
            'role'       => 'user',
            'content'    => $message,
            'metadata'   => ['status' => 'completed'],
        ]);

        // Create placeholder assistant message in pending state
        $assistantMsg = AgentMessage::create([
            'user_id'    => $user->id,
            'session_id' => $sessionId,
            'role'       => 'assistant',
            'content'    => '',
            'metadata'   => ['status' => 'pending'],
        ]);

        // Dispatch to queue — returns immediately, job runs in background
        ProcessAgentJob::dispatch($user->id, $message, $sessionId, $assistantMsg->id);

        return response()->json([
            'status'     => 'pending',
            'message_id' => $assistantMsg->id,
        ]);
    }

    /**
     * Poll endpoint: returns status + content of an assistant message.
     */
    public function poll(Request $request, int $messageId): JsonResponse
    {
        $msg = AgentMessage::where('id', $messageId)
            ->where('user_id', $request->user()->id)
            ->first();

        if (! $msg) {
            return response()->json(['status' => 'not_found'], 404);
        }

        $status = $msg->metadata['status'] ?? 'pending';

        if ($status === 'pending') {
            return response()->json(['status' => 'pending']);
        }

        return response()->json([
            'status'      => $status,
            'reply'       => $msg->content,
            'agents_used' => $msg->metadata['agents_used'] ?? [],
        ]);
    }

    public function dismissInsight(Request $request, AgentInsight $insight): JsonResponse
    {
        abort_unless($insight->user_id === $request->user()->id, 403);
        $insight->update(['is_dismissed' => true]);
        return response()->json(['status' => 'ok']);
    }

    /** Quick-analyze: run budget + anomaly agents as a queued job */
    public function quickAnalyze(Request $request): JsonResponse
    {
        $user      = $request->user();
        $sessionId = 'quick-analysis-' . $user->id;

        session()->save();

        $assistantMsg = AgentMessage::create([
            'user_id'    => $user->id,
            'session_id' => $sessionId,
            'role'       => 'assistant',
            'content'    => '',
            'metadata'   => ['status' => 'pending'],
        ]);

        ProcessAgentJob::dispatch(
            $user->id,
            'Son harcamalarımı analiz et ve bütçe önerileri sun. Anormal harcama var mı?',
            $sessionId,
            $assistantMsg->id,
        );

        return response()->json(['status' => 'ok', 'message' => 'Analiz kuyruğa alındı.']);
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
