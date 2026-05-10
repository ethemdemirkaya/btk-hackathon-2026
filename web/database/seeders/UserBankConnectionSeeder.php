<?php

namespace Database\Seeders;

use App\Models\Account;
use App\Models\BankConnection;
use App\Models\Card;
use App\Models\Loan;
use App\Models\Transaction;
use App\Models\User;
use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCard;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankLoan;
use App\Models\FakeBank\FakeBankTransaction;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Populates real financial tables for the demo user directly from
 * the fake bank tables — no HTTP calls, no queue, works offline.
 *
 * Run after FakeBankSeeder and DatabaseSeeder (demo user must exist).
 */
class UserBankConnectionSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'demo@paranette.local')->first();

        if (! $user) {
            $this->command->warn('Demo user not found — run DatabaseSeeder first.');
            return;
        }

        // Clear previous connections for this user so re-seeding is idempotent
        BankConnection::where('user_id', $user->id)->forceDelete();

        $banks = DB::table('banks')->whereIn('slug', ['ziraat', 'garanti', 'isbank', 'akbank'])->get()->keyBy('slug');

        foreach (FakeBankSeeder::CREDENTIALS as $slug => $credentials) {
            $bank = $banks->get($slug);
            if (! $bank) {
                $this->command->warn("Bank not found: {$slug}");
                continue;
            }

            $customer = FakeBankCustomer::where('bank_slug', $slug)
                ->where('tckn', '12345678901')
                ->first();

            if (! $customer) {
                $this->command->warn("FakeBankCustomer not found for {$slug}");
                continue;
            }

            // ── Create BankConnection ─────────────────────────────
            $conn = new BankConnection([
                'user_id'      => $user->id,
                'bank_id'      => $bank->id,
                'last_sync_at' => now(),
                'status'       => 'active',
            ]);
            $conn->setCredentials($credentials);
            $conn->save();

            // ── Accounts ──────────────────────────────────────────
            $fakeAccounts = FakeBankAccount::where('fake_customer_id', $customer->id)->get();
            $accountMap   = []; // fake_account.id => Account model

            foreach ($fakeAccounts as $fa) {
                $account = Account::create([
                    'bank_connection_id' => $conn->id,
                    'user_id'            => $user->id,
                    'external_id'        => $fa->external_id,
                    'account_type'       => $fa->account_type,
                    'iban'               => $fa->iban,
                    'currency'           => $fa->currency,
                    'balance'            => $fa->balance,
                    'available_balance'  => $fa->available_balance,
                ]);

                $accountMap[$fa->id] = $account;
            }

            // ── Cards ─────────────────────────────────────────────
            $fakeCards = FakeBankCard::where('fake_customer_id', $customer->id)->get();
            $cardMap   = []; // fake_card.id => Card model
            $firstAcct = array_values($accountMap)[0] ?? null;

            foreach ($fakeCards as $fc) {
                [$expMonth, $expYear] = $this->parseExpiry($fc->expiry ?? '12/2028');

                $card = Card::create([
                    'user_id'         => $user->id,
                    'account_id'      => $firstAcct?->id,
                    'type'            => $fc->type ?? 'credit',
                    'masked_number'   => $fc->masked_number,
                    'expiry_month'    => $expMonth,
                    'expiry_year'     => $expYear,
                    'holder_name'     => $fc->holder_name ?? $user->name,
                    'credit_limit'    => $fc->credit_limit ?? 0,
                    'current_debt'    => $fc->current_debt ?? 0,
                    'available_limit' => $fc->credit_limit - $fc->current_debt ?? 0,
                    'statement_day'   => $fc->statement_day ?? 1,
                    'due_day'         => $fc->due_day ?? 10,
                ]);

                $cardMap[$fc->id] = $card;
            }

            // ── Loans ─────────────────────────────────────────────
            $fakeLoans = FakeBankLoan::where('fake_customer_id', $customer->id)->get();

            foreach ($fakeLoans as $fl) {
                Loan::create([
                    'bank_connection_id'  => $conn->id,
                    'user_id'             => $user->id,
                    'external_id'         => $fl->external_id,
                    'type'                => $fl->type ?? 'personal',
                    'principal'           => $fl->principal,
                    'current_balance'     => $fl->current_balance,
                    'interest_rate'       => $fl->interest_rate,
                    'total_installments'  => $fl->total_installments,
                    'paid_installments'   => $fl->paid_installments,
                    'next_payment_date'   => $fl->next_payment_date,
                    'next_payment_amount' => $fl->next_payment_amount,
                ]);
            }

            // ── Transactions ──────────────────────────────────────
            $fakeAccountIds = $fakeAccounts->pluck('id')->toArray();

            FakeBankTransaction::whereIn('fake_account_id', $fakeAccountIds)
                ->orderBy('posted_at')
                ->each(function (FakeBankTransaction $ft) use ($accountMap, $cardMap) {
                    $account = $accountMap[$ft->fake_account_id] ?? null;
                    $card    = $ft->fake_card_id ? ($cardMap[$ft->fake_card_id] ?? null) : null;

                    if (! $account) {
                        return;
                    }

                    Transaction::create([
                        'id'                => Str::uuid()->toString(),
                        'account_id'        => $account->id,
                        'card_id'           => $card?->id,
                        'external_id'       => $ft->external_id,
                        'posted_at'         => $ft->posted_at,
                        'amount'            => $ft->amount,
                        'currency'          => $ft->currency ?? 'TRY',
                        'try_amount'        => $ft->amount,
                        'description'       => $ft->description,
                        'raw_description'   => $ft->description,
                        'merchant_name'     => $ft->merchant_name,
                        'channel'           => $ft->channel ?? 'pos',
                        'installment_no'    => $ft->installment_no,
                        'installment_total' => $ft->installment_total,
                    ]);
                });

            $this->command->info("✓ {$slug}: {$fakeAccounts->count()} hesap, {$fakeCards->count()} kart, {$fakeLoans->count()} kredi bağlandı.");
        }

        $this->command->info("Demo user banka bağlantıları tamamlandı.");
    }

    private function parseExpiry(string $expiry): array
    {
        if (str_contains($expiry, '/')) {
            [$m, $y] = explode('/', $expiry);
            return [(int) $m, (int) $y];
        }
        return [12, 2028];
    }
}
