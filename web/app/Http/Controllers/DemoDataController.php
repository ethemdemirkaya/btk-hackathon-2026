<?php

namespace App\Http\Controllers;

use App\Models\Bank;
use App\Models\BankConnection;
use App\Models\Account;
use App\Models\Card;
use App\Models\Loan;
use App\Models\Goal;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\View\View;

class DemoDataController extends Controller
{
    /** Desteklenen demo bankaları */
    private const BANK_SLUGS = ['ziraat', 'garanti', 'isbank', 'akbank'];

    /** Her banka için insan okunabilir isim */
    private const BANK_NAMES = [
        'ziraat'  => 'Ziraat Bankası',
        'garanti' => 'Garanti BBVA',
        'isbank'  => 'İş Bankası',
        'akbank'  => 'Akbank',
    ];

    /** Kategori ve işlem şablonları */
    private const EXPENSE_TEMPLATES = [
        ['desc' => 'Migros Market',       'merchant' => 'Migros',         'cat' => 'market',      'min' => 120,  'max' => 850],
        ['desc' => 'CarrefourSA',          'merchant' => 'CarrefourSA',    'cat' => 'market',      'min' => 80,   'max' => 600],
        ['desc' => 'Akaryakıt / Shell',    'merchant' => 'Shell',          'cat' => 'ulasim',      'min' => 400,  'max' => 1200],
        ['desc' => 'Akaryakıt / BP',       'merchant' => 'BP',             'cat' => 'ulasim',      'min' => 300,  'max' => 1100],
        ['desc' => 'Elektrik Faturası',    'merchant' => 'TEDAŞ',          'cat' => 'fatura',      'min' => 350,  'max' => 900],
        ['desc' => 'Doğalgaz Faturası',    'merchant' => 'IGDAŞ',          'cat' => 'fatura',      'min' => 200,  'max' => 700],
        ['desc' => 'Netflix Abonelik',     'merchant' => 'Netflix',        'cat' => 'abonelik',    'min' => 169,  'max' => 169],
        ['desc' => 'Spotify Premium',      'merchant' => 'Spotify',        'cat' => 'abonelik',    'min' => 69,   'max' => 69],
        ['desc' => 'Yemeksepeti Sipariş',  'merchant' => 'Yemeksepeti',    'cat' => 'restoran',    'min' => 150,  'max' => 480],
        ['desc' => 'Getir Market',         'merchant' => 'Getir',          'cat' => 'market',      'min' => 60,   'max' => 280],
        ['desc' => 'Trendyol Alışveriş',   'merchant' => 'Trendyol',       'cat' => 'alisveris',   'min' => 200,  'max' => 1800],
        ['desc' => 'Hepsiburada.com',      'merchant' => 'Hepsiburada',    'cat' => 'alisveris',   'min' => 150,  'max' => 2500],
        ['desc' => 'Eczane Alışveriş',     'merchant' => 'Eczane',         'cat' => 'saglik',      'min' => 80,   'max' => 400],
        ['desc' => 'Diş Kliniği',          'merchant' => 'Diş Kliniği',    'cat' => 'saglik',      'min' => 500,  'max' => 3000],
        ['desc' => 'Kafe / Kahve',         'merchant' => 'Starbucks',      'cat' => 'restoran',    'min' => 80,   'max' => 220],
        ['desc' => 'Restoran',             'merchant' => 'Restoran',       'cat' => 'restoran',    'min' => 200,  'max' => 800],
        ['desc' => 'İnternet Faturası',    'merchant' => 'Turk Telekom',   'cat' => 'fatura',      'min' => 200,  'max' => 500],
        ['desc' => 'Telefon Faturası',     'merchant' => 'Turkcell',       'cat' => 'fatura',      'min' => 150,  'max' => 450],
        ['desc' => 'Sinema / Eğlence',     'merchant' => 'Cinemaximum',    'cat' => 'eglence',     'min' => 100,  'max' => 350],
        ['desc' => 'ATM Nakit Çekim',      'merchant' => null,             'cat' => 'diger',       'min' => 500,  'max' => 2000],
    ];

