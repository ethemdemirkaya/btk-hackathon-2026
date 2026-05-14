<?php

namespace App\Services\Gemini;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class GeminiClient
{
    private const BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

    /** @var string[] */
    private array $apiKeys;

    public function __construct()
    {
        $keys = config('services.gemini.api_keys', []);

        if (empty($keys)) {
            $single = config('services.gemini.api_key', '');
            $keys   = $single ? [$single] : [];
        }

        $this->apiKeys = array_values(array_filter($keys));
    }

    /**
     * Single-shot content generation.
     * Returns parsed JSON body (as array) when responseSchema is set,
     * or raw text otherwise.
     *
     * @param  array<string, mixed>  $contents
     * @param  array<string, mixed>  $schema    responseSchema for structured output
     */
    public function generate(
        GeminiModelEnum $model,
        array $contents,
        ?string $systemPrompt = null,
        array $schema = [],
        float $temperature = 0.7,
    ): array {
        $body = [
            'contents'         => $contents,
            'generationConfig' => array_filter([
                'temperature'      => $temperature,
                'responseMimeType' => $schema ? 'application/json' : null,
                'responseSchema'   => $schema ?: null,
            ]),
        ];

        if ($systemPrompt) {
            $body['systemInstruction'] = [
                'parts' => [['text' => $systemPrompt]],
            ];
        }

        $response = $this->post("{$model->value}:generateContent", $body);

        return $this->parseResponse($response, (bool) $schema);
    }

    /**
     * Returns a Generator that yields text chunks as they stream in.
     */
    public function stream(
        GeminiModelEnum $model,
        array $contents,
        ?string $systemPrompt = null,
        float $temperature = 0.7,
    ): \Generator {
        $body = [
            'contents'         => $contents,
            'generationConfig' => ['temperature' => $temperature],
        ];

        if ($systemPrompt) {
            $body['systemInstruction'] = ['parts' => [['text' => $systemPrompt]]];
        }

        $key = $this->pickKey();
        $url = self::BASE . "/{$model->value}:streamGenerateContent?alt=sse&key={$key}";

        $response = Http::withoutVerifying()
            ->withHeaders(['Accept' => 'text/event-stream'])
            ->timeout(120)
            ->post($url, $body);

        if (! $response->successful()) {
            throw new RuntimeException("Gemini stream error {$response->status()}: {$response->body()}");
        }

        foreach (explode("\n", $response->body()) as $line) {
            if (str_starts_with($line, 'data: ')) {
                $json = json_decode(substr($line, 6), true);
                $text = $json['candidates'][0]['content']['parts'][0]['text'] ?? '';
                if ($text !== '') {
                    yield $text;
                }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────

    /**
     * Picks the next available API key via round-robin, skipping keys that
     * are in a 60-second cooldown due to rate-limit errors.
     */
    private function pickKey(): string
    {
        if (empty($this->apiKeys)) {
            throw new RuntimeException('No GEMINI_API_KEY(S) configured.');
        }

        $count = count($this->apiKeys);

        // Round-robin counter stored in cache
        $idx = (int) Cache::get('gemini_key_idx', 0);

        for ($attempt = 0; $attempt < $count; $attempt++) {
            $key       = $this->apiKeys[$idx % $count];
            $cooldown  = Cache::get("gemini_key_cooldown_{$idx}");

            if (! $cooldown) {
                // Advance for next call
                Cache::put('gemini_key_idx', ($idx + 1) % $count, now()->addHour());
                return $key;
            }

            $idx = ($idx + 1) % $count;
        }

        // All keys on cooldown — use first key anyway
        Cache::put('gemini_key_idx', 1 % $count, now()->addHour());
        return $this->apiKeys[0];
    }

    private function cooldownKey(int $idx): void
    {
        Cache::put("gemini_key_cooldown_{$idx}", true, now()->addSeconds(60));
    }

    private function post(string $method, array $body): Response
    {
        if (empty($this->apiKeys)) {
            throw new RuntimeException('No GEMINI_API_KEY(S) configured.');
        }

        $count    = count($this->apiKeys);
        $startIdx = (int) Cache::get('gemini_key_idx', 0);

        for ($attempt = 0; $attempt < $count; $attempt++) {
            $idx = ($startIdx + $attempt) % $count;
            $key = $this->apiKeys[$idx];

            $url      = self::BASE . "/{$method}?key={$key}";
            $response = Http::withoutVerifying()->timeout(60)->post($url, $body);

            if ($response->status() === 429) {
                $this->cooldownKey($idx);
                continue;
            }

            if (! $response->successful()) {
                throw new RuntimeException("Gemini API error {$response->status()}: {$response->body()}");
            }

            // Success — advance the index for next call
            Cache::put('gemini_key_idx', ($idx + 1) % $count, now()->addHour());
            return $response;
        }

        throw new RuntimeException('All Gemini API keys are rate-limited. Retry in 60s.');
    }

    private function parseResponse(Response $response, bool $jsonMode): array
    {
        $data  = $response->json();
        $text  = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        $usage = $data['usageMetadata'] ?? [];

        $content = $jsonMode ? (json_decode($text, true) ?? []) : ['text' => $text];

        return [
            'content'    => $content,
            'text'       => $text,
            'tokens_in'  => (int) ($usage['promptTokenCount'] ?? 0),
            'tokens_out' => (int) ($usage['candidatesTokenCount'] ?? 0),
            'model'      => $data['modelVersion'] ?? '',
        ];
    }
}
