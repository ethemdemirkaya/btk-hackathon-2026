<?php

namespace App\Jobs;

use App\Models\Account;
use App\Models\BankConnection;
use App\Models\Card;
use App\Models\Loan;
use App\Models\Transaction;
use App\Services\BankConnector\BankConnectorFactory;
use Carbon\Carbon;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class SyncBankConnectionJob implements ShouldQueue
{
    use Queueable, InteractsWithQueue, SerializesModels;

    public int $tries   = 3;
    public int $timeout = 120;

    public function __construct(public readonly BankConnection $connection)
    {
    }

    public function handle(): void
    {
        $connection = $this->connection;
        $connection->load('bank');

        $connector = BankConnectorFactory::make($connection);
        $from      = $connection->last_sync_at
            ? $connection->last_sync_at->subHours(1) // overlap to avoid missing txns
            : Carbon::now()->subMonths(6);

        try {
            // ── Accounts ──────────────────────────────────────────
            $rawAccounts = $connector->fetchAccounts();
            $accountMap  = []; // external_id => App\Models\Account

            foreach ($rawAccounts as $data) {
                $account = Account::updateOrCreate(
                    ['bank_connection_id' => $connection->id, 'external_id' => $data['external_id']],
                    [
                        'user_id'           => $connection->user_id,
                        'account_type'      => $data['account_type'],
                        'iban'              => $data['iban'],
                        'currency'          => $data['currency'],
                        'balance'           => $data['balance'],
                        'available_balance' => $data['available_balance'],
                    ]
                );

                $accountMap[$data['external_id']] = $account;
            }

            // ── Transactions ────────────────────────────────────────
            foreach ($accountMap as $externalId => $account) {
                $rawTxns = $connector->fetchTransactions($externalId, $from);

                foreach ($rawTxns as $t) {
                    Transaction::updateOrCreate(
                        ['account_id' => $account->id, 'external_id' => $t['external_id']],
                        [
                            'posted_at'         => $t['posted_at'],
                            'amount'            => $t['amount'],
                            'currency'          => $t['currency'],
                            'try_amount'        => $t['amount'], // FX conversion handled separately
                            'description'       => $t['description'],
                            'raw_description'   => $t['description'],
                            'merchant_name'     => $t['merchant_name'],
                            'channel'           => $t['channel'],
                            'installment_no'    => $t['installment_no'],
                            'installment_total' => $t['installment_total'],
                        ]
                    );
                }
            }

            // ── Cards ───────────────────────────────────────────────
            $rawCards  = $connector->fetchCards();
            $firstAcct = array_values($accountMap)[0] ?? null;

            foreach ($rawCards as $c) {
                Card::updateOrCreate(
                    [
                        'user_id'       => $connection->user_id,
                        'masked_number' => $c['masked_number'],
                        'expiry_month'  => $c['expiry_month'],
                        'expiry_year'   => $c['expiry_year'],
                    ],
                    [
                        'account_id'     => $firstAcct?->id,
                        'type'           => $c['type'],
                        'holder_name'    => $c['holder_name'],
                        'credit_limit'   => $c['credit_limit'],
                        'current_debt'   => $c['current_debt'],
                        'available_limit'=> $c['available_limit'],
                        'statement_day'  => $c['statement_day'],
                        'due_day'        => $c['due_day'],
                    ]
                );
            }

            // ── Loans ───────────────────────────────────────────────
            $rawLoans = $connector->fetchLoans();

            foreach ($rawLoans as $l) {
                Loan::updateOrCreate(
                    ['bank_connection_id' => $connection->id, 'external_id' => $l['external_id']],
                    [
                        'user_id'              => $connection->user_id,
                        'type'                 => $l['type'],
                        'principal'            => $l['principal'],
                        'current_balance'      => $l['current_balance'],
                        'interest_rate'        => $l['interest_rate'],
                        'total_installments'   => $l['total_installments'],
                        'paid_installments'    => $l['paid_installments'],
                        'next_payment_date'    => $l['next_payment_date'],
                        'next_payment_amount'  => $l['next_payment_amount'],
                    ]
                );
            }

            $connection->update([
                'last_sync_at' => now(),
                'status'       => 'active',
            ]);

            CalculateHealthScoreJob::dispatch($connection->user)
                ->delay(now()->addSeconds(5));

        } catch (Throwable $e) {
            $connection->update(['status' => 'error']);
            throw $e;
        }
    }

    public function failed(Throwable $e): void
    {
        $this->connection->update(['status' => 'error']);
    }
}
