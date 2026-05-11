<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BudgetSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'demo@paranette.local')->first();
        if (! $user) {
            $this->command->warn('Demo user not found.');
            return;
        }

        $period = now()->format('Y-m');

        DB::table('budgets')
            ->where('user_id', $user->id)
            ->where('period', $period)
            ->delete();

        $slugsToAmounts = [
            'market'         => [4000.00, 80],
            'restoran-kafe'  => [2500.00, 80],
            'faturalar'      => [3000.00, 90],
            'ulasim'         => [2000.00, 80],
            'eglence'        => [1500.00, 75],
            'saglik'         => [1000.00, 85],
            'online-yemek'   => [800.00,  80],
            'giyim-aksesuar' => [2000.00, 80],
        ];

        foreach ($slugsToAmounts as $slug => [$amount, $threshold]) {
            $catId = DB::table('categories')->where('slug', $slug)->value('id');
            if (! $catId) {
                continue;
            }

            DB::table('budgets')->insertOrIgnore([
                'user_id'         => $user->id,
                'category_id'     => $catId,
                'period'          => $period,
                'amount'          => $amount,
                'alert_threshold' => $threshold,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);
        }

        $this->command->info('✓ BudgetSeeder: ' . count($slugsToAmounts) . ' bütçe eklendi (' . $period . ').');
    }
}