    private const INCOME_TEMPLATES = [
        ['desc' => 'Maaş Ödemesi',       'merchant' => null, 'min' => 0, 'max' => 0],  // salary — amount set dynamically
        ['desc' => 'Freelance Geliri',   'merchant' => null, 'min' => 1000, 'max' => 5000],
        ['desc' => 'Kira Geliri',        'merchant' => null, 'min' => 3000, 'max' => 8000],
        ['desc' => 'Faiz Geliri',        'merchant' => null, 'min' => 100,  'max' => 800],
    ];

    /** Kişisel borç/alacak hareketi şablonları — AI tespiti için gerçekçi veriler */
    private const PERSONAL_DEBT_TEMPLATES = [
        // Ben verdim (negatif tutar)
        ['desc' => "Ahmet'e borç verdim",          'sign' => -1, 'min' => 300,  'max' => 2500],
        ['desc' => "Can'a ödünç para",              'sign' => -1, 'min' => 500,  'max' => 3000],
        ['desc' => "Burak için borç attım",         'sign' => -1, 'min' => 200,  'max' => 1500],
        ['desc' => "Selin'e kira için borç verdim", 'sign' => -1, 'min' => 1000, 'max' => 5000],
        ['desc' => "Ali borç istedi",               'sign' => -1, 'min' => 150,  'max' => 1200],
        // Ben aldım (pozitif tutar)
        ['desc' => "Zeynep'ten ödünç aldım",        'sign' =>  1, 'min' => 200,  'max' => 2000],
        ['desc' => "Fatma borcumu ödedi",            'sign' =>  1, 'min' => 300,  'max' => 1800],
        // Geri ödeme (pozitif tutar — repayment detection için)
        ['desc' => "Ahmet borcunu geri verdi",       'sign' =>  1, 'min' => 300,  'max' => 2500],
        ['desc' => "Can geri ödeme yaptı",           'sign' =>  1, 'min' => 500,  'max' => 3000],
        ['desc' => "Burak borç iadesi",              'sign' =>  1, 'min' => 200,  'max' => 1500],
    ];

    public function index(): View
    {
        $existingConnections = BankConnection::with(['bank', 'accounts'])
            ->where('user_id', auth()->id())
            ->whereNotNull('encrypted_credentials')
            ->latest()
            ->get()
            ->filter(function ($conn) {
                $creds = $conn->getCredentials();
                return isset($creds['demo']) && $creds['demo'] === true;
            });

        return view('demo-data.index', [
            'bankSlugs'           => self::BANK_SLUGS,
            'bankNames'           => self::BANK_NAMES,
            'existingConnections' => $existingConnections,
        ]);
    }

