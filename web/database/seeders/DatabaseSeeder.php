<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $this->call([
            CategorySeeder::class,
            BankSeeder::class,
            FakeBankSeeder::class,
            TuikInflationSeeder::class,
        ]);

        // Demo kullanıcısı (UserBankConnectionSeeder email ile bu user'ı bulur)
        User::factory()->create([
            'name'           => 'Ethem Demirkaya',
            'email'          => 'demo@paranette.local',
            'password'       => Hash::make('password'),
            'monthly_income' => 35000.00,
            'inflation_aware'=> true,
        ]);

        $this->call([
            UserBankConnectionSeeder::class,
            TransactionCategorySeeder::class,
            BillSeeder::class,
            SubscriptionSeeder::class,
            BudgetSeeder::class,
            GoalSeeder::class,
            AgentInsightSeeder::class,
            EconomicIndicatorSeeder::class,
            ExchangeRateSeeder::class,
            HealthScoreSeeder::class,
            DemoUsersSeeder::class,
        ]);
    }
}
