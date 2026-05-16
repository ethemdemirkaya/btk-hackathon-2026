<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PersonalDebtSeeder extends Seeder
{
    public function run(): void
    {
        $user = DB::table('users')->where('email', 'demo@paranette.local')->first();
        if (! $user) {
            $this->command->warn('demo@paranette.local bulunamadı — PersonalDebtSeeder atlandı.');
            return;
        }

        // Skip if already seeded
        if (DB::table('personal_debts')->where('user_id', $user->id)->exists()) {
            $this->command->info('PersonalDebt kayıtları zaten mevcut — atlandı.');
            return;
        }

        $now = Carbon::now();

        $debts = [
            // Active — money lent out (given)
            [
                'contact_name'     => 'Burak Şahin',
                'amount'           => 1500.00,
                'direction'        => 'given',
                'note'             => 'Kira için borç verdim - Burak borcu',
                'is_settled'       => false,
                'is_auto_detected' => false,
                'created_at'       => $now->copy()->subDays(45),
            ],
            [
                'contact_name'     => 'Selin Arslan',
                'amount'           => 750.00,
                'direction'        => 'given',
                'note'             => 'Diş tedavisi için ödünç',
                'is_settled'       => false,
                'is_auto_detected' => false,
                'created_at'       => $now->copy()->subDays(22),
            ],
            [
                'contact_name'     => 'Can Öztürk',
                'amount'           => 300.00,
                'direction'        => 'given',
                'note'             => 'Akşam yemeği hesabı',
                'is_settled'       => false,
                'is_auto_detected' => true,
                'created_at'       => $now->copy()->subDays(8),
            ],

            // Active — money borrowed (received)
            [
                'contact_name'     => 'Emre Yıldız',
                'amount'           => 2000.00,
                'direction'        => 'received',
                'note'             => 'Araba tamiri için aldım',
                'is_settled'       => false,
                'is_auto_detected' => false,
                'created_at'       => $now->copy()->subDays(60),
            ],
            [
                'contact_name'     => 'Zeynep Koç',
                'amount'           => 500.00,
                'direction'        => 'received',
                'note'             => 'Fatura ödemesi için borç - Zeynep borcu',
                'is_settled'       => false,
                'is_auto_detected' => true,
                'created_at'       => $now->copy()->subDays(15),
            ],

            // Settled
            [
                'contact_name'     => 'Ahmet Demir',
                'amount'           => 1200.00,
                'direction'        => 'given',
                'note'             => 'Tatil için ödünç verdim',
                'is_settled'       => true,
                'is_auto_detected' => false,
                'settled_at'       => $now->copy()->subDays(10),
                'profit_amount'    => 0.00,
                'created_at'       => $now->copy()->subDays(90),
            ],
            [
                'contact_name'     => 'Fatma Çelik',
                'amount'           => 850.00,
                'direction'        => 'received',
                'note'             => 'Market alışverişi borcu',
                'is_settled'       => true,
                'is_auto_detected' => true,
                'settled_at'       => $now->copy()->subDays(5),
                'profit_amount'    => 0.00,
                'created_at'       => $now->copy()->subDays(35),
            ],
        ];

        foreach ($debts as $debt) {
            DB::table('personal_debts')->insert(array_merge([
                'user_id'                  => $user->id,
                'transaction_id'           => null,
                'repayment_transaction_id' => null,
                'profit_amount'            => null,
                'settled_at'               => null,
                'updated_at'               => $now,
            ], $debt));
        }

        $this->command->info('✓ ' . count($debts) . ' kişisel borç kaydı oluşturuldu (demo@paranette.local).');
    }
}
