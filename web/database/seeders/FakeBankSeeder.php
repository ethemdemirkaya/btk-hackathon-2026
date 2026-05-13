<?php

namespace Database\Seeders;

use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCard;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankLoan;
use App\Models\FakeBank\FakeBankTransaction;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Demo kullanıcısı için 4 bankada gerçekçi 6 aylık finansal veri.
 * TCKN: 12345678901 | Ad: Ethem Demirkaya | Maaş: ~35.000 TL/ay (15. gün)
 *
 * Davranış kalıpları:
 *  - Maaş günü (15): büyük gelen transfer
 *  - Ay başı (1-5): kira, fatura ödemeleri
 *  - Hafta içi: market, iş yemeği, ulaşım yoğun
 *  - Hafta sonu: restoran, AVM, eğlence yoğun
 *  - Her ay: abonelikler (Netflix, Spotify, gym)
 */
class FakeBankSeeder extends Seeder
{
    private const TCKN = '12345678901';
    private const NAME = 'Ethem Demirkaya';

    // Merchants grouped by category
    private const GROCERIES  = ['Migros', 'CarrefourSA', 'A101', 'BİM', 'Şok Market', 'Özdilek Market'];
    private const RESTAURANTS = ['Sushi Lab', 'Dürümcü Emmi', 'Köfteci Yusuf', 'Popeyes', 'Nusret Etiler',
                                   'Meşhur Pide', 'Kral Burger', 'Tahta Bahçe', 'Mahalle Pidecisi', 'Pizza Hut'];
    private const CAFES       = ['Starbucks', 'Gloria Jeans', 'Kahve Dünyası', 'Caribou Coffee', 'Espresso Lab'];
    private const TRANSPORT   = ['İETT', 'Uber', 'Bitaksi', 'Dolmuş', 'Beltur İBB'];
    private const FUEL        = ['BP Akaryakıt', 'Shell', 'Total Enerji', 'Opet'];
    private const ONLINE      = ['Amazon TR', 'Trendyol', 'Hepsiburada', 'n11', 'GittiGidiyor'];
    private const SUBSCRIPTIONS = [
        ['Netflix', 259.00],
        ['Spotify', 69.99],
        ['YouTube Premium', 139.99],
        ['Gym Üyeliği', 890.00],
        ['iCloud 200GB', 39.99],
    ];
    private const UTILITIES   = [
        ['İGDAŞ Doğalgaz', 450],
        ['TEDAŞ Elektrik', 620],
        ['İSKİ Su', 180],
        ['Türk Telekom İnternet', 399],
    ];

