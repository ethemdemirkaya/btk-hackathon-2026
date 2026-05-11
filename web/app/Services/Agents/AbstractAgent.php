<?php

namespace App\Services\Agents;

use App\Models\AgentRun;
use App\Models\User;
use App\Services\Gemini\GeminiClient;
use App\Services\Gemini\GeminiModelEnum;
use Illuminate\Support\Facades\DB;

abstract class AbstractAgent
{
    protected GeminiClient $gemini;
    protected User $user;
    protected ?AgentRun $run = null;

    public function __construct(User $user)
    {
        $this->user   = $user;
        $this->gemini = app(GeminiClient::class);
    }

    abstract public function getName(): string;
    abstract protected function getModel(): GeminiModelEnum;
    abstract protected function getSystemPrompt(): string;

    /**
     * Run the agent with the given input and return structured output.
     *
     * @param  array<string, mixed>  $input
     * @return array<string, mixed>
     */
    abstract public function run(array $input): array;

    protected function createRun(array $input, ?string $parentRunId = null): AgentRun
    {
        $this->run = AgentRun::create([
            'user_id'       => $this->user->id,
            'parent_run_id' => $parentRunId,
            'agent_name'    => $this->getName(),
            'status'        => 'pending',
            'input'         => $input,
        ]);

        return $this->run;
    }

    protected function generate(array $contents, array $schema = [], float $temperature = 0.7): array
    {
        $this->run?->markRunning();

        try {
            $result = $this->gemini->generate(
                $this->getModel(),
                $contents,
                $this->getSystemPrompt(),
                $schema,
                $temperature,
            );

            $this->run?->markCompleted(
                $result['content'],
                $result['tokens_in'],
                $result['tokens_out'],
                $result['model'],
            );

            return $result['content'];
        } catch (\Throwable $e) {
            $this->run?->markFailed($e->getMessage());
            throw $e;
        }
    }

    protected function buildUserMessage(string $text): array
    {
        return [['role' => 'user', 'parts' => [['text' => $text]]]];
    }

    /**
     * Load the most recent memory entries for this user and return them as
     * a formatted string to be prepended to a system prompt.
     */
    protected function loadMemories(int $limit = 10): string
    {
        $memories = DB::table('agent_memories')
            ->where('user_id', $this->user->id)
            ->orderByDesc('created_at')
            ->limit($limit)
            ->pluck('content')
            ->implode("\n");

        return $memories ? "Kullanıcı hakkında önceki bilgiler:\n" . $memories : '';
    }

    /**
     * Persist a memory entry for this user, skipping empty or duplicate content.
     */
    protected function saveMemory(string $content): void
    {
        if (empty(trim($content))) return;

        $exists = DB::table('agent_memories')
            ->where('user_id', $this->user->id)
            ->where('content', $content)
            ->exists();

        if (!$exists) {
            DB::table('agent_memories')->insert([
                'user_id'    => $this->user->id,
                'type'       => 'fact',
                'content'    => $content,
                'importance' => 5,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Build a system prompt that includes the agent's base system prompt
     * followed by any stored memories for the user.
     *
     * Agents that want memory support should call this method instead of
     * calling getSystemPrompt() directly.
     */
    protected function buildSystemPromptWithMemory(): string
    {
        $base    = $this->getSystemPrompt();
        $memories = $this->loadMemories();

        if (empty($memories)) {
            return $base;
        }

        return $base . "\n\n" . $memories;
    }
}
