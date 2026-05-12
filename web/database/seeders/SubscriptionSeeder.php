<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SubscriptionSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'demo@paranette.local')->first();
        if (! $user) {
            $this->command->warn('Demo user not found.');
            return;
        }

        DB::table('subscriptions')->where('user_id', $user->id)->delete();

        $catId = DB::table('categories')->where('slug', 'dijital-abonelik')->value('id');

        $subs = [
            [
                'name'              => 'Netflix Standard',
                'merchant_name'     => 'Netflix Inc.',
                'amount'            => 289.99,
                'billing_cycle'     => 'monthly',
                'next_billing_date' => now()->startOfMonth()->addMonths(1)->addDays(4)->toDateString(),
                'started_at'        => now()->subMonths(14)->toDateString(),
                'status'            => 'active',
            ],
            [
                'name'              => 'Spotify Premium',
                'merchant_name'     => 'Spotify AB',
                'amount'            => 99.00,
                'billing_cycle'     => 'monthly',
                'next_billing_date' => now()->startOfMonth()->addMonths(1)->addDays(9)->toDateString(),
                'started_at'        => now()->subMonths(22)->toDateString(),
                'status'            => 'active',
            ],
            [
                'name'              => 'YouTube Premium',
                'merchant_name'     => 'Google LLC',
                'amount'            => 79.99,
                'billing_cycle'     => 'monthly',
                'next_billing_date' => now()->startOfMonth()->addMonths(1)->addDays(14)->toDateString(),
                'started_at'        => now()->subMonths(8)->toDateString(),
                'status'            => 'active',
            ],
            [
                'name'              => 'Apple iCloud 50GB',
                'merchant_name'     => 'Apple Inc.',
                'amount'            => 59.99,
                'billing_cycle'     => 'monthly',
                'next_billing_date' => now()->startOfMonth()->addMonths(1)->addDays(1)->toDateString(),
                'started_at'        => now()->subMonths(18)->toDateString(),
                'status'            => 'active',
            ],
            [
                'name'              => 'Amazon Prime',
                'merchant_name'     => 'Amazon.com',
                'amount'            => 69.90,
                'billing_cycle'     => 'monthly',
                'next_billing_date' => now()->startOfMonth()->addMonths(1)->addDays(6)->toDateString(),
                'started_at'        => now()->subMonths(5)->toDateString(),
                'status'            => 'active',
            ],
            [
                'name'              => 'Notion Pro',
                'merchant_name'     => 'Notion Labs',
                'amount'            => 1999.99,
                'billing_cycle'     => 'yearly',
                'next_billing_date' => now()->addMonths(7)->toDateString(),
                'started_at'        => now()->subMonths(5)->toDateString(),
                'status'            => 'active',
            ],
        ];

        foreach ($subs as $sub) {
            DB::table('subscriptions')->insert(array_merge($sub, [
                'user_id'     => $user->id,
                'currency'    => 'TRY',
                'category_id' => $catId,
                'created_at'  => now(),
                'updated_at'  => now(),
            ]));
        }

        $this->command->info('✓ SubscriptionSeeder: ' . count($subs) . ' abonelik eklendi.');
    }
}
