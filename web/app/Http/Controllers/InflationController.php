<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class InflationController extends Controller
{
    // Maps transaction descriptions → TÜİK slugs
    private const DESC_MAP = [
        'Market'        => 'gida', 'market'       => 'gida',
        'Haftalık'      => 'gida', 'Manav'        => 'gida',
        'Restoran'      => 'lokanta', 'Yemek'     => 'lokanta',
        'Kafe'          => 'lokanta', 'Kahve'      => 'lokanta',
        'Öğle Yemeği'   => 'lokanta', 'Akşam Yemeği' => 'lokanta',
        'Benzin'        => 'ulastirma', 'Motorin'  => 'ulastirma',
        'Ulaşım'        => 'ulastirma', 'Taksi'    => 'ulastirma',
        'Elektrik'      => 'konut', 'Doğalgaz'    => 'konut',
        'Su Fatura'     => 'konut', 'Kira'        => 'konut',
        'İnternet'      => 'haberlesme', 'Telefon' => 'haberlesme',
        'iCloud'        => 'haberlesme', 'GSM'     => 'haberlesme',
        'Sağlık'        => 'saglik', 'Eczane'     => 'saglik',
        'Doktor'        => 'saglik',
        'Okul'          => 'egitim', 'Kurs'       => 'egitim',
        'Kitap'         => 'egitim',
        'Sinema'        => 'eglence', 'Spor'      => 'eglence',
        'Spotify'       => 'eglence', 'Netflix'   => 'eglence',
        'Giyim'         => 'giyim', 'Kıyafet'    => 'giyim',
        'Mobilya'       => 'mobilya', 'Beyaz Eşya'=> 'mobilya',
        'Alkol'         => 'alkol', 'Sigara'      => 'alkol',
        'Banka'         => 'finans', 'Kredi'      => 'finans',
        'Sigorta'       => 'finans',
    ];

    public function index(Request $request): View
    {
        $user = $request->user();

        // Latest TÜİK category rates
        $latestPeriod = DB::table('inflation_category_rates')
            ->selectRaw('period_year, period_month')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->first();

        $categoryRates = collect();
        $headline = 37.86;
        $periodLabel = 'Nisan 2025';

        if ($latestPeriod) {
            $categoryRates = DB::table('inflation_category_rates')
                ->where('period_year', $latestPeriod->period_year)
                ->where('period_month', $latestPeriod->period_month)
                ->whereNotIn('tuik_category_slug', ['genel'])
                ->orderByDesc('annual_change_rate')
                ->get();

            $generalRate = DB::table('inflation_category_rates')
                ->where('period_year', $latestPeriod->period_year)
                ->where('period_month', $latestPeriod->period_month)
                ->where('tuik_category_slug', 'genel')
                ->value('annual_change_rate');

            if ($generalRate) $headline = (float) $generalRate;

            $monthNames = ['', 'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
                           'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
            $periodLabel = ($monthNames[$latestPeriod->period_month] ?? '') . ' ' . $latestPeriod->period_year;
        }

        // Historical headline inflation (last 12 months from category rates)
        $historical = DB::table('inflation_category_rates')
            ->where('tuik_category_slug', 'genel')
            ->orderByDesc('period_year')->orderByDesc('period_month')
            ->limit(12)
            ->get(['period_year', 'period_month', 'annual_change_rate'])
            ->reverse()->values();

        // Calculate personal inflation from user spending
        $spendingByDesc = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', now()->subMonths(3))
            ->select('t.description', DB::raw('SUM(ABS(t.amount)) as total'))
            ->groupBy('t.description')
            ->get();

        $spendingByTuik = [];
        $totalSpend = 0;
        foreach ($spendingByDesc as $row) {
            $slug = $this->mapDescToTuik($row->description);
            $spendingByTuik[$slug] = ($spendingByTuik[$slug] ?? 0) + (float)$row->total;
            $totalSpend += (float) $row->total;
        }

        $personalRate = 0.0;
        $personalBreakdown = [];
        if ($totalSpend > 0 && $categoryRates->isNotEmpty()) {
            $rateMap = $categoryRates->keyBy('tuik_category_slug');
            foreach ($spendingByTuik as $slug => $amount) {
                $weight = $amount / $totalSpend;
                $rate   = (float) ($rateMap[$slug]?->annual_change_rate ?? $headline);
                $personalRate += $weight * $rate;
                $personalBreakdown[] = [
                    'slug'   => $slug,
                    'amount' => round($amount, 0),
                    'weight' => round($weight * 100, 1),
                    'rate'   => round($rate, 2),
                    'impact' => round($weight * $rate, 2),
                ];
            }
            usort($personalBreakdown, fn($a,$b) => $b['impact'] <=> $a['impact']);
        }

        $personalRate    = round($personalRate, 2) ?: $headline;
        $personalDelta   = round($personalRate - $headline, 2);
        $topImpact       = $personalBreakdown[0] ?? null;

        return view('inflation.index', compact(
            'categoryRates', 'headline', 'periodLabel', 'historical',
            'personalRate', 'personalDelta', 'personalBreakdown', 'topImpact',
            'totalSpend'
        ));
    }

    private function mapDescToTuik(string $desc): string
    {
        foreach (self::DESC_MAP as $keyword => $slug) {
            if (str_contains($desc, $keyword)) return $slug;
        }
        return 'diger';
    }
}
