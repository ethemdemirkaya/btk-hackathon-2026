<?php

namespace App\Services;

use App\Models\InflationCategoryRate;
use App\Models\InflationRate;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Kullanıcının kişisel enflasyon oranını hesaplar.
 *
 * Algoritma:
 *  1. Son 90 günde kullanıcının TÜİK kategorisine göre harcama ağırlıklarını hesapla
 *  2. Her kategorinin ağırlığını, o kategorinin resmi TÜİK oranıyla çarp
 *  3. Topla → kişisel yıllık enflasyon
 *
 * Ör: Konut %32 harcama × %59.08 enflasyon + Gıda %18 × %30.97 + ...
 */
class PersonalInflationService
{
    // TÜİK category slug → app category slug mapping
    // (categories tablosundaki tuik_category_slug alanı zaten bu slug'ları içeriyor)
    public function __construct(
        private readonly TuikApiService $tuikService
    ) {}

    /**
     * Kullanıcının kişisel enflasyon oranını hesaplar ve kaydeder.
     * Döner: ['personal_rate' => 38.24, 'tufe_rate' => 32.37, 'diff' => +5.87, 'breakdown' => [...]]
     */
    public function calculate(User $user, ?Carbon $asOf = null): array
    {
        $asOf   ??= Carbon::now();
        $since    = $asOf->copy()->subDays(90);
        $prevMonth = $asOf->copy()->subMonth();
        $year     = $prevMonth->year;
        $month    = $prevMonth->month;

        // TÜİK kategori oranlarını al
        $tuikRates = $this->getTuikRates($year, $month);
        $tufeRate  = $tuikRates['genel'] ?? 37.86;

        // Kullanıcının kategori bazında toplam harcamasını al
        $spending  = $this->getUserCategorySpending($user->id, $since, $asOf);

        if ($spending->isEmpty()) {
            return $this->emptyResult($tufeRate);
        }

        $total = $spending->sum('total');

        if ($total <= 0) {
            return $this->emptyResult($tufeRate);
        }

        $personalRate = 0.0;
        $breakdown    = [];

        foreach ($spending as $row) {
            $slug   = $row->tuik_slug;
            $weight = round($row->total / $total * 100, 2);
            $rate   = (float) ($tuikRates[$slug] ?? $tufeRate);

            $contribution  = $weight * $rate / 100;
            $personalRate += $contribution;

            $breakdown[] = [
                'category'     => $row->category_name,
                'tuik_slug'    => $slug,
                'weight_pct'   => $weight,
                'tuik_rate'    => $rate,
                'contribution' => round($contribution, 4),
            ];
        }

        $personalRate = round($personalRate, 2);

        return [
            'personal_rate' => $personalRate,
            'tufe_rate'     => $tufeRate,
            'diff'          => round($personalRate - $tufeRate, 2),
            'period'        => "{$year}-{$month}",
            'days_analyzed' => 90,
            'total_spending'=> round($total, 2),
            'breakdown'     => collect($breakdown)->sortByDesc('weight_pct')->values()->all(),
        ];
    }

    /**
     * Placeholder — returns empty until personal_inflation_snapshots table exists.
     */
    public function getHistory(User $user, int $months = 6): array
    {
        return [];
    }

    // ──────────────────────────────────────────────────────────────────────

    private function getUserCategorySpending(int $userId, Carbon $from, Carbon $to)
    {
        return DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->join('categories as c', 'c.id', '=', 't.category_id')
            ->select(
                'c.name as category_name',
                DB::raw('COALESCE(c.tuik_category_slug, "diger") as tuik_slug'),
                DB::raw('SUM(ABS(t.amount)) as total')
            )
            ->where('a.user_id', $userId)
            ->where('t.amount', '<', 0)
            ->whereBetween('t.posted_at', [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->whereNotNull('t.category_id')
            ->groupBy('c.id', 'c.name', 'c.tuik_category_slug')
            ->orderByDesc('total')
            ->get();
    }

    private function getTuikRates(int $year, int $month): array
    {
        $rows = InflationCategoryRate::where('period_year', $year)
            ->where('period_month', $month)
            ->get()
            ->keyBy('tuik_category_slug');

        if ($rows->isEmpty()) {
            // Trigger a fetch for this period
            $this->tuikService->fetchAndStore(Carbon::createFromDate($year, $month, 1));

            $rows = InflationCategoryRate::where('period_year', $year)
                ->where('period_month', $month)
                ->get()
                ->keyBy('tuik_category_slug');
        }

        return $rows->map(fn ($r) => (float) $r->annual_change_rate)->all();
    }

    private function emptyResult(float $tufeRate): array
    {
        return [
            'personal_rate' => null,
            'tufe_rate'     => $tufeRate,
            'diff'          => null,
            'period'        => null,
            'days_analyzed' => 90,
            'total_spending'=> 0,
            'breakdown'     => [],
        ];
    }
}
