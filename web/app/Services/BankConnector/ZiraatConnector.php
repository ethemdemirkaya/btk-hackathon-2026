<?php

namespace App\Services\BankConnector;

use Carbon\Carbon;
use Illuminate\Support\Facades\Http;

/**
 * Ziraat Bankası — REST + Bearer Token
 * Credentials: { tckn, password }
 */
class ZiraatConnector extends AbstractBankConnector
{
    private ?string $token = null;

    public function fetchAccounts(): array
    {
        $token    = $this->authenticate();
        $response = $this->http()->withToken($token)
            ->get($this->apiUrl('accounts'));

        $response->throw();

        return collect($response->json('accounts', []))->map(fn ($a) => [
            'external_id'       => $a['id'],
            'account_type'      => $a['account_type'],
            'iban'              => $a['iban'] ?? null,
            'currency'          => $a['currency'],
            'balance'           => (float) $a['balance'],
            'available_balance' => (float) $a['available_balance'],
        ])->all();
    }

    public function fetchTransactions(string $externalAccountId, Carbon $from): array
    {
        $token       = $this->authenticate();
        $transactions = [];
        $page        = 1;

        do {
            $response = $this->http()->withToken($token)
                ->get($this->apiUrl("accounts/{$externalAccountId}/transactions"), [
                    'page'     => $page,
                    'per_page' => 100,
                    'from'     => $from->format('Y-m-d'),
                ]);

            $response->throw();

            $data      = $response->json();
            $items     = $data['transactions'] ?? [];
            $lastPage  = $data['pagination']['last_page'] ?? 1;

            foreach ($items as $t) {
                $transactions[] = $this->normalizeTransaction($t);
            }

            $page++;
        } while ($page <= $lastPage);

        return $transactions;
    }

    public function fetchCards(): array
    {
        $token    = $this->authenticate();
        $response = $this->http()->withToken($token)
            ->get($this->apiUrl('cards'));

        $response->throw();

        return collect($response->json('cards', []))->map(fn ($c) => [
            'type'           => $c['type'],
            'masked_number'  => $c['masked_number'],
            'expiry_month'   => (int) explode('/', $c['expiry'])[0],
            'expiry_year'    => (int) explode('/', $c['expiry'])[1],
            'holder_name'    => $c['holder_name'],
            'credit_limit'   => isset($c['credit_limit']) ? (float) $c['credit_limit'] : null,
            'current_debt'   => (float) ($c['current_debt'] ?? 0),
            'available_limit'=> isset($c['credit_limit'], $c['current_debt'])
                ? (float) $c['credit_limit'] - (float) $c['current_debt']
                : null,
            'statement_day'  => $c['statement_day'] ?? null,
            'due_day'        => $c['due_day'] ?? null,
        ])->all();
    }

    public function fetchLoans(): array
    {
        $token    = $this->authenticate();
        $response = $this->http()->withToken($token)
            ->get($this->apiUrl('loans'));

        $response->throw();

        return collect($response->json('loans', []))->map(fn ($l) => [
            'external_id'          => $l['id'],
            'type'                 => $l['type'],
            'principal'            => (float) $l['principal'],
            'current_balance'      => (float) $l['current_balance'],
            'interest_rate'        => (float) $l['interest_rate'],
            'total_installments'   => (int) $l['total_installments'],
            'paid_installments'    => (int) $l['paid_installments'],
            'next_payment_date'    => $l['next_payment_date'] ?? null,
            'next_payment_amount'  => isset($l['next_payment_amount']) ? (float) $l['next_payment_amount'] : null,
        ])->all();
    }

    private function authenticate(): string
    {
        if ($this->token) {
            return $this->token;
        }

        $response = Http::post($this->apiUrl('auth/login'), [
            'tckn'     => $this->credentials['tckn'],
            'password' => $this->credentials['password'],
        ]);

        $response->throw();

        $this->token = $response->json('token');

        return $this->token;
    }

    private function normalizeTransaction(array $t): array
    {
        return [
            'external_id'       => $t['id'],
            'posted_at'         => $t['posted_at'],
            'amount'            => (float) $t['amount'],
            'currency'          => $t['currency'],
            'description'       => $t['description'],
            'merchant_name'     => $t['merchant_name'] ?? null,
            'channel'           => $t['channel'] ?? null,
            'installment_no'    => $t['installment_no'] ?? null,
            'installment_total' => $t['installment_total'] ?? null,
        ];
    }
}
