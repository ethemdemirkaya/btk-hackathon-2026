<?php

namespace App\Http\Controllers;

use App\Models\NegotiationDraft;
use App\Services\Agents\Specialists\NegotiationAgent;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Throwable;

class NegotiationController extends Controller
{
    public function index(Request $request): View
    {
        $drafts = NegotiationDraft::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get();

        $targetLabels = NegotiationDraft::targetLabels();

        return view('negotiation.index', compact('drafts', 'targetLabels'));
    }

    public function generate(Request $request)
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
                'success'          => true,
                'draft'            => $draft,
                'key_arguments'    => $result['key_arguments'] ?? [],
                'success_tips'     => $result['success_tips'] ?? [],
                'estimated_chance' => $result['estimated_chance'] ?? null,
            ]);

        } catch (Throwable $e) {
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    }

    public function updateStatus(Request $request, NegotiationDraft $draft)
    {
        abort_if($draft->user_id !== $request->user()->id, 403);

        $request->validate(['status' => 'required|in:draft,sent,accepted,rejected']);
        $draft->update(['status' => $request->status]);

        return response()->json(['success' => true]);
    }

    public function destroy(Request $request, NegotiationDraft $draft)
    {
        abort_if($draft->user_id !== $request->user()->id, 403);
        $draft->delete();

        if ($request->wantsJson()) {
            return response()->json(['success' => true]);
        }

        return redirect()->route('negotiation.index')->with('success', 'Taslak silindi.');
    }
}
