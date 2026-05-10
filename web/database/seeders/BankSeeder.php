<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BankSeeder extends Seeder
{
    public function run(): void
    {
        $banks = [
            [
                'name'         => 'Ziraat Bankası',
                'slug'         => 'ziraat',
                'logo'         => 'assets/img/banks/ziraat.svg',
                'api_base_url' => config('app.url') . '/api/banks/ziraat',
                'auth_type'    => 'bearer',
                'is_active'    => true,
            ],
            [
                'name'         => 'Garanti BBVA',
                'slug'         => 'garanti',
                'logo'         => 'assets/img/banks/garanti.svg',
                'api_base_url' => config('app.url') . '/api/banks/garanti',
                'auth_type'    => 'oauth2',
                'is_active'    => true,
            ],
            [
                'name'         => 'İş Bankası',
                'slug'         => 'isbank',
                'logo'         => 'assets/img/banks/isbank.svg',
                'api_base_url' => config('app.url') . '/api/banks/isbank',
                'auth_type'    => 'hmac',
                'is_active'    => true,
            ],
            [
                'name'         => 'Akbank',
                'slug'         => 'akbank',
                'logo'         => 'assets/img/banks/akbank.svg',
                'api_base_url' => config('app.url') . '/api/banks/akbank',
                'auth_type'    => 'jsonrpc',
                'is_active'    => true,
            ],
        ];

        foreach ($banks as $bank) {
            DB::table('banks')->updateOrInsert(
                ['slug' => $bank['slug']],
                array_merge($bank, ['created_at' => now(), 'updated_at' => now()])
            );
        }
    }
}
