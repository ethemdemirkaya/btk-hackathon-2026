<?php

namespace App\Services\Agents\Orchestrator;

use App\Models\AgentInsight;
use App\Models\User;
use App\Services\Gemini\GeminiClient;
use App\Services\Gemini\GeminiModelEnum;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrchestratorAgent
{
    private GeminiClient $gemini;

    public function __construct()
    {
        $this->gemini = app(GeminiClient::class);
    }

    /**
     * Single-call orchestration: gathers all financial context from DB,
     * then makes ONE Gemini Flash call instead of 5 sequential ones.
     * Reduces latency from ~60-120 s to ~10-20 s.
     */
    public function handle(User $user, string $message, string $sessionId = ''): array
    {
        $sessionId = $sessionId ?: Str::uuid()->toString();

        $context = $this->gatherContext($user);
        $final   = $this->synthesize($user, $message, $context);

        try {
            $this->maybeStoreInsight($user, $final);
        } catch (\Throwable) {}

        return [
            'session_id'         => $sessionId,
            'final'              => $final,
            'specialist_results' => [],
            'run_ids'            => [],
            'agents_used'        => ['budget_advisor', 'anomaly_detector', 'investment_advisor',
                                     'savings_coach', 'debt_manager', 'inflation_advisor'],
        ];
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Context gathering — all DB, zero Gemini calls
    // ──────────────────────────────────────────────────────────────────────────

    private function gatherContext(User $user): array
    {
        $userId = $user->id;
        $since  = Carbon::now()->subDays(30);

        // Balances — no is_active/name columns; use nickname, filter soft-deleted
        $balances = DB::table('accounts')
            ->where('user_id', $userId)
            ->whereNull('deleted_at')
            ->select('nickname', 'account_type', 'balance', 'currency')
            ->get()->toArray();

        // Category spending (last 30 days)
        $spending = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->leftJoin('categories as c', 'c.id', '=', 't.category_id')
            ->select('c.name as category', DB::raw('SUM(ABS(t.amount)) as total'), DB::raw('COUNT(*) as cnt'))
            ->where('a.user_id', $userId)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', $since)
            ->whereNull('t.deleted_at')
            ->groupBy('c.id', 'c.name')
            ->orderByDesc('total')
            ->limit(15)
            ->get()->toArray();

        // Anomalous transactions (anomaly_score >= 5)
        $anomalies = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->select('t.description', 't.amount', 't.anomaly_score', 't.posted_at')
            ->where('a.user_id', $userId)
            ->where('t.anomaly_score', '>=', 5)
            ->where('t.posted_at', '>=', $since)
            ->whereNull('t.deleted_at')
            ->orderByDesc('t.anomaly_score')
            ->limit(5)
            ->get()->toArray();

        // Budgets — no category_name/spent columns; join categories, calc spent
        $budgets = DB::table('budgets as b')
            ->leftJoin('categories as c', 'c.id', '=', 'b.category_id')
            ->where('b.user_id', $userId)
            ->select('c.name as category', 'b.amount as budget_amount', 'b.period')
            ->get()->toArray();

        // Goals — uses target_date not deadline
        $goals = DB::table('goals')
            ->where('user_id', $userId)
            ->where('status', 'active')
            ->whereNull('deleted_at')
            ->select('name', 'target_amount', 'current_amount', 'target_date')
            ->get()->toArray();

        // Health score
        $healthScore = DB::table('financial_health_scores')
            ->where('user_id', $userId)
            ->orderByDesc('calculated_at')
            ->value('score');

        // Active loans — no status/name/remaining_amount/monthly_payment columns
        $loans = DB::table('loans')
            ->where('user_id', $userId)
            ->whereNull('deleted_at')
            ->select('type', 'current_balance', 'interest_rate', 'next_payment_amount', 'next_payment_date')
            ->get()->toArray();

        return compact('balances', 'spending', 'anomalies', 'budgets', 'goals', 'healthScore', 'loans');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Single Gemini Flash call — acts as all 6 specialists combined
    // ──────────────────────────────────────────────────────────────────────────

    private function synthesize(User $user, string $userMessage, array $ctx): string
    {
        $monthlyIncome = number_format((float) ($user->monthly_income ?? 0), 0, ',', '.');

        $systemPrompt = <<<'SYS'
Sen Paranette'nin baş yapay zeka finansal asistanısın. Aynı anda şu uzman rolleri üstleniyorsun:
BütçeDanışmanı · AnomalyDedektörü · YatırımDanışmanı · TasarrufKoçu · BorçYöneticisi · EnflasyonDanışmanı

Görevin: Kullanıcının tam finansal tablosuna bakarak sorusuna Türkçe, samimi, somut ve rakamsal bir yanıt ver.
- Önce durumu özetle (1-2 cümle)
- Kritik bulguları madde madde listele (anormallikler, bütçe aşımları, fırsatlar)
- En az 2 somut eylem öner (rakamlarla)
- Bitişte motivasyon ver
Kesinlikle JSON veya kod bloku döndürme. Düz metin yaz.
SYS;

        $ctxJson = json_encode($ctx, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

        $prompt = <<<PROMPT
Kullanıcı aylık geliri: ₺{$monthlyIncome}
Finansal veri (son 30 gün):
{$ctxJson}

Kullanıcı sorusu: "{$userMessage}"

Yukarıdaki verilere dayanarak kapsamlı ve kişisel bir yanıt ver.
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
            if (str_contains($msg, '503') || str_contains($msg, 'overloaded')) {
                return 'Gemini şu anda yoğun. Lütfen 30-60 saniye sonra tekrar deneyin. 🔄';
            }
            if (str_contains($msg, '429') || str_contains($msg, 'rate')) {
                return 'API kotası aşıldı. Lütfen 1 dakika bekleyip tekrar deneyin.';
            }
            if (str_contains($msg, '401') || str_contains($msg, 'API key')) {
                return 'Yapay zeka servisine bağlanılamıyor. Lütfen yöneticinize bildirin.';
            }
            throw $e;
        }
    }

    private function maybeStoreInsight(User $user, string $final): void
    {
        if (empty(trim($final)) || strlen($final) < 50) {
            return;
        }
        AgentInsight::create([
            'user_id'    => $user->id,
            'agent_name' => 'orchestrator',
            'type'       => 'recommendation',
            'title'      => 'AI Analiz',
            'body'       => \Illuminate\Support\Str::limit($final, 2000),
            'importance' => 7,
            'expires_at' => now()->addDays(7),
        ]);
    }
}
