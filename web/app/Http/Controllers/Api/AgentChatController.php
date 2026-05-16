<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AgentInsight;
use App\Models\AgentMessage;
use App\Models\AgentRun;
use App\Services\Agents\Orchestrator\OrchestratorAgent;
use App\Services\Agents\Specialists\AnomalyDetectorAgent;
use App\Services\Agents\Specialists\BudgetAdvisorAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AgentChatController extends Controller
{
    public function __construct(private readonly OrchestratorAgent $orchestrator) {}

    public function send(Request $request): JsonResponse
    {
        set_time_limit(300);

        $data = $request->validate([
            'message'    => 'required|string|max:2000',
            'session_id' => 'nullable|string|max:100',
        ]);

        $user      = $request->user();
        $sessionId = $data['session_id'] ?? 'mobile-' . $user->id . '-' . now()->format('Ymd');

        // AgentRun: agent_name required (NOT NULL in schema), use 'finished_at'
        $run = AgentRun::create([
            'user_id'    => $user->id,
            'agent_name' => 'orchestrator',
            'status'     => 'running',
            'started_at' => now(),
        ]);

        // AgentMessage schema: user_id + session_id (no agent_run_id column)
        AgentMessage::create([
            'user_id'    => $user->id,
            'session_id' => $sessionId,
            'role'       => 'user',
            'content'    => $data['message'],
        ]);

        try {
            $response = $this->orchestrator->handle($user, $data['message'], $sessionId);

            AgentMessage::create([
                'user_id'    => $user->id,
                'session_id' => $sessionId,
                'role'       => 'assistant',
                'content'    => $response['final'] ?? '',
                'metadata'   => ['agents_used' => $response['agents_used'] ?? []],
            ]);

            $run->update([
                'status'      => 'completed',
                'finished_at' => now(),
                'duration_ms' => (int) abs($run->started_at->diffInMilliseconds(now())),
            ]);

            return response()->json([
                'reply'       => $response['final'] ?? '',
                'agents_used' => $response['agents_used'] ?? [],
                'session_id'  => $sessionId,
                'run_id'      => $run->id,
            ]);
        } catch (\Throwable $e) {
            // Sync attributes so Eloquent doesn't re-send any dirty values from a
            // previously failed update() attempt (e.g. negative duration_ms).
            $run->syncOriginal();
            $run->update(['status' => 'failed', 'finished_at' => now()]);

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

        $query = AgentMessage::where('user_id', $user->id)
            ->orderBy('created_at');

        if ($sessionId) {
            $query->where('session_id', $sessionId);
        }

        $messages = $query->limit(200)->get()->map(fn ($m) => [
            'role'    => $m->role,
            'content' => $m->content,
            'at'      => $m->created_at?->toIso8601String(),
        ]);

        return response()->json([
            'runs' => [[
                'session_id' => $sessionId,
                'status'     => 'completed',
                'messages'   => $messages,
            ]],
        ]);
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

    public function refreshInsights(Request $request): JsonResponse
    {
        $user  = $request->user();
        $force = $request->boolean('force', false);

        $freshExists = AgentInsight::where('user_id', $user->id)
            ->where('is_dismissed', false)
            ->where('created_at', '>=', now()->subDay())
            ->exists();

        if ($freshExists && ! $force) {
            return $this->insights($request);
        }

        $context = 'Finansal verilerimi analiz et, bütçe durumumu ve olağandışı harcamaları değerlendir.';
        $input   = ['context' => $context];

        try {
            $budget  = (new BudgetAdvisorAgent($user))->run($input);
            $summary = $budget['summary'] ?? null;
            if ($summary) {
                AgentInsight::create([
                    'user_id'    => $user->id,
                    'agent_name' => 'budget_advisor',
                    'type'       => 'tip',
                    'title'      => 'Bütçe Analizi',
                    'body'       => Str::limit($summary, 2000),
                    'importance' => 7,
                    'expires_at' => now()->addDays(7),
                ]);
            }
            foreach (($budget['recommendations'] ?? []) as $rec) {
                $suggestion = $rec['suggestion'] ?? null;
                if (! $suggestion) continue;
                $priority = match (strtolower($rec['priority'] ?? 'medium')) {
                    'high', 'yüksek' => 8,
                    'medium', 'orta' => 6,
                    'low', 'düşük'   => 4,
                    default          => 5,
                };
                AgentInsight::create([
                    'user_id'    => $user->id,
                    'agent_name' => 'budget_advisor',
                    'type'       => 'tip',
                    'title'      => ($rec['category'] ?? 'Bütçe') . ' Önerisi',
                    'body'       => Str::limit($suggestion, 2000),
                    'importance' => $priority,
                    'expires_at' => now()->addDays(7),
                ]);
            }
        } catch (\Throwable) {}

        try {
            $anomaly = (new AnomalyDetectorAgent($user))->run($input);
            $summary = $anomaly['summary'] ?? null;
            if ($summary) {
                AgentInsight::create([
                    'user_id'    => $user->id,
                    'agent_name' => 'anomaly_detector',
                    'type'       => 'warning',
                    'title'      => 'Harcama Anomalisi',
                    'body'       => Str::limit($summary, 2000),
                    'importance' => 9,
                    'expires_at' => now()->addDays(3),
                ]);
            }
        } catch (\Throwable) {}

        return $this->insights($request);
    }

    public function pageAnalyze(Request $request): JsonResponse
    {
        $data = $request->validate([
            'page'    => 'required|string|max:100',
            'context' => 'nullable|array',
        ]);

        $user = $request->user();

        try {
            $response = $this->orchestrator->handle(
                $user,
                'Şu an ' . $data['page'] . ' sayfasındayım. Bu sayfayla ilgili bana kısa ve öz bir finansal öneri ver.',
                'page-analyze-' . $user->id,
            );

            return response()->json(['insight' => $response['final'] ?? '']);
        } catch (\Throwable $e) {
            return response()->json([
                'error'   => 'Sayfa analizi yapılamadı.',
                'details' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }
}
