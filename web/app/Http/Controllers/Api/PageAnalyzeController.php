<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Agents\Specialists\AnomalyDetectorAgent;
use App\Services\Agents\Specialists\BudgetAdvisorAgent;
use App\Services\Agents\Specialists\DebtOptimizerAgent;
use App\Services\Agents\Specialists\ForecasterAgent;
use App\Services\Agents\Specialists\InflationAwareAgent;
use App\Services\Agents\Specialists\SubscriptionHunterAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PageAnalyzeController extends Controller
{
    /**
     * Run the appropriate specialist agent(s) for the given page and return
     * structured insight cards ready for the x-ai-insight-panel component.
     */
    public function analyze(Request $request): JsonResponse
    {
        $request->validate([
            'page'  => ['required', 'string', 'in:budgets,transactions,loans,goals,investments,subscriptions,inflation,fx_alerts,dashboard'],
            'limit' => ['sometimes', 'integer', 'min:1', 'max:10'],
        ]);

        $user  = Auth::user();
        $page  = $request->input('page');
        $limit = (int) $request->input('limit', 3);

        try {
            $insights  = [];
            $agentName = 'unknown';

            match ($page) {
                'budgets' => [
                    $insights  = $this->runBudgetAdvisor($user),
                    $agentName = 'budget_advisor',
                ],
                'transactions' => [
                    $insights  = $this->runAnomalyDetector($user),
                    $agentName = 'anomaly_detector',
                ],
                'loans' => [
                    $insights  = $this->runDebtOptimizer($user),
                    $agentName = 'debt_optimizer',
                ],
                'goals' => [
                    $insights  = $this->runForecaster($user, 'goals'),
                    $agentName = 'forecaster',
                ],
                'investments' => [
                    $insights  = $this->runForecaster($user, 'investments'),
                    $agentName = 'forecaster',
                ],
                'subscriptions' => [
                    $insights  = $this->runSubscriptionHunter($user),
                    $agentName = 'subscription_hunter',
                ],
                'inflation' => [
                    $insights  = $this->runInflationAware($user, 'inflation'),
                    $agentName = 'inflation_aware',
                ],
                'fx_alerts' => [
                    $insights  = $this->runInflationAware($user, 'fx_alerts'),
                    $agentName = 'inflation_aware',
                ],
                'dashboard' => [
                    $insights  = $this->runDashboard($user),
                    $agentName = 'orchestrator',
                ],
            };

            // Clamp to requested limit
            $insights = array_slice($insights, 0, $limit);

            // Always return at least one entry so the panel never shows empty on success
            if (empty($insights)) {
                $insights = [$this->genericAnalyzing()];
            }

        } catch (\Throwable $e) {
            \Log::warning('PageAnalyzeController: agent failed', [
                'page'  => $page,
                'error' => $e->getMessage(),
            ]);

            $insights  = [$this->unavailableInsight()];
            $agentName = 'unknown';
        }

        return response()->json([
            'insights'     => $insights,
            'agent'        => $agentName,
            'generated_at' => now()->toIso8601String(),
        ]);
    }

    // ── BudgetAdvisorAgent ────────────────────────────────────────────────────

    private function runBudgetAdvisor($user): array
    {
        $agent  = new BudgetAdvisorAgent($user);
        $result = $agent->run(['context' => 'Bütçe sayfası analizi']);

        $insights = [];

        foreach ($result['recommendations'] ?? [] as $rec) {
            $category   = $rec['category']   ?? 'Genel';
            $suggestion = $rec['suggestion'] ?? ($rec['reason'] ?? '');
            $priority   = strtolower($rec['priority'] ?? 'medium');
            $savingTl   = $rec['saving_tl']  ?? null;

            $type       = match ($priority) {
                'high', 'yüksek'  => 'warning',
                'critical'        => 'alert',
                'low', 'düşük'    => 'info',
                default           => 'tip',
            };
            $importance = match ($priority) {
                'critical'        => 'critical',
                'high', 'yüksek'  => 'high',
                'low', 'düşük'    => 'low',
                default           => 'medium',
            };

            $body = $suggestion;
            if ($savingTl !== null && $savingTl > 0) {
                $body .= ' (Tahmini tasarruf: ₺' . number_format($savingTl, 0, ',', '.') . '/ay)';
            }

            $insights[] = [
                'type'       => $type,
                'title'      => $category . ' Bütçesi',
                'body'       => $body,
                'importance' => $importance,
                'action'     => ['label' => 'Bütçeleri Yönet', 'url' => '/budgets'],
            ];
        }

        // Prepend a summary card if present
        if (!empty($result['summary']) && count($insights) > 0) {
            array_unshift($insights, [
                'type'       => 'info',
                'title'      => 'Bütçe Özeti',
                'body'       => $result['summary'],
                'importance' => 'medium',
                'action'     => ['label' => 'Bütçeleri Gör', 'url' => '/budgets'],
            ]);
        }

        return $insights ?: [$this->genericAnalyzing()];
    }

    // ── AnomalyDetectorAgent ──────────────────────────────────────────────────

    private function runAnomalyDetector($user): array
    {
        $agent  = new AnomalyDetectorAgent($user);
        $result = $agent->run(['days' => 30]);

        $insights = [];

        foreach ($result['anomalies'] ?? [] as $anomaly) {
            $score  = (float) ($anomaly['score'] ?? 0);
            $reason = $anomaly['reason'] ?? '';
            $txId   = $anomaly['transaction_id'] ?? null;
            $type   = $anomaly['type'] ?? 'anomaly';

            $insightType = $score >= 80 ? 'alert' : ($score >= 50 ? 'warning' : 'info');
            $importance  = $score >= 80 ? 'high'  : ($score >= 50 ? 'medium'  : 'low');

            $entry = [
                'type'       => $insightType,
                'title'      => 'Olağandışı İşlem: ' . ucfirst($type),
                'body'       => $reason,
                'importance' => $importance,
            ];

            if ($txId) {
                $entry['action'] = ['label' => 'İşlemlere Git', 'url' => '/transactions'];
            }

            $insights[] = $entry;
        }

        if (!empty($result['summary'])) {
            array_unshift($insights, [
                'type'       => 'info',
                'title'      => 'Anomali Özeti',
                'body'       => $result['summary'],
                'importance' => 'medium',
                'action'     => ['label' => 'Tüm İşlemler', 'url' => '/transactions'],
            ]);
        }

        return $insights ?: [$this->genericAnalyzing()];
    }

    // ── DebtOptimizerAgent ────────────────────────────────────────────────────

    private function runDebtOptimizer($user): array
    {
        $agent  = new DebtOptimizerAgent($user);
        $result = $agent->run(['context' => 'Kredi/borç sayfası analizi']);

        $insights = [];

        // Quick wins first
        foreach ($result['quick_wins'] ?? [] as $win) {
            $insights[] = [
                'type'       => 'tip',
                'title'      => 'Hızlı Kazanım',
                'body'       => $win,
                'importance' => 'high',
                'action'     => ['label' => 'Kredileri Gör', 'url' => '/loans'],
            ];
        }

        // Strategies
        foreach ($result['strategies'] ?? [] as $strategy) {
            $insights[] = [
                'type'       => 'tip',
                'title'      => $strategy['name'] ?? 'Strateji',
                'body'       => ($strategy['description'] ?? '') . (isset($strategy['first_step']) ? ' İlk adım: ' . $strategy['first_step'] : ''),
                'importance' => 'medium',
                'action'     => ['label' => 'Borçları Yönet', 'url' => '/loans'],
            ];
        }

        // Debt summary
        if (!empty($result['debt_summary'])) {
            $ds        = $result['debt_summary'];
            $riskLevel = strtolower($ds['risk_level'] ?? 'medium');
            $insights[] = [
                'type'       => $riskLevel === 'high' ? 'warning' : ($riskLevel === 'low' ? 'success' : 'info'),
                'title'      => 'Borç Durum Özeti',
                'body'       => 'Toplam borç: ₺' . number_format((float) ($ds['total_debt'] ?? 0), 0, ',', '.') . ' | Borç/Gelir oranı: ' . ($ds['debt_to_income_ratio'] ?? '—') . ' | Risk: ' . ($ds['risk_level'] ?? '—'),
                'importance' => $riskLevel === 'high' ? 'high' : 'medium',
                'action'     => ['label' => 'Kredileri Gör', 'url' => '/loans'],
            ];
        }

        return $insights ?: [$this->genericAnalyzing()];
    }

    // ── ForecasterAgent ───────────────────────────────────────────────────────

    private function runForecaster($user, string $context): array
    {
        $contextStr = $context === 'investments'
            ? 'Yatırım portföyü analizi ve projeksiyon'
            : 'Tasarruf hedefleri ve finansal projeksiyon';

        $agent  = new ForecasterAgent($user);
        $result = $agent->run(['months' => 6, 'context' => $contextStr]);

        $insights = [];

        // Outlook
        if (!empty($result['outlook'])) {
            $insights[] = [
                'type'       => 'info',
                'title'      => '6 Aylık Finansal Görünüm',
                'body'       => $result['outlook'],
                'importance' => 'high',
                'action'     => ['label' => $context === 'investments' ? 'Yatırımlarım' : 'Hedeflerim', 'url' => '/' . ($context === 'investments' ? 'investments' : 'goals')],
            ];
        }

        // Purchasing power loss
        if (!empty($result['purchasing_power_loss'])) {
            $insights[] = [
                'type'       => 'warning',
                'title'      => 'Satın Alma Gücü Kaybı',
                'body'       => $result['purchasing_power_loss'],
                'importance' => 'medium',
            ];
        }

        // Savings recommendations
        foreach ($result['savings_recommendations'] ?? [] as $rec) {
            $insights[] = [
                'type'       => 'tip',
                'title'      => 'Tasarruf Önerisi',
                'body'       => $rec,
                'importance' => 'medium',
                'action'     => ['label' => 'Hedeflerimi Yönet', 'url' => '/goals'],
            ];
        }

        // Risk assessment
        if (!empty($result['risk_assessment'])) {
            $insights[] = [
                'type'       => 'info',
                'title'      => 'Risk Değerlendirmesi',
                'body'       => $result['risk_assessment'],
                'importance' => 'low',
            ];
        }

        return $insights ?: [$this->genericAnalyzing()];
    }

    // ── SubscriptionHunterAgent ───────────────────────────────────────────────

    private function runSubscriptionHunter($user): array
    {
        $agent  = new SubscriptionHunterAgent($user);
        $result = $agent->run(['context' => 'Abonelik analizi ve optimizasyon']);

        $insights = [];

        // Price increase alerts
        foreach ($result['price_increase_alerts'] ?? [] as $alert) {
            $insights[] = [
                'type'       => 'warning',
                'title'      => 'Fiyat Artışı Tespit Edildi',
                'body'       => $alert,
                'importance' => 'high',
                'action'     => ['label' => 'Abonelikleri Yönet', 'url' => '/subscriptions'],
            ];
        }

        // Cancellation candidates
        foreach ($result['cancellation_candidates'] ?? [] as $candidate) {
            $insights[] = [
                'type'       => 'tip',
                'title'      => 'İptal Adayı',
                'body'       => $candidate,
                'importance' => 'medium',
                'action'     => ['label' => 'Abonelikleri Gör', 'url' => '/subscriptions'],
            ];
        }

        // Income percentage warning
        if (!empty($result['income_percentage'])) {
            $insights[] = [
                'type'       => 'info',
                'title'      => 'Abonelik Yükü',
                'body'       => 'Aylık ₺' . number_format((float) ($result['total_monthly_burden'] ?? 0), 0, ',', '.') . ' abonelik harcaman gelirinizin ' . $result['income_percentage'] . '\'ini oluşturuyor.',
                'importance' => 'medium',
                'action'     => ['label' => 'Abonelikleri Yönet', 'url' => '/subscriptions'],
            ];
        }

        // Summary
        if (!empty($result['summary'])) {
            array_unshift($insights, [
                'type'       => 'info',
                'title'      => 'Abonelik Analizi Özeti',
                'body'       => $result['summary'],
                'importance' => 'medium',
                'action'     => ['label' => 'Aboneliklerim', 'url' => '/subscriptions'],
            ]);
        }

        return $insights ?: [$this->genericAnalyzing()];
    }

    // ── InflationAwareAgent ───────────────────────────────────────────────────

    private function runInflationAware($user, string $context): array
    {
        $contextStr = $context === 'fx_alerts'
            ? 'Kur hareketleri ve enflasyonun döviz/altın yatırımlarına etkisi'
            : 'Kişisel enflasyon profili ve harcama alışkanlıkları';

        $agent  = new InflationAwareAgent($user);
        $result = $agent->run(['context' => $contextStr, 'months' => 12, 'target_amount' => 0]);

        $insights = [];

        // Key insights
        foreach ($result['key_insights'] ?? [] as $insight) {
            $insights[] = [
                'type'       => 'info',
                'title'      => 'Enflasyon İçgörüsü',
                'body'       => $insight,
                'importance' => 'medium',
                'action'     => ['label' => 'Enflasyon Sayfası', 'url' => '/inflation'],
            ];
        }

        // Real value impact
        if (!empty($result['real_value_impact'])) {
            $insights[] = [
                'type'       => 'warning',
                'title'      => 'Reel Değer Etkisi',
                'body'       => $result['real_value_impact'],
                'importance' => 'high',
            ];
        }

        // Recommendation
        if (!empty($result['recommendation'])) {
            $insights[] = [
                'type'       => 'tip',
                'title'      => 'AI Önerisi',
                'body'       => $result['recommendation'],
                'importance' => 'medium',
                'action'     => $context === 'fx_alerts'
                    ? ['label' => 'Kur Alarmları', 'url' => '/fx-alerts']
                    : ['label' => 'Enflasyon Analizi', 'url' => '/inflation'],
            ];
        }

        // Personal vs official gap
        if (!empty($result['personal_vs_official_gap'])) {
            $insights[] = [
                'type'       => 'info',
                'title'      => 'Kişisel vs Resmi Enflasyon',
                'body'       => $result['personal_vs_official_gap'],
                'importance' => 'low',
            ];
        }

        return $insights ?: [$this->genericAnalyzing()];
    }

    // ── Dashboard: merge BudgetAdvisor + AnomalyDetector ─────────────────────

    private function runDashboard($user): array
    {
        $insights = [];

        try {
            $budgetInsights = $this->runBudgetAdvisor($user);
            $insights       = array_merge($insights, $budgetInsights);
        } catch (\Throwable) {
            // continue
        }

        try {
            $anomalyInsights = $this->runAnomalyDetector($user);
            $insights        = array_merge($insights, $anomalyInsights);
        } catch (\Throwable) {
            // continue
        }

        // Sort by importance: critical > high > medium > low
        $order = ['critical' => 0, 'high' => 1, 'medium' => 2, 'low' => 3];
        usort($insights, function ($a, $b) use ($order) {
            $ia = $order[$a['importance'] ?? 'medium'] ?? 2;
            $ib = $order[$b['importance'] ?? 'medium'] ?? 2;
            return $ia <=> $ib;
        });

        return $insights ?: [$this->genericAnalyzing()];
    }

    // ── Fallback helpers ──────────────────────────────────────────────────────

    private function unavailableInsight(): array
    {
        return [
            'type'       => 'info',
            'title'      => 'AI Analiz Geçici Olarak Devre Dışı',
            'body'       => 'AI analiz şu anda mevcut değil. Lütfen birkaç dakika sonra tekrar deneyin.',
            'importance' => 'low',
        ];
    }

    private function genericAnalyzing(): array
    {
        return [
            'type'       => 'info',
            'title'      => 'Analiz Hazırlanıyor',
            'body'       => 'Yeterli finansal veri bulunamadı. Banka hesabı bağlayın veya demo veri oluşturun.',
            'importance' => 'low',
            'action'     => ['label' => 'Demo Veri Oluştur', 'url' => '/demo-data'],
        ];
    }
}
