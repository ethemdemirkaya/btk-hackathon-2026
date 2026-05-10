<?php

namespace App\Services\Agents;

use App\Models\AgentRun;
use App\Models\User;
use App\Services\Gemini\GeminiClient;
use App\Services\Gemini\GeminiModelEnum;

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
}
