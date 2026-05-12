<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NegotiationDraft;
use App\Services\Agents\Specialists\NegotiationAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class NegotiationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $drafts = NegotiationDraft::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($d) => [
                'id'             => $d->id,
                'target'         => $d->target,
                'target_label'   => $d->target_label,
                'recipient_name' => $d->recipient_name,
                'subject'        => $d->subject,
                'body'           => $d->body,
                'status'         => $d->status,
                'created_at'     => $d->created_at?->toIso8601String(),
            ]);

        return response()->json([
            'drafts'       => $drafts->values(),
            'target_types' => NegotiationDraft::targetLabels(),
        ]);
    }

    public function generate(Request $request): JsonResponse
    {
        $request->validate([
            'target'         => 'required|string|in:' . implode(',', array_keys(NegotiationDraft::targetLabels())),
            'recipient_name' => 'nullable|string|max:200',
            'extra_context'  => 'nullable|string|max:1000',
        ]);

        $user = $request->user();

        try {
            $agent  = new NegotiationAgent($user);
            $result = $agent->run([
                'target'         => $request->target,
                'recipient_name' => $request->recipient_name ?? 'İlgili Yetkili',
                'user_name'      => $user->name,
                'extra_context'  => $request->extra_context ?? '',
            ]);

            $draft = NegotiationDraft::create([
                'user_id'               => $user->id,
                'target'                => $request->target,
                'recipient_name'        => $request->recipient_name,
                'subject'               => $result['subject'] ?? 'Müzakere Talebi',
                'body'                  => $result['body'] ?? '',
                'status'                => 'draft',
                'generated_by_agent_id' => null,
            ]);

            return response()->json([
                'draft'            => $draft,
                'key_arguments'    => $result['key_arguments'] ?? [],
                'success_tips'     => $result['success_tips'] ?? [],
                'estimated_chance' => $result['estimated_chance'] ?? null,
            ], 201);

        } catch (Throwable $e) {
            return response()->json([
                'error'   => 'Mektup oluşturulamadı.',
                'details' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    public function updateStatus(Request $request, NegotiationDraft $draft): JsonResponse
    {
        abort_if($draft->user_id !== $request->user()->id, 403);
        $request->validate(['status' => 'required|in:draft,sent,accepted,rejected']);
        $draft->update(['status' => $request->status]);

        return response()->json(['message' => 'Durum güncellendi.', 'status' => $draft->status]);
    }

    public function destroy(Request $request, NegotiationDraft $draft): JsonResponse
    {
        abort_if($draft->user_id !== $request->user()->id, 403);
        $draft->delete();

        return response()->json(['message' => 'Taslak silindi.']);
    }
}
