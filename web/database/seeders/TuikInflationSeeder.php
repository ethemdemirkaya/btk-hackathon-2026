<?php

namespace Database\Seeders;

use App\Models\InflationCategoryRate;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

/**
 * TÜİK TÜFE verisi — son 12 ay (2024-05 → 2025-04)
 * Gerçekçi Türkiye enflasyon verileri demo için yerleştirilmiştir.
 */
class TuikInflationSeeder extends Seeder
{
    // Gerçekçi Türkiye TÜFE verileri (yıllık değişim %)
    private const MONTHLY_DATA = [
        '2024-05' => ['genel'=>75.45,'gida'=>70.12,'alkol'=>85.22,'giyim'=>55.30,'konut'=>82.16,'mobilya'=>68.40,'saglik'=>63.28,'ulastirma'=>74.08,'haberlesme'=>45.67,'eglence'=>71.89,'egitim'=>105.33,'lokanta'=>89.54,'diger'=>77.20,'finans'=>75.45],
        '2024-06' => ['genel'=>71.60,'gida'=>66.80,'alkol'=>82.10,'giyim'=>52.40,'konut'=>78.92,'mobilya'=>65.18,'saglik'=>60.44,'ulastirma'=>70.22,'haberlesme'=>43.55,'eglence'=>68.70,'egitim'=>101.44,'lokanta'=>85.33,'diger'=>73.88,'finans'=>71.60],
        '2024-07' => ['genel'=>61.78,'gida'=>57.55,'alkol'=>71.60,'giyim'=>44.20,'konut'=>68.44,'mobilya'=>56.30,'saglik'=>51.80,'ulastirma'=>60.44,'haberlesme'=>38.10,'eglence'=>58.90,'egitim'=>89.22,'lokanta'=>74.10,'diger'=>63.44,'finans'=>61.78],
        '2024-08' => ['genel'=>51.97,'gida'=>48.62,'alkol'=>60.88,'giyim'=>37.44,'konut'=>57.60,'mobilya'=>47.82,'saglik'=>43.66,'ulastirma'=>50.88,'haberlesme'=>33.22,'eglence'=>49.40,'egitim'=>76.10,'lokanta'=>63.22,'diger'=>53.20,'finans'=>51.97],
        '2024-09' => ['genel'=>49.38,'gida'=>46.10,'alkol'=>58.20,'giyim'=>35.22,'konut'=>54.80,'mobilya'=>45.44,'saglik'=>41.20,'ulastirma'=>48.30,'haberlesme'=>31.80,'eglence'=>47.10,'egitim'=>73.40,'lokanta'=>60.80,'diger'=>50.88,'finans'=>49.38],
        '2024-10' => ['genel'=>48.58,'gida'=>45.22,'alkol'=>57.10,'giyim'=>34.44,'konut'=>53.60,'mobilya'=>44.30,'saglik'=>40.10,'ulastirma'=>47.20,'haberlesme'=>30.90,'eglence'=>46.00,'egitim'=>72.20,'lokanta'=>59.44,'diger'=>49.80,'finans'=>48.58],
        '2024-11' => ['genel'=>47.09,'gida'=>43.80,'alkol'=>55.44,'giyim'=>33.10,'konut'=>52.22,'mobilya'=>43.00,'saglik'=>38.80,'ulastirma'=>45.80,'haberlesme'=>29.80,'eglence'=>44.60,'egitim'=>70.80,'lokanta'=>57.90,'diger'=>48.30,'finans'=>47.09],
        '2024-12' => ['genel'=>44.38,'gida'=>41.20,'alkol'=>52.20,'giyim'=>31.00,'konut'=>49.44,'mobilya'=>40.60,'saglik'=>36.40,'ulastirma'=>43.20,'haberlesme'=>28.20,'eglence'=>42.10,'egitim'=>67.80,'lokanta'=>54.90,'diger'=>45.60,'finans'=>44.38],
        '2025-01' => ['genel'=>42.12,'gida'=>39.10,'alkol'=>49.80,'giyim'=>29.20,'konut'=>47.00,'mobilya'=>38.40,'saglik'=>34.20,'ulastirma'=>41.00,'haberlesme'=>26.80,'eglence'=>40.00,'egitim'=>64.60,'lokanta'=>52.20,'diger'=>43.20,'finans'=>42.12],
        '2025-02' => ['genel'=>39.05,'gida'=>36.22,'alkol'=>46.44,'giyim'=>27.10,'konut'=>44.00,'mobilya'=>35.80,'saglik'=>32.00,'ulastirma'=>38.40,'haberlesme'=>25.10,'eglence'=>37.60,'egitim'=>60.80,'lokanta'=>48.80,'diger'=>40.10,'finans'=>39.05],
        '2025-03' => ['genel'=>38.10,'gida'=>33.10,'alkol'=>43.20,'giyim'=>36.22,'konut'=>60.44,'mobilya'=>39.22,'saglik'=>32.44,'ulastirma'=>32.10,'haberlesme'=>26.80,'eglence'=>40.22,'egitim'=>76.10,'lokanta'=>44.20,'diger'=>40.80,'finans'=>38.10],
        '2025-04' => ['genel'=>37.86,'gida'=>30.97,'alkol'=>42.30,'giyim'=>35.24,'konut'=>59.08,'mobilya'=>38.90,'saglik'=>32.10,'ulastirma'=>31.22,'haberlesme'=>26.45,'eglence'=>39.67,'egitim'=>75.33,'lokanta'=>43.51,'diger'=>40.12,'finans'=>37.86],
    ];

    public function run(): void
    {
        $now = now();

        foreach (self::MONTHLY_DATA as $periodStr => $rates) {
            [$year, $month] = explode('-', $periodStr);

            foreach ($rates as $slug => $rate) {
                InflationCategoryRate::updateOrCreate(
                    [
                        'period_year'        => (int) $year,
                        'period_month'       => (int) $month,
                        'tuik_category_slug' => $slug,
                    ],
                    [
                        'annual_change_rate' => $rate,
                        'fetched_at'         => $now,
                    ]
                );
            }
        }
    }
}
