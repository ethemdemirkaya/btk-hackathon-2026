<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class GoalSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'demo@paranette.local')->first();
        if (! $user) {
            $this->command->warn('Demo user not found.');
            return;
        }

        DB::table('goals')->where('user_id', $user->id)->delete();

        $goals = [
            [
                'name'                => 'Tatil Fonu',
                'target_amount'       => 25000.00,
                'current_amount'      => 8500.00,
                'target_date'         => '2026-08-15',
                'monthly_contribution'=> 2000.00,
                'status'              => 'active',
            ],
            [
                'name'                => 'Acil Durum Fonu',
                'target_amount'       => 100000.00,
                'current_amount'      => 42000.00,
                'target_date'         => '2026-12-31',
                'monthly_contribution'=> 3000.00,
                'status'              => 'active',
            ],
            [
                'name'                => 'Yeni MacBook Pro',
                'target_amount'       => 85000.00,
                'current_amount'      => 31500.00,
                'target_date'         => '2026-10-01',
                'monthly_contribution'=> 5000.00,
                'status'              => 'active',
            ],
            [
                'name'                => 'Konut Peşinatı',
                'target_amount'       => 500000.00,
                'current_amount'      => 75000.00,
                'target_date'         => '2028-01-01',
                'monthly_contribution'=> 10000.00,
                'status'              => 'active',
            ],
        ];

        foreach ($goals as $goal) {
            DB::table('goals')->insert(array_merge($goal, [
                'user_id'    => $user->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }

        $this->command->info('✓ GoalSeeder: ' . count($goals) . ' hedef eklendi.');
    }
}
