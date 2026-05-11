<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Creates 2 additional demo users (Ayşe Kaya, Mehmet Yılmaz) with
 * complete financial data seeded directly — no FakeBank OAuth flow needed.
 */
class DemoUsersSeeder extends Seeder
{
    public function run(): void
    {
        $banks = DB::table('banks')->get()->keyBy('slug');

        $profiles = [
            [
                'name'           => 'Ayşe Kaya',
                'email'          => 'ayse@paranette.local',
                'monthly_income' => 22000.00,
                'bank_slugs'     => ['garanti', 'ziraat'],
                'spending' => [
                    ['merchant' => 'BİM Market',          'category' => 'market',          'min' => 350,  'max' => 900,  'freq' => 7,  'channel' => 'pos'],
                    ['merchant' => 'Migros',              'category' => 'market',          'min' => 200,  'max' => 600,  'freq' => 4,  'channel' => 'pos'],
                    ['merchant' => 'Yemeksepeti',         'category' => 'online-yemek',    'min' => 80,   'max' => 220,  'freq' => 5,  'channel' => 'online'],
                    ['merchant' => 'İETT',                'category' => 'toplu-tasima',    'min' => 30,   'max' => 80,   'freq' => 20, 'channel' => 'pos'],
                    ['merchant' => 'Eczane Sağlık',      'category' => 'eczane',          'min' => 50,   'max' => 300,  'freq' => 2,  'channel' => 'pos'],
                    ['merchant' => 'Vodafone',            'category' => 'telefon',         'min' => 199,  'max' => 199,  'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Netflix',             'category' => 'dijital-abonelik','min' => 139,  'max' => 139,  'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Türk Telekom',        'category' => 'internet',        'min' => 349,  'max' => 349,  'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Giyim AVM',           'category' => 'kiyafet',         'min' => 200,  'max' => 800,  'freq' => 1,  'channel' => 'pos'],
                    ['merchant' => 'Kitap & Kırtasiye',  'category' => 'kitap-kirtasiye', 'min' => 50,   'max' => 250,  'freq' => 1,  'channel' => 'pos'],
                ],
                'income_desc' => 'Maaş - Ayşe Kaya',
                'loans' => [
                    ['type' => 'personal', 'principal' => 45000, 'balance' => 28400, 'rate' => 3.89, 'total' => 36, 'paid' => 14, 'payment' => 1420, 'bank' => 'garanti'],
                ],
                'bills' => [
                    ['name' => 'Elektrik',  'type' => 'electricity', 'provider' => 'BEDAŞ',  'due' => 15, 'avg' => 280],
                    ['name' => 'Su',        'type' => 'water',       'provider' => 'İSKİ',   'due' => 20, 'avg' => 85],
                    ['name' => 'Doğalgaz',  'type' => 'gas',         'provider' => 'İGDAŞ',  'due' => 10, 'avg' => 320],
                    ['name' => 'İnternet',  'type' => 'internet',    'provider' => 'Türk Telekom', 'due' => 5, 'avg' => 349],
                ],
                'subscriptions' => [
                    ['name' => 'Netflix',   'merchant' => 'Netflix Inc.',  'amount' => 139.99, 'cycle' => 'monthly',  'next_day' => 8],
                    ['name' => 'Spotify Premium', 'merchant' => 'Spotify', 'amount' => 49.99,  'cycle' => 'monthly',  'next_day' => 15],
                ],
                'goals' => [
                    ['name' => 'Tatil Fonu',       'target' => 15000, 'current' => 4200, 'months' => 8],
                    ['name' => 'Acil Durum Fonu',  'target' => 50000, 'current' => 12000,'months' => 24],
                ],
                'budgets' => [
                    ['category' => 'yiyecek-iceeck', 'amount' => 4500, 'alert' => 80],
                    ['category' => 'ulasim',          'amount' => 800,  'alert' => 90],
                    ['category' => 'eglence',         'amount' => 1000, 'alert' => 85],
                ],
            ],
            [
                'name'           => 'Mehmet Yılmaz',
                'email'          => 'mehmet@paranette.local',
                'monthly_income' => 68000.00,
                'bank_slugs'     => ['akbank', 'isbank', 'garanti'],
                'spending' => [
                    ['merchant' => 'CarrefourSA',         'category' => 'market',          'min' => 800,   'max' => 2500,  'freq' => 5,  'channel' => 'pos'],
                    ['merchant' => 'Mado Restoran',       'category' => 'restoran-kafe',   'min' => 200,   'max' => 800,   'freq' => 8,  'channel' => 'pos'],
                    ['merchant' => 'Opet Akaryakıt',      'category' => 'yakit',           'min' => 1200,  'max' => 2800,  'freq' => 3,  'channel' => 'pos'],
                    ['merchant' => 'Apple Store',         'category' => 'elektronik',      'min' => 500,   'max' => 8000,  'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Zara',                'category' => 'kiyafet',         'min' => 500,   'max' => 2000,  'freq' => 2,  'channel' => 'pos'],
                    ['merchant' => 'BeIN Sports',         'category' => 'dijital-abonelik','min' => 259,   'max' => 259,   'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Netflix',             'category' => 'dijital-abonelik','min' => 199,   'max' => 199,   'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Spotify Premium',     'category' => 'dijital-abonelik','min' => 49,    'max' => 49,    'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Turkcell',            'category' => 'telefon',         'min' => 499,   'max' => 499,   'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Sigorta Acentesi',    'category' => 'sigorta',         'min' => 1200,  'max' => 1200,  'freq' => 1,  'channel' => 'online'],
                    ['merchant' => 'Spor Salonu',         'category' => 'spor',            'min' => 650,   'max' => 650,   'freq' => 1,  'channel' => 'pos'],
                    ['merchant' => 'Eczane',              'category' => 'eczane',          'min' => 100,   'max' => 600,   'freq' => 1,  'channel' => 'pos'],
                    ['merchant' => 'Çiçekçi / Hediye',   'category' => 'diger',           'min' => 200,   'max' => 1000,  'freq' => 1,  'channel' => 'pos'],
                ],
                'income_desc' => 'Maaş / Serbest Meslek - Mehmet Yılmaz',
                'loans' => [
                    ['type' => 'mortgage', 'principal' => 1800000, 'balance' => 1540000, 'rate' => 2.49, 'total' => 180, 'paid' => 22, 'payment' => 22400, 'bank' => 'akbank'],
                    ['type' => 'vehicle',  'principal' => 480000,  'balance' => 310000,  'rate' => 3.10, 'total' => 48,  'paid' => 16, 'payment' => 12800, 'bank' => 'isbank'],
                ],
                'bills' => [
                    ['name' => 'Elektrik',  'type' => 'electricity', 'provider' => 'BEDAŞ',  'due' => 12, 'avg' => 680],
                    ['name' => 'Su',        'type' => 'water',       'provider' => 'İSKİ',   'due' => 18, 'avg' => 130],
                    ['name' => 'Doğalgaz',  'type' => 'gas',         'provider' => 'İGDAŞ',  'due' => 8,  'avg' => 820],
                    ['name' => 'İnternet',  'type' => 'internet',    'provider' => 'Türk Telekom', 'due' => 3, 'avg' => 499],
                    ['name' => 'Telefon',   'type' => 'phone',       'provider' => 'Turkcell','due' => 22, 'avg' => 499],
                ],
                'subscriptions' => [
                    ['name' => 'Netflix Premium',  'merchant' => 'Netflix',    'amount' => 199.99, 'cycle' => 'monthly', 'next_day' => 5],
                    ['name' => 'Spotify Premium',  'merchant' => 'Spotify',    'amount' => 49.99,  'cycle' => 'monthly', 'next_day' => 5],
                    ['name' => 'BeIN Sports',       'merchant' => 'BeIN Group','amount' => 259.90, 'cycle' => 'monthly', 'next_day' => 1],
                    ['name' => 'Apple One',         'merchant' => 'Apple',     'amount' => 219.99, 'cycle' => 'monthly', 'next_day' => 18],
                    ['name' => 'Microsoft 365',     'merchant' => 'Microsoft', 'amount' => 479.00, 'cycle' => 'yearly',  'next_day' => 10],
                ],
                'goals' => [
                    ['name' => 'Yatırım Fonu',     'target' => 500000,  'current' => 148000, 'months' => 36],
                    ['name' => 'Araba Değişimi',   'target' => 1800000, 'current' => 95000,  'months' => 48],
                ],
                'budgets' => [
                    ['category' => 'yiyecek-iceeck', 'amount' => 12000, 'alert' => 80],
                    ['category' => 'ulasim',          'amount' => 8000,  'alert' => 80],
                    ['category' => 'eglence',         'amount' => 6000,  'alert' => 90],
                    ['category' => 'giyim-aksesuar',  'amount' => 5000,  'alert' => 85],
                ],
            ],
        ];

        foreach ($profiles as $profile) {
            // Skip if user already exists
            if (DB::table('users')->where('email', $profile['email'])->exists()) {
                $this->command->info("Skipping {$profile['email']} (already exists).");
                continue;
            }

            $userId = DB::table('users')->insertGetId([
                'name'            => $profile['name'],
                'email'           => $profile['email'],
                'password'        => Hash::make('password'),
                'monthly_income'  => $profile['monthly_income'],
                'inflation_aware' => true,
                'email_verified_at' => now(),
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);

            // Bank connections + accounts
            $accountsByBankSlug = [];
            foreach ($profile['bank_slugs'] as $slug) {
                $bank = $banks->get($slug);
                if (! $bank) continue;

                $connId = DB::table('bank_connections')->insertGetId([
                    'user_id'      => $userId,
                    'bank_id'      => $bank->id,
                    'encrypted_credentials' => json_encode(['demo' => true]),
                    'status'       => 'active',
                    'last_sync_at' => now(),
                    'created_at'   => now(),
                    'updated_at'   => now(),
                ]);

                $balance = rand(8000, 85000) * 100 / 100;
                $accId   = DB::table('accounts')->insertGetId([
                    'user_id'            => $userId,
                    'bank_connection_id' => $connId,
                    'external_id'        => 'DEMO-' . strtoupper($slug) . '-' . $userId,
                    'account_type'       => 'checking',
                    'iban'               => 'TR' . str_pad($userId . rand(100000, 999999), 24, '0', STR_PAD_LEFT),
                    'currency'           => 'TRY',
                    'balance'            => $balance,
                    'available_balance'  => $balance * 0.95,
                    'created_at'         => now(),
                    'updated_at'         => now(),
                ]);

                $accountsByBankSlug[$slug] = ['conn_id' => $connId, 'account_id' => $accId];
            }

            $primaryAccId = array_values($accountsByBankSlug)[0]['account_id'];
            $primaryConnId = array_values($accountsByBankSlug)[0]['conn_id'];

            // Credit card
            DB::table('cards')->insert([
                'user_id'         => $userId,
                'account_id'      => $primaryAccId,
                'type'            => 'credit',
                'masked_number'   => '**** **** **** ' . rand(1000, 9999),
                'expiry_month'    => rand(1, 12),
                'expiry_year'     => 2028,
                'holder_name'     => $profile['name'],
                'credit_limit'    => $profile['monthly_income'] * 3,
                'current_debt'    => $profile['monthly_income'] * rand(20, 60) / 100,
                'available_limit' => $profile['monthly_income'] * 3 - ($profile['monthly_income'] * rand(20, 60) / 100),
                'statement_day'   => 1,
                'due_day'         => 10,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);

            // Loans
            foreach ($profile['loans'] as $ln) {
                $connId = ($accountsByBankSlug[$ln['bank']] ?? array_values($accountsByBankSlug)[0])['conn_id'];
                DB::table('loans')->insert([
                    'user_id'             => $userId,
                    'bank_connection_id'  => $connId,
                    'external_id'         => 'LOAN-' . Str::upper($ln['type']) . '-' . $userId,
                    'type'                => $ln['type'],
                    'principal'           => $ln['principal'],
                    'current_balance'     => $ln['balance'],
                    'interest_rate'       => $ln['rate'],
                    'total_installments'  => $ln['total'],
                    'paid_installments'   => $ln['paid'],
                    'next_payment_date'   => now()->addDays(rand(5, 25))->toDateString(),
                    'next_payment_amount' => $ln['payment'],
                    'started_at'         => now()->subMonths($ln['paid'])->toDateString(),
                    'ends_at'            => now()->addMonths($ln['total'] - $ln['paid'])->toDateString(),
                    'created_at'         => now(),
                    'updated_at'         => now(),
                ]);
            }

            // Bills
            foreach ($profile['bills'] as $b) {
                DB::table('bills')->insert([
                    'user_id'        => $userId,
                    'name'           => $b['name'],
                    'type'           => $b['type'],
                    'provider'       => $b['provider'],
                    'average_amount' => $b['avg'],
                    'due_day'        => $b['due'],
                    'is_autopay'     => rand(0, 1),
                    'created_at'     => now(),
                    'updated_at'     => now(),
                ]);
            }

            // Subscriptions
            foreach ($profile['subscriptions'] as $sub) {
                DB::table('subscriptions')->insert([
                    'user_id'           => $userId,
                    'name'              => $sub['name'],
                    'merchant_name'     => $sub['merchant'],
                    'amount'            => $sub['amount'],
                    'billing_cycle'     => $sub['cycle'],
                    'next_billing_date' => now()->startOfMonth()->addDays($sub['next_day'] - 1)->toDateString(),
                    'status'            => 'active',
                    'auto_detected'     => false,
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ]);
            }

            // Goals
            foreach ($profile['goals'] as $g) {
                $pct  = min(100, round($g['current'] / $g['target'] * 100));
                $stat = $pct >= 100 ? 'completed' : 'active';
                DB::table('goals')->insert([
                    'user_id'              => $userId,
                    'name'                 => $g['name'],
                    'target_amount'        => $g['target'],
                    'current_amount'       => $g['current'],
                    'monthly_contribution' => round($g['target'] / $g['months']),
                    'target_date'          => now()->addMonths($g['months'])->toDateString(),
                    'status'               => $stat,
                    'created_at'           => now(),
                    'updated_at'           => now(),
                ]);
            }

            // Budgets + categories
            $catMap = DB::table('categories')->get()->keyBy('slug');
            $period = now()->format('Y-m');
            foreach ($profile['budgets'] as $b) {
                $cat = $catMap->get($b['category']);
                if (! $cat) continue;
                DB::table('budgets')->insert([
                    'user_id'         => $userId,
                    'category_id'     => $cat->id,
                    'amount'          => $b['amount'],
                    'period'          => $period,
                    'alert_threshold' => $b['alert'],
                    'created_at'      => now(),
                    'updated_at'      => now(),
                ]);
            }

            // Transactions: 6 months of history
            $txBatch = [];
            for ($m = 5; $m >= 0; $m--) {
                $monthStart = now()->startOfMonth()->subMonths($m);
                $monthEnd   = $monthStart->copy()->endOfMonth();

                // Monthly income
                $txBatch[] = [
                    'id'                => Str::uuid()->toString(),
                    'account_id'        => $primaryAccId,
                    'posted_at'         => $monthStart->copy()->addDays(1)->toDateTimeString(),
                    'amount'            => $profile['monthly_income'],
                    'try_amount'        => $profile['monthly_income'],
                    'currency'          => 'TRY',
                    'description'       => $profile['income_desc'],
                    'merchant_name'     => null,
                    'merchant_category' => null,
                    'category_id'       => null,
                    'channel'           => 'transfer',
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ];

                // Expenses
                foreach ($profile['spending'] as $spend) {
                    $catObj = $catMap->get($spend['category']);
                    for ($f = 0; $f < $spend['freq']; $f++) {
                        $day = rand(1, min(28, $monthEnd->day));
                        $amt = rand((int) $spend['min'] * 100, (int) $spend['max'] * 100) / 100;
                        $txBatch[] = [
                            'id'              => Str::uuid()->toString(),
                            'account_id'      => $primaryAccId,
                            'posted_at'       => $monthStart->copy()->addDays($day - 1)->toDateTimeString(),
                            'amount'          => -$amt,
                            'try_amount'      => -$amt,
                            'currency'        => 'TRY',
                            'description'     => $spend['merchant'] . ' alışverişi',
                            'merchant_name'   => $spend['merchant'],
                            'merchant_category' => $catObj?->name ?? null,
                            'category_id'     => $catObj?->id ?? null,
                            'channel'         => $spend['channel'],
                            'created_at'      => now(),
                            'updated_at'      => now(),
                        ];
                    }
                }

                if (count($txBatch) >= 200) {
                    DB::table('transactions')->insert($txBatch);
                    $txBatch = [];
                }
            }

            if (! empty($txBatch)) {
                DB::table('transactions')->insert($txBatch);
            }

            $this->command->info("✓ {$profile['name']} ({$profile['email']}) oluşturuldu — " . count($profile['spending']) . " harcama kalıbı, " . count($profile['loans']) . " kredi.");
        }
    }
}