    public function generate(Request $request)
    {
        $request->validate([
            'full_name'    => ['required', 'string', 'min:2', 'max:80'],
            'banks'        => ['required', 'array', 'min:1'],
            'banks.*'      => ['in:ziraat,garanti,isbank,akbank'],
            'monthly_income' => ['nullable', 'numeric', 'min:1000', 'max:500000'],
            'months_back'  => ['nullable', 'integer', 'min:1', 'max:12'],
            'tx_per_month' => ['nullable', 'integer', 'min:5', 'max:60'],
        ]);

        $userId      = auth()->id();
        $fullName    = trim($request->input('full_name'));
        $banks       = $request->input('banks', []);
        $monthlyIncome = (float) ($request->input('monthly_income', rand(15000, 45000)));
        $monthsBack  = (int) ($request->input('months_back', 3));
        $txPerMonth  = (int) ($request->input('tx_per_month', 20));

        $nameSlug = Str::slug($fullName, '_');

        $createdConnections = [];

        DB::transaction(function () use (
            $userId, $fullName, $banks, $monthlyIncome,
            $monthsBack, $txPerMonth, $nameSlug, &$createdConnections
        ) {
            foreach ($banks as $bankSlug) {
                $bank = Bank::where('slug', $bankSlug)->first();
                if (! $bank) {
                    continue;
                }

                $rndSuffix  = strtolower(Str::random(4));
                $username   = "{$nameSlug}_{$rndSuffix}";
                $password   = 'Demo1234!';
                $oauthToken = "demo_tkn_{$bankSlug}_" . strtolower(Str::random(8));

                $credentials = [
                    'demo'        => true,
                    'username'    => $username,
                    'password'    => $password,
                    'oauth_token' => $oauthToken,
                    'full_name'   => $fullName,
                ];

                /** @var BankConnection $conn */
                $conn = BankConnection::create([
                    'user_id'               => $userId,
                    'bank_id'               => $bank->id,
                    'encrypted_credentials' => Crypt::encryptString(json_encode($credentials)),
                    'status'                => 'active',
                    'last_sync_at'          => now(),
                ]);

                // Checking hesabı
                $checkingBalance   = (float) rand(5000, 30000) + round(rand(0, 99) / 100, 2);
                $checkingAccount   = Account::create([
                    'user_id'            => $userId,
                    'bank_connection_id' => $conn->id,
                    'external_id'        => 'demo_chk_' . Str::random(8),
                    'account_type'       => 'checking',
                    'iban'               => $this->generateFakeIban(),
                    'currency'           => 'TRY',
                    'balance'            => $checkingBalance,
                    'available_balance'  => $checkingBalance * 0.95,
                    'nickname'           => self::BANK_NAMES[$bankSlug] . ' Vadesiz',
                ]);

                // Savings hesabı
                $savingsBalance  = (float) rand(2000, 15000) + round(rand(0, 99) / 100, 2);
                $savingsAccount  = Account::create([
                    'user_id'            => $userId,
                    'bank_connection_id' => $conn->id,
                    'external_id'        => 'demo_sav_' . Str::random(8),
                    'account_type'       => 'savings',
                    'iban'               => $this->generateFakeIban(),
                    'currency'           => 'TRY',
                    'balance'            => $savingsBalance,
                    'available_balance'  => $savingsBalance,
                    'nickname'           => self::BANK_NAMES[$bankSlug] . ' Birikimli',
                ]);

                // İşlemler oluştur (checking hesabı üzerinden)
                $this->generateTransactions($checkingAccount, $monthlyIncome, $monthsBack, $txPerMonth);
                $this->generatePersonalDebtTransactions($checkingAccount, $monthsBack);

                // Kredi kartı
                $cardLimit = (float) (rand(5, 30) * 1000);
                $cardDebt  = round($cardLimit * (rand(10, 60) / 100), 2);
                Card::create([
                    'user_id'        => $userId,
                    'account_id'     => $checkingAccount->id,
                    'type'           => 'credit',
                    'masked_number'  => '**** **** **** ' . rand(1000, 9999),
                    'expiry_month'   => rand(1, 12),
                    'expiry_year'    => now()->year + rand(1, 5),
                    'holder_name'    => strtoupper($fullName),
                    'credit_limit'   => $cardLimit,
                    'current_debt'   => $cardDebt,
                    'available_limit'=> $cardLimit - $cardDebt,
                    'statement_day'  => rand(1, 28),
                    'due_day'        => rand(1, 28),
                ]);

                // Kredi (50% şans)
                if (rand(0, 1) === 1) {
                    $principal    = (float) (rand(20, 200) * 1000);
                    $totalInst    = rand(12, 60);
                    $paidInst     = rand(1, $totalInst - 1);
                    $currentBal   = $principal * (1 - $paidInst / $totalInst);
                    Loan::create([
                        'user_id'             => $userId,
                        'bank_connection_id'  => $conn->id,
                        'external_id'         => 'demo_loan_' . Str::random(6),
                        'type'                => ['personal', 'vehicle', 'mortgage'][rand(0, 2)],
                        'principal'           => $principal,
                        'current_balance'     => round($currentBal, 2),
                        'interest_rate'       => round(rand(25, 55) + rand(0, 99) / 100, 4),
                        'total_installments'  => $totalInst,
                        'paid_installments'   => $paidInst,
                        'next_payment_date'   => now()->addDays(rand(1, 30))->toDateString(),
                        'next_payment_amount' => round($principal / $totalInst * 1.3, 2),
                        'started_at'          => now()->subMonths($paidInst)->toDateString(),
                        'ends_at'             => now()->addMonths($totalInst - $paidInst)->toDateString(),
                    ]);
                }

                $createdConnections[] = [
                    'bank_name'      => self::BANK_NAMES[$bankSlug],
                    'bank_slug'      => $bankSlug,
                    'username'       => $username,
                    'password'       => $password,
                    'oauth_token'    => $oauthToken,
                    'checking_bal'   => $checkingBalance,
                    'savings_bal'    => $savingsBalance,
                ];
            }

            // Demo hedef ekle
            $this->ensureDemoGoals($userId);

            // Demo bütçe ekle
            $this->ensureDemoBudgets($userId);
        });

        return redirect()
            ->route('demo-data.index')
            ->with('success', 'Demo veriler başarıyla oluşturuldu!')
            ->with('created', $createdConnections);
    }

