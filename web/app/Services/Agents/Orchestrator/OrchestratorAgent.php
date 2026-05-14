<?php

namespace App\Services\Agents\Orchestrator;

use App\Models\AgentInsight;
use App\Models\AgentRun;
use App\Models\User;
use App\Services\Agents\Specialists\AnomalyDetectorAgent;
use App\Services\Agents\Specialists\BudgetAdvisorAgent;
use App\Services\Agents\Specialists\CriticAgent;
use App\Services\Agents\Specialists\DebtOptimizerAgent;
use App\Services\Agents\Specialists\ForecasterAgent;
use App\Services\Agents\Specialists\InflationAwareAgent;
use App\Services\Agents\Specialists\PurchasePlannerAgent;
use App\Services\Agents\Specialists\ReceiptOCRAgent;
use App\Services\Agents\Specialists\SubscriptionHunterAgent;
use App\Services\Agents\Specialists\TransactionClassifierAgent;
use App\Services\Gemini\GeminiClient;
use App\Services\Gemini\GeminiModelEnum;
use Illuminate\Support\Str;

class OrchestratorAgent
{
    private GeminiClient $gemini;
    private IntentRouter $router;

    public function __construct()
    {
        $this->gemini = app(GeminiClient::class);
        $this->router = new IntentRouter();
    }

    /**
     * Main entry point — routes intent, runs specialists in sequence,
     * then synthesizes a final answer with Gemini Pro.
     *
     * @return array{session_id: string, final: string, specialist_results: array, run_ids: array}
     */
    public function handle(User $user, string $message, string $sessionId = ''): array
    {
        $sessionId = $sessionId ?: Str::uuid()->toString();

        // ── 1. Route intent ────────────────────────────────────────────
        $routing = $this->router->route($message);
        $agents  = array_slice($routing['agents'], 0, 2); // cap at 2 to prevent timeouts
        $context = $routing['context'];
        $extracted = $routing['extracted'] ?? [];

        // ── 2. Run specialists ─────────────────────────────────────────
        $specialistResults = [];
        $runIds            = [];

        foreach ($agents as $agentName) {
            if ($agentName === 'critic') {
                continue; // critic runs after all others
            }
            try {
                $agent = $this->resolveSpecialist($user, $agentName);
                if (! $agent) {
                    continue;
                }

                $agentInput = array_merge(
                    ['context' => $context, 'session_id' => $sessionId],
                    $extracted,
                );

                $result = $agent->run($agentInput);
                $specialistResults[$agentName] = $result;
                $runIds[] = $agent->run instanceof AgentRun ? $agent->run->id : null;
            } catch (\Throwable $e) {
                $specialistResults[$agentName] = ['error' => $e->getMessage()];
            }
        }

        // ── 2b. Run CriticAgent if specialists produced results ────────
        if (! empty($specialistResults)) {
            try {
                $critic = new CriticAgent($user);
                $criticResult = $critic->run(array_merge(
                    ['context' => $context, 'session_id' => $sessionId, 'specialist_results' => $specialistResults],
                    $extracted,
                ));
                $specialistResults['critic'] = $criticResult;
            } catch (\Throwable $e) {
                $specialistResults['critic'] = ['error' => $e->getMessage()];
            }
        }

        // ── 3. Synthesize with Flash ───────────────────────────────────
        $final = $this->synthesize($user, $message, $specialistResults);

        // ── 4. Persist insight if there are budget/anomaly recommendations ────
        try {
            $this->maybeStoreInsight($user, $final, $specialistResults);
        } catch (\Throwable) {
            // Non-critical: insight storage failure must not kill the response
        }

        return [
            'session_id'         => $sessionId,
            'final'              => $final,
            'specialist_results' => $specialistResults,
            'run_ids'            => array_filter($runIds),
            'agents_used'        => $agents,
        ];
    }

    private function maybeStoreInsight(User $user, string $final, array $results): void
    {
        // Only store if budget or anomaly results are present
        $hasContent = isset($results['budget_advisor']) || isset($results['anomaly_detector']);
        if (! $hasContent || empty(trim($final))) return;

        $title = match (true) {
            isset($results['anomaly_detector']) => 'Anormallik Tespiti',
            isset($results['budget_advisor'])   => 'Bütçe Önerisi',
            default                             => 'AI Analiz',
        };

        $importance = isset($results['anomaly_detector']) ? 9 : 7;

        AgentInsight::create([
            'user_id'    => $user->id,
            'agent_name' => 'orchestrator',
            'type'       => 'recommendation',
            'title'      => $title,
            'body'       => \Illuminate\Support\Str::limit($final, 2000),
            'importance' => $importance,
            'expires_at' => now()->addDays(7),
        ]);
    }

    private function resolveSpecialist(User $user, string $name): ?object
    {
        return match ($name) {
            'purchase_planner'       => new PurchasePlannerAgent($user),
            'budget_advisor'         => new BudgetAdvisorAgent($user),
            'inflation_aware'        => new InflationAwareAgent($user),
            'anomaly_detector'       => new AnomalyDetectorAgent($user),
            'transaction_classifier' => new TransactionClassifierAgent($user),
            'forecaster'             => new ForecasterAgent($user),
            'debt_optimizer'         => new DebtOptimizerAgent($user),
            'subscription_hunter'    => new SubscriptionHunterAgent($user),
            'receipt_ocr'            => new ReceiptOCRAgent($user),
            default                  => null,
        };
    }

    private function synthesize(User $user, string $userMessage, array $specialistResults): string
    {
        $systemPrompt = <<<'SYS'
        Sen Paranette'nin baş finansal asistanısın. Uzman ajanlardan gelen analizleri
        birleştirip kullanıcıya açık, sıcak, somut ve güven veren bir Türkçe yanıt ver.
        Rakamları vurgula, eylem adımları öner. Mümkünse 3 alternatif sun.
        SYS;

        $specialistJson = json_encode($specialistResults, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        $monthlyIncome  = number_format((float) ($user->monthly_income ?? 0), 0, ',', '.');

        $prompt = <<<PROMPT
        Kullanıcı sorusu: "{$userMessage}"
        Kullanıcı aylık geliri: ₺{$monthlyIncome}

        Uzman ajan sonuçları:
        {$specialistJson}

        Yukarıdaki tüm analizleri kullanarak kullanıcıya kapsamlı bir yanıt ver.
        PROMPT;

        $contents = [['role' => 'user', 'parts' => [['text' => $prompt]]]];

        try {
            $result = $this->gemini->generate(
                GeminiModelEnum::FLASH,
                $contents,
                $systemPrompt,
                [],
                0.7,
            );
            return $result['text'];
        } catch (\Throwable $e) {
            $msg = $e->getMessage();
            if (str_contains($msg, '503') || str_contains($msg, 'high demand') || str_contains($msg, 'overloaded')) {
                return "Gemini şu anda yoğun talep nedeniyle geçici olarak yavaşladı. Uzman ajanlar analizleri tamamladı ancak sonuç birleştirilemiyor. Lütfen 30-60 saniye sonra tekrar deneyin. 🔄";
            }
            if (str_contains($msg, '429') || str_contains($msg, 'rate')) {
                return "API kotası aşıldı. Lütfen 1 dakika bekleyip tekrar deneyin.";
            }
            if (str_contains($msg, '401') || str_contains($msg, 'API key')) {
                return "Yapay zeka servisine bağlanılamıyor. Lütfen yöneticinize bildirin.";
            }
            return "Analiz tamamlandı ancak yanıt oluşturulurken beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.";
        }
    }
}