    public function run(): void
    {
        $endDate   = Carbon::now()->startOfDay();
        $startDate = $endDate->copy()->subMonths(6);

        foreach ($this->banks() as $bank) {
            // Skip if customer already exists (idempotent re-run)
            $existing = FakeBankCustomer::where('customer_id', $bank['customer_id'])->first();
            if ($existing) {
                continue;
            }

            $customer = $this->createCustomer($bank);
            $accounts = $this->createAccounts($bank, $customer);
            $cards    = $this->createCards($bank, $customer, $accounts[0]);

            $this->createLoans($bank, $customer);
            $this->createTransactions($bank, $customer, $accounts, $cards, $startDate, $endDate);
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Bank configurations
    // ──────────────────────────────────────────────────────────────

    // Fixed credentials — must stay stable across re-seeds so UserBankConnectionSeeder
    // can reference them without querying the DB.
    public const CREDENTIALS = [
        'ziraat'  => ['tckn' => self::TCKN, 'password' => 'password'],
        'garanti' => ['client_id' => self::TCKN, 'client_secret' => 'garanti-demo-secret-2026'],
        'isbank'  => ['tckn' => self::TCKN, 'hmac_secret' => 'isbank-demo-hmac-key-2026-paranette'],
        'akbank'  => ['api_key' => 'akb_paranette-demo-2026-hackathon-fixed-key'],
    ];

    private function banks(): array
    {
        return [
            [
                'slug'        => 'ziraat',
                'customer_id' => 'ZBK-001-' . self::TCKN,
                'password'    => 'password',
                'credentials' => [],
            ],
            [
                'slug'        => 'garanti',
                'customer_id' => 'GBK-001-' . self::TCKN,
                'password'    => 'password',
                'credentials' => ['client_secret' => 'garanti-demo-secret-2026'],
            ],
            [
                'slug'        => 'isbank',
                'customer_id' => 'ISB-001-' . self::TCKN,
                'password'    => 'password',
                'credentials' => ['hmac_secret' => 'isbank-demo-hmac-key-2026-paranette'],
            ],
            [
                'slug'        => 'akbank',
                'customer_id' => 'AKB-001-' . self::TCKN,
                'password'    => 'password',
                'credentials' => ['api_key' => 'akb_paranette-demo-2026-hackathon-fixed-key'],
            ],
        ];
    }

    private function createCustomer(array $bank): FakeBankCustomer
    {
        return FakeBankCustomer::create([
            'bank_slug'       => $bank['slug'],
            'customer_id'     => $bank['customer_id'],
            'tckn'            => self::TCKN,
            'name'            => self::NAME,
            'email'           => 'demo@paranette.local',
            'password_hash'   => Hash::make($bank['password']),
            'api_credentials' => $bank['credentials'] ?: null,
        ]);
    }

    private function createAccounts(array $bank, FakeBankCustomer $customer): array
    {
        $slug = $bank['slug'];
        $prefix = strtoupper(substr($slug, 0, 3));

        // Vadesiz TL hesabı (maaş hesabı)
        $checking = FakeBankAccount::create([
            'bank_slug'         => $slug,
            'fake_customer_id'  => $customer->id,
            'external_id'       => "{$prefix}-CHK-" . Str::padLeft(rand(10000, 99999), 5, '0'),
            'account_type'      => 'checking',
            'iban'              => $this->generateIban(),
            'currency'          => 'TRY',
            'balance'           => rand(8000, 25000) + rand(0, 99) / 100,
            'available_balance' => rand(7500, 24000) + rand(0, 99) / 100,
            'opened_at'         => Carbon::now()->subYears(rand(2, 6))->format('Y-m-d'),
        ]);

        // Birikimli TL hesabı
        $savings = FakeBankAccount::create([
            'bank_slug'         => $slug,
            'fake_customer_id'  => $customer->id,
            'external_id'       => "{$prefix}-SAV-" . Str::padLeft(rand(10000, 99999), 5, '0'),
            'account_type'      => 'savings',
            'iban'              => $this->generateIban(),
            'currency'          => 'TRY',
            'balance'           => rand(50000, 180000) + rand(0, 99) / 100,
            'available_balance' => rand(50000, 180000) + rand(0, 99) / 100,
            'opened_at'         => Carbon::now()->subYears(rand(1, 4))->format('Y-m-d'),
        ]);

        return [$checking, $savings];
    }

    private function createCards(array $bank, FakeBankCustomer $customer, FakeBankAccount $account): array
    {
        $slug = $bank['slug'];

        // Kredi kartı
        $creditCard = FakeBankCard::create([
            'bank_slug'         => $slug,
            'fake_customer_id'  => $customer->id,
            'fake_account_id'   => $account->id,
            'type'              => 'credit',
            'masked_number'     => $this->maskedCardNumber(),
            'expiry'            => $this->cardExpiry(),
            'holder_name'       => strtoupper(self::NAME),
            'credit_limit'      => 30000.00,
            'current_debt'      => rand(3000, 12000) + rand(0, 99) / 100,
            'statement_day'     => 10,
            'due_day'           => 28,
        ]);

        // Banka kartı (debit)
        $debitCard = FakeBankCard::create([
            'bank_slug'         => $slug,
            'fake_customer_id'  => $customer->id,
            'fake_account_id'   => $account->id,
            'type'              => 'debit',
            'masked_number'     => $this->maskedCardNumber(),
            'expiry'            => $this->cardExpiry(),
            'holder_name'       => strtoupper(self::NAME),
            'credit_limit'      => null,
            'current_debt'      => 0,
            'statement_day'     => null,
            'due_day'           => null,
        ]);

        return [$creditCard, $debitCard];
    }

    private function createLoans(array $bank, FakeBankCustomer $customer): void
    {
        // İhtiyaç kredisi
        FakeBankLoan::create([
            'bank_slug'            => $bank['slug'],
            'fake_customer_id'     => $customer->id,
            'external_id'          => strtoupper($bank['slug']) . '-LN-' . Str::padLeft(rand(10000, 99999), 5, '0'),
            'type'                 => 'personal',
            'principal'            => 100000.00,
            'current_balance'      => rand(40000, 90000) + rand(0, 99) / 100,
            'interest_rate'        => 4.89,
            'total_installments'   => 36,
            'paid_installments'    => rand(6, 20),
            'next_payment_date'    => Carbon::now()->addDays(rand(5, 25))->format('Y-m-d'),
            'next_payment_amount'  => 3850.00,
        ]);
    }

    // ──────────────────────────────────────────────────────────────
    // Transaction generation
    // ──────────────────────────────────────────────────────────────

    private function createTransactions(
        array $bank,
        FakeBankCustomer $customer,
        array $accounts,
        array $cards,
        Carbon $startDate,
        Carbon $endDate
    ): void {
        [$checking, $savings] = $accounts;
        [$creditCard]         = $cards;
        $slug                 = $bank['slug'];

        $current = $startDate->copy();

        while ($current->lte($endDate)) {
            $dom = $current->day;
            $dow = $current->dayOfWeek; // 0=Sun, 6=Sat

            // ── Maaş günü (15): gelen transfer ──────────────────
            if ($dom === 15) {
                $salary = rand(34000, 36500);
                $this->addTx($slug, $checking, null, $current->copy()->setTime(9, rand(0, 30)),
                    +$salary, 'Maaş Ödemesi - İşveren A.Ş.', null, 'transfer');
            }

            // ── Ay başı ödemeleri (1-5) ──────────────────────────
            if ($dom === 1) {
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(10, 11), rand(0, 59)),
                    -8500, 'Kira Ödemesi', 'Ev Sahibi', 'transfer');
            }
            if ($dom === 2) {
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(10, 12), rand(0, 59)),
                    -(rand(350, 420)), 'İnternet Fatura', 'Türk Telekom', 'online');
            }
            if ($dom === 3 && in_array($current->month, [1, 3, 5, 7, 9, 11])) {
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(10, 14), rand(0, 59)),
                    -(rand(500, 900)), 'Elektrik Fatura', 'TEDAŞ', 'online');
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(10, 14), rand(0, 59)),
                    -(rand(300, 650)), 'Doğalgaz Fatura', 'İGDAŞ', 'online');
            }
            if ($dom === 4) {
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(10, 14), rand(0, 59)),
                    -(rand(150, 220)), 'Su Fatura', 'İSKİ', 'online');
            }
            if ($dom === 5) {
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(9, 11), rand(0, 59)),
                    -890, 'Spor Salonu Üyeliği', 'Gym Üyeliği', 'online');
            }

            // ── Kredi kartı ekstret ödemesi (28. gün) ────────────
            if ($dom === 28) {
                $payment = rand(5000, 10000);
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(10, 15), rand(0, 59)),
                    -$payment, 'Kredi Kartı Ekstre Ödemesi', null, 'transfer');
            }

            // ── Abonelikler (sabit günler) ────────────────────────
            if ($dom === 8) {
                $this->addTx($slug, $checking, $creditCard, $current->copy()->setTime(0, 1),
                    -259.00, 'Netflix Abonelik', 'Netflix', 'online');
                $this->addTx($slug, $checking, $creditCard, $current->copy()->setTime(0, 2),
                    -69.99, 'Spotify Premium', 'Spotify', 'online');
            }
            if ($dom === 12) {
                $this->addTx($slug, $checking, $creditCard, $current->copy()->setTime(0, 3),
                    -139.99, 'YouTube Premium', 'YouTube Premium', 'online');
                $this->addTx($slug, $checking, $creditCard, $current->copy()->setTime(0, 4),
                    -39.99, 'iCloud Depolama', 'iCloud 200GB', 'online');
            }

            // ── Kredi taksiti (20. gün) ───────────────────────────
            if ($dom === 20) {
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(9, 11), rand(0, 30)),
                    -3850.00, 'İhtiyaç Kredisi Taksiti', null, 'transfer');
            }

            // ── Günlük alışveriş kalıpları ────────────────────────
            if ($dow >= 1 && $dow <= 5) {
                // Hafta içi
                $this->weekdayTransactions($slug, $checking, $creditCard, $current);
            } else {
                // Hafta sonu
                $this->weekendTransactions($slug, $checking, $creditCard, $current);
            }

            // ── Nakit çekim (haftada ~1 kez, Pazartesi veya Perşembe) ──
            if (in_array($dow, [1, 4]) && rand(1, 7) === 1) {
                $this->addTx($slug, $checking, null, $current->copy()->setTime(rand(12, 18), rand(0, 59)),
                    -(rand(5, 20) * 100), 'ATM Para Çekme', null, 'atm');
            }

            $current->addDay();
        }
    }

    private function weekdayTransactions(
        string $slug,
        FakeBankAccount $account,
        FakeBankCard $card,
        Carbon $date
    ): void {
        // Kahve (her iş günü yüksek ihtimal)
        if (rand(1, 10) <= 7) {
            $cafe = self::CAFES[array_rand(self::CAFES)];
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(8, 9), rand(0, 59)),
                -(rand(55, 150)), 'Kahve', $cafe, 'pos');
        }

        // Öğle yemeği (her iş günü)
        if (rand(1, 10) <= 9) {
            $rest = self::RESTAURANTS[array_rand(self::RESTAURANTS)];
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(12, 13), rand(0, 59)),
                -(rand(150, 380)), 'Öğle Yemeği', $rest, 'pos');
        }

        // Ulaşım (her iş günü)
        if (rand(1, 10) <= 8) {
            $transport = self::TRANSPORT[array_rand(self::TRANSPORT)];
            $this->addTx($slug, $account, null, $date->copy()->setTime(rand(7, 9), rand(0, 59)),
                -(rand(15, 60)), 'Ulaşım', $transport, 'pos');
        }

        // Market (haftada ~3 kez)
        if (rand(1, 5) <= 3) {
            $market = self::GROCERIES[array_rand(self::GROCERIES)];
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(18, 20), rand(0, 59)),
                -(rand(300, 850)), 'Market Alışverişi', $market, 'pos');
        }

        // Online alışveriş (haftada ~1 kez)
        if (rand(1, 5) === 1) {
            $shop = self::ONLINE[array_rand(self::ONLINE)];
            $amount = rand(200, 1500);
            // Zaman zaman taksitli
            $installTotal = rand(1, 3) === 1 ? rand(3, 12) : null;
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(20, 23), rand(0, 59)),
                -$amount, 'Online Alışveriş', $shop, 'online',
                $installTotal ? 1 : null, $installTotal);
        }
    }

    private function weekendTransactions(
        string $slug,
        FakeBankAccount $account,
        FakeBankCard $card,
        Carbon $date
    ): void {
        // Restoran (hafta sonu daha sık ve pahalı)
        if (rand(1, 10) <= 8) {
            $rest = self::RESTAURANTS[array_rand(self::RESTAURANTS)];
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(13, 20), rand(0, 59)),
                -(rand(300, 800)), 'Restoran', $rest, 'pos');
        }

        // Akaryakıt (haftada ~1 kez hafta sonu)
        if (rand(1, 3) === 1) {
            $fuel = self::FUEL[array_rand(self::FUEL)];
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(10, 16), rand(0, 59)),
                -(rand(1000, 2200)), 'Benzin / Motorin', $fuel, 'pos');
        }

        // AVM / eğlence
        if (rand(1, 4) === 1) {
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(14, 18), rand(0, 59)),
                -(rand(300, 1200)), 'AVM Alışveriş', 'Cevahir AVM', 'pos');
        }

        // Büyük market alışverişi (hafta sonu büyük alış)
        if (rand(1, 3) <= 2) {
            $market = self::GROCERIES[array_rand(self::GROCERIES)];
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(11, 14), rand(0, 59)),
                -(rand(600, 1800)), 'Haftalık Market', $market, 'pos');
        }

        // Kahve (hafta sonu daha rahat)
        if (rand(1, 10) <= 6) {
            $cafe = self::CAFES[array_rand(self::CAFES)];
            $this->addTx($slug, $account, $card, $date->copy()->setTime(rand(10, 17), rand(0, 59)),
                -(rand(100, 250)), 'Kafe', $cafe, 'pos');
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────

    private function addTx(
        string $slug,
        FakeBankAccount $account,
        ?FakeBankCard $card,
        Carbon $postedAt,
        float $amount,
        string $description,
        ?string $merchant,
        string $channel,
        ?int $installmentNo = null,
        ?int $installmentTotal = null
    ): void {
        FakeBankTransaction::create([
            'bank_slug'         => $slug,
            'fake_account_id'   => $account->id,
            'fake_card_id'      => $card?->id,
            'external_id'       => strtoupper(substr($slug, 0, 3)) . '-TX-' . Str::random(24),
            'posted_at'         => $postedAt->format('Y-m-d H:i:s'),
            'amount'            => $amount,
            'currency'          => 'TRY',
            'description'       => $description,
            'merchant_name'     => $merchant,
            'channel'           => $channel,
            'installment_no'    => $installmentNo,
            'installment_total' => $installmentTotal,
        ]);
    }

    private function generateIban(): string
    {
        $bban = Str::padLeft(rand(0, 99999999999999999), 17, '0');
        return 'TR' . Str::padLeft(rand(0, 99), 2, '0') . '0001' . $bban;
    }

    private function maskedCardNumber(): string
    {
        return '**** **** **** ' . Str::padLeft(rand(1000, 9999), 4, '0');
    }

    private function cardExpiry(): string
    {
        $month = Str::padLeft(rand(1, 12), 2, '0');
        $year  = date('Y') + rand(1, 5);
        return "{$month}/{$year}";
    }
}