    public function clear(Request $request)
    {
        $userId = auth()->id();

        $demoConnectionIds = BankConnection::where('user_id', $userId)
            ->get()
            ->filter(function ($conn) {
                $creds = $conn->getCredentials();
                return isset($creds['demo']) && $creds['demo'] === true;
            })
            ->pluck('id');

        if ($demoConnectionIds->isEmpty()) {
            return redirect()->route('demo-data.index')->with('info', 'Silinecek demo veri bulunamadı.');
        }

        DB::transaction(function () use ($demoConnectionIds) {
            // İşlemler — account_id üzerinden
            $accountIds = Account::whereIn('bank_connection_id', $demoConnectionIds)->pluck('id');
            Transaction::whereIn('account_id', $accountIds)->delete();

            // Kartlar
            Card::whereIn('account_id', $accountIds)->delete();

            // Krediler
            Loan::whereIn('bank_connection_id', $demoConnectionIds)->delete();

            // Hesaplar
            Account::whereIn('bank_connection_id', $demoConnectionIds)->delete();

            // Bağlantılar
            BankConnection::whereIn('id', $demoConnectionIds)->delete();
        });

        return redirect()->route('demo-data.index')->with('success', 'Tüm demo veriler silindi.');
    }

    // ── Yardımcı metotlar ───────────────────────────────────────────────────

    private function generateTransactions(Account $account, float $monthlyIncome, int $monthsBack, int $txPerMonth): void
    {
        $now = Carbon::now();

        // Merchant-category slug → Category ID lookup (cached for this call)
        $categoryCache = [];
        $resolveCategoryId = function (string $slug) use (&$categoryCache): ?int {
            if (! array_key_exists($slug, $categoryCache)) {
                $cat = \App\Models\Category::where('slug', $slug)->first();
                $categoryCache[$slug] = $cat ? $cat->id : null;
            }
            return $categoryCache[$slug];
        };

        // Map expense template 'cat' slugs to canonical category slugs in the DB
        $catSlugMap = [
            'market'    => 'market',
            'ulasim'    => 'ulasim',
            'fatura'    => 'faturalar',
            'abonelik'  => 'dijital-abonelik',
            'restoran'  => 'restoran-kafe',
            'alisveris' => 'elektronik',
            'saglik'    => 'saglik',
            'eglence'   => 'eglence',
            'diger'     => 'diger',
        ];

        for ($m = $monthsBack; $m >= 0; $m--) {
            $monthStart = $now->copy()->subMonths($m)->startOfMonth();
            $monthEnd   = $m === 0 ? $now->copy() : $now->copy()->subMonths($m)->endOfMonth();

            // Maaş geliri (her ay 1-5'i arası)
            $salaryDay = $monthStart->copy()->addDays(rand(0, 4));
            if ($salaryDay->lte($monthEnd)) {
                Transaction::create([
                    'id'              => (string) Str::uuid(),
                    'account_id'      => $account->id,
                    'external_id'     => 'demo_' . Str::random(12),
                    'posted_at'       => $salaryDay,
                    'amount'          => $monthlyIncome,
                    'currency'        => 'TRY',
                    'try_amount'      => $monthlyIncome,
                    'description'     => 'Maaş Ödemesi',
                    'merchant_name'   => null,
                    'channel'         => 'transfer',
                    'is_recurring'    => true,
                ]);
            }

            // Gider işlemleri
            $count = rand((int)($txPerMonth * 0.7), (int)($txPerMonth * 1.3));
            for ($i = 0; $i < $count; $i++) {
                $template   = self::EXPENSE_TEMPLATES[array_rand(self::EXPENSE_TEMPLATES)];
                $amount     = -(rand($template['min'] * 100, $template['max'] * 100) / 100);
                $dbSlug     = $catSlugMap[$template['cat']] ?? $template['cat'];
                $categoryId = $resolveCategoryId($dbSlug);

                $dayOffset = rand(0, (int) $monthStart->copy()->diffInDays($monthEnd));
                $txDate    = $monthStart->copy()->addDays($dayOffset);

                Transaction::create([
                    'id'               => (string) Str::uuid(),
                    'account_id'       => $account->id,
                    'external_id'      => 'demo_' . Str::random(12),
                    'posted_at'        => $txDate,
                    'amount'           => $amount,
                    'currency'         => 'TRY',
                    'try_amount'       => $amount,
                    'description'      => $template['desc'],
                    'merchant_name'    => $template['merchant'],
                    'merchant_category'=> $template['cat'],
                    'category_id'      => $categoryId,
                    'channel'          => in_array($template['cat'], ['ulasim', 'diger']) ? 'atm' : 'pos',
                    'is_recurring'     => in_array($template['cat'], ['fatura', 'abonelik']),
                ]);
            }
        }
    }

