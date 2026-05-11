<?php

namespace Database\Seeders;

use App\Models\Bill;
use App\Models\User;
use Illuminate\Database\Seeder;

class BillSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'demo@paranette.local')->first();
        if (! $user) {
            return;
        }

        $bills = [
            ['name' => 'AYEDAŞ Elektrik', 'type' => 'electricity', 'provider' => 'AYEDAŞ', 'average_amount' => 850.00,  'due_day' => 15, 'is_autopay' => false],
            ['name' => 'İSKİ Su',          'type' => 'water',       'provider' => 'İSKİ',   'average_amount' => 280.00,  'due_day' => 20, 'is_autopay' => false],
            ['name' => 'BOTAŞ Doğalgaz',   'type' => 'gas',         'provider' => 'BOTAŞ',  'average_amount' => 1200.00, 'due_day' => 25, 'is_autopay' => true],
            ['name' => 'Türk Telekom İnt', 'type' => 'internet',    'provider' => 'Türk Telekom', 'average_amount' => 399.00, 'due_day' => 5, 'is_autopay' => true],
            ['name' => 'Turkcell Hat',     'type' => 'phone',       'provider' => 'Turkcell', 'average_amount' => 650.00, 'due_day' => 10, 'is_autopay' => true],
            ['name' => 'Kira',             'type' => 'rent',        'provider' => null,       'average_amount' => 12000.00, 'due_day' => 1, 'is_autopay' => false],
            ['name' => 'Trafik Sigortası', 'type' => 'insurance',   'provider' => 'Allianz', 'average_amount' => 420.00, 'due_day' => 28, 'is_autopay' => false],
        ];

        foreach ($bills as $bill) {
            Bill::firstOrCreate(
                ['user_id' => $user->id, 'name' => $bill['name']],
                array_merge($bill, [
                    'user_id'     => $user->id,
                    'last_paid_at'=> now()->subMonth()->startOfMonth()->addDays(($bill['due_day'] ?? 1) - 1),
                    'last_amount' => $bill['average_amount'],
                ])
            );
        }
    }
}
