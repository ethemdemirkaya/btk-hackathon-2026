<?php

namespace App\Services\Gemini;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class GeminiClient
{
    private const BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

    private string $apiKey;

    public function __construct()
    {
        $this->apiKey = config('services.gemini.api_key', '');
    }

    /**
     * Single-shot content generation.
     * Returns parsed JSON body (as array) when responseSchema is set,
     * or raw text otherwise.
     *
     * @param  array<string, mixed>  $contents    Gemini contents array
     * @param  string|null           $systemPrompt
     * @param  array<string, mixed>  $schema       responseSchema for structured output
     * @param  float                 $temperature
     */
    public function generate(
        GeminiModelEnum $model,
        array $contents,
        ?string $systemPrompt = null,
        array $schema = [],
        float $temperature = 0.7,
    ): array {
        $body = [
            'contents'        => $contents,
            'generationConfig' => array_filter([
                'temperature'    => $temperature,
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
     * Each yielded value is a string delta.
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

        $url = self::BASE . "/{$model->value}:streamGenerateContent?alt=sse&key={$this->apiKey}";

        $response = Http::withHeaders(['Accept' => 'text/event-stream'])
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

    private function post(string $method, array $body): Response
    {
        if (! $this->apiKey) {
            throw new RuntimeException('GEMINI_API_KEY is not set.');
        }

        $url      = self::BASE . "/{$method}?key={$this->apiKey}";
        $response = Http::timeout(60)->retry(2, 1000)->post($url, $body);

        if (! $response->successful()) {
            throw new RuntimeException("Gemini API error {$response->status()}: {$response->body()}");
        }

        return $response;
    }

    private function parseResponse(Response $response, bool $jsonMode): array
    {
        $data     = $response->json();
        $text     = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        $usage    = $data['usageMetadata'] ?? [];

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