    private function ensureDemoGoals(int $userId): void
    {
        if (Goal::where('user_id', $userId)->count() > 0) {
            return;
        }

        $goals = [
            ['name' => 'Tatil Fonu',         'target' => 25000,  'current' => rand(2000, 8000)],
            ['name' => 'Acil Durum Fonu',     'target' => 60000,  'current' => rand(5000, 20000)],
            ['name' => 'Yeni Bilgisayar',     'target' => 15000,  'current' => rand(1000, 10000)],
        ];

        foreach ($goals as $g) {
            Goal::create([
                'user_id'       => $userId,
                'name'          => $g['name'],
                'target_amount' => $g['target'],
                'current_amount'=> $g['current'],
                'target_date'   => now()->addMonths(rand(3, 18))->toDateString(),
                'monthly_contribution' => round($g['target'] / 24, 2),
                'status'        => 'active',
            ]);
        }
    }

    private function ensureDemoBudgets(int $userId): void
    {
        $period = now()->format('Y-m');

        // Yaygın kategori slug'larını dene
        $categoryMap = [
            'market'       => ['Market', 'Gıda', 'Supermarket'],
            'restoran-kafe'=> ['Restoran & Kafe', 'Yeme & İçme', 'Restoran', 'Lokanta'],
            'ulasim'       => ['Ulaşım', 'Yakıt', 'Transport'],
            'eglence'      => ['Eğlence', 'Etkinlik'],
        ];

        foreach ($categoryMap as $slugHint => $names) {
            $category = Category::where('slug', $slugHint)
                ->orWhereIn('name', $names)
                ->first();
            if (! $category) {
                continue;
            }

            // Unique constraint: user_id + category_id + period
            $exists = Budget::where('user_id', $userId)
                ->where('category_id', $category->id)
                ->where('period', $period)
                ->exists();

            if ($exists) {
                continue;
            }

            Budget::create([
                'user_id'          => $userId,
                'category_id'      => $category->id,
                'period'           => $period,
                'amount'           => (float) (rand(15, 60) * 100),
                'alert_threshold'  => 80,
            ]);
        }
    }

    /**
     * Son monthsBack ay içine 3-5 adet kişisel borç/geri-ödeme işlemi ekler.
     * Bu işlemler DebtDetectionService'in anahtar kelime taramasına yakalanır.
     */
    private function generatePersonalDebtTransactions(Account $account, int $monthsBack): void
    {
        $now        = Carbon::now();
        $templates  = self::PERSONAL_DEBT_TEMPLATES;
        $count      = rand(3, 5);
        $used       = [];

        shuffle($templates);

        for ($i = 0; $i < $count; $i++) {
            $tpl    = $templates[$i % count($templates)];
            $amount = $tpl['sign'] * (rand($tpl['min'] * 100, $tpl['max'] * 100) / 100);

            // Geçmiş aylara rastgele dağıt
            $daysBack = rand(1, $monthsBack * 30);
            $txDate   = $now->copy()->subDays($daysBack);

            Transaction::create([
                'id'            => (string) Str::uuid(),
                'account_id'    => $account->id,
                'external_id'   => 'demo_debt_' . Str::random(10),
                'posted_at'     => $txDate,
                'amount'        => $amount,
                'currency'      => 'TRY',
                'try_amount'    => $amount,
                'description'   => $tpl['desc'],
                'merchant_name' => null,
                'channel'       => 'transfer',
                'is_recurring'  => false,
            ]);
        }
    }

    private function generateFakeIban(): string
    {
        return 'TR' . rand(10, 99) . ' ' .
            implode(' ', array_map(fn () => rand(1000, 9999), range(1, 6)));
    }
}
