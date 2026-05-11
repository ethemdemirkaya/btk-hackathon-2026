<?php

namespace App\Jobs;

use App\Models\AgentMessage;
use App\Models\User;
use App\Services\Agents\Orchestrator\OrchestratorAgent;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessAgentJob implements ShouldQueue
{
    use Queueable, InteractsWithQueue, SerializesModels;

    public int $timeout = 300;
    public int $tries   = 1;

    public function __construct(
        private readonly int    $userId,
        private readonly string $message,
        private readonly string $sessionId,
        private readonly int    $assistantMessageId,
    ) {}

    public function handle(): void
    {
        $assistantMsg = AgentMessage::find($this->assistantMessageId);
        if (! $assistantMsg) return;

        $user = User::find($this->userId);
        if (! $user) {
            $assistantMsg->update([
                'content'  => 'Kullanıcı bulunamadı.',
                'metadata' => ['status' => 'error'],
            ]);
            return;
        }

        try {
            $orchestrator = new OrchestratorAgent();
            $result       = $orchestrator->handle($user, $this->message, $this->sessionId);

            $assistantMsg->update([
                'content'  => $result['final'],
                'metadata' => [
                    'status'             => 'completed',
                    'agents_used'        => $result['agents_used'],
                    'specialist_results' => $result['specialist_results'],
                ],
            ]);
        } catch (\Throwable $e) {
            $errorMsg = 'Üzgünüm, şu anda yanıt üretemiyorum. Lütfen tekrar deneyin.';

            $assistantMsg->update([
                'content'  => $errorMsg,
                'metadata' => ['status' => 'error', 'error' => $e->getMessage()],
            ]);
        }
    }
}
