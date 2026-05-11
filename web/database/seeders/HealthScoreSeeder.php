<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class HealthScoreSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'demo@paranette.local')->first();
        if (! $user) {
            $this->command->warn('Demo user not found.');
            return;
        }

        DB::table('financial_health_scores')->where('user_id', $user->id)->delete();

        DB::table('financial_health_scores')->insert([
            'user_id'                  => $user->id,
            'score'                    => 68,
            'debt_ratio_score'         => 62,
            'savings_rate_score'       => 74,
            'emergency_fund_score'     => 71,
            'expense_consistency_score'=> 65,
            'components'               => json_encode([
                'debt_ratio'          => ['score' => 62, 'value' => 0.38, 'label' => 'Borç / Gelir Oranı'],
                'savings_rate'        => ['score' => 74, 'value' => 0.21, 'label' => 'Tasarruf Oranı'],
                'emergency_fund'      => ['score' => 71, 'value' => 4.2,  'label' => 'Acil Fon (Ay)'],
                'expense_consistency' => ['score' => 65, 'value' => 0.18, 'label' => 'Gider Değişkenliği'],
            ]),
            'details'                  => json_encode([
                'monthly_income'      => 35000,
                'monthly_expense'     => 27650,
                'monthly_savings'     => 7350,
                'total_debt'          => 159800,
                'liquid_assets'       => 116000,
                'note'                => 'Kart borcu yüksek; acil fon hedefin altında.',
            ]),
            'calculated_at'            => now(),
            'created_at'               => now(),
            'updated_at'               => now(),
        ]);

        $this->command->info('✓ HealthScoreSeeder: Finansal sağlık skoru eklendi (68/100).');
    }
}
