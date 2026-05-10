<?php

namespace App\Services\BankConnector;

use Carbon\Carbon;
use Illuminate\Support\Facades\Http;

/**
 * Akbank — JSON-RPC 2.0
 * Credentials: { api_key }
 */
class AkbankConnector extends AbstractBankConnector
{
    private int $rpcId = 1;

    public function fetchAccounts(): array
    {
        $result = $this->rpc('accounts.list');

        return collect($result['accounts'] ?? [])->map(fn ($a) => [
            'external_id'       => $a['accountId'],
            'account_type'      => $a['accountType'],
            'iban'              => null, // Akbank RPC doesn't expose IBAN
            'currency'          => $a['currency'],
            'balance'           => (float) $a['balance'],
            'available_balance' => (float) $a['availableBalance'],
        ])->all();
    }

    public function fetchTransactions(string $externalAccountId, Carbon $from): array
    {
        $transactions = [];
        $offset       = 0;
        $limit        = 100;

        do {
            $result = $this->rpc('transactions.list', [
                'accountId' => $externalAccountId,
                'from'      => $from->format('Y-m-d'),
                'limit'     => $limit,
                'offset'    => $offset,
            ]);

            $items   = $result['transactions'] ?? [];
            $hasMore = $result['pagination']['hasMore'] ?? false;

            foreach ($items as $t) {
                $transactions[] = $this->normalizeTransaction($t);
            }

            $offset += $limit;
        } while ($hasMore);

        return $transactions;
    }

    public function fetchCards(): array
    {
        $result = $this->rpc('cards.list');

        return collect($result['cards'] ?? [])->map(fn ($c) => [
            'type'           => $c['type'],
            'masked_number'  => $c['maskedNumber'],
            'expiry_month'   => (int) explode('/', $c['expiry'])[0],
            'expiry_year'    => (int) explode('/', $c['expiry'])[1],
            'holder_name'    => $c['holderName'],
            'credit_limit'   => isset($c['creditLimit']) ? (float) $c['creditLimit'] : null,
            'current_debt'   => (float) ($c['currentDebt'] ?? 0),
            'available_limit'=> isset($c['creditLimit'], $c['currentDebt'])
                ? (float) $c['creditLimit'] - (float) $c['currentDebt']
                : null,
            'statement_day'  => $c['statementDay'] ?? null,
            'due_day'        => $c['dueDay'] ?? null,
        ])->all();
    }

    public function fetchLoans(): array
    {
        $result = $this->rpc('loans.list');

        return collect($result['loans'] ?? [])->map(fn ($l) => [
            'external_id'          => $l['loanId'],
            'type'                 => $l['type'],
            'principal'            => (float) $l['principal'],
            'current_balance'      => (float) $l['currentBalance'],
            'interest_rate'        => (float) $l['interestRate'],
            'total_installments'   => (int) $l['totalInstallments'],
            'paid_installments'    => (int) $l['paidInstallments'],
            'next_payment_date'    => $l['nextPaymentDate'] ?? null,
            'next_payment_amount'  => isset($l['nextPaymentAmount']) ? (float) $l['nextPaymentAmount'] : null,
        ])->all();
    }

    private function rpc(string $method, array $params = []): array
    {
        $response = Http::withHeaders(['X-Api-Key' => $this->credentials['api_key']])
            ->timeout(15)
            ->retry(2, 200)
            ->post($this->apiUrl('jsonrpc'), [
                'jsonrpc' => '2.0',
                'method'  => $method,
                'params'  => $params,
                'id'      => $this->rpcId++,
            ]);

        $response->throw();

        $body = $response->json();

        if (isset($body['error'])) {
            throw new \RuntimeException(
                "JSON-RPC error [{$body['error']['code']}]: {$body['error']['message']}"
            );
        }

        return $body['result'] ?? [];
    }

    private function normalizeTransaction(array $t): array
    {
        return [
            'external_id'       => $t['id'],
            'posted_at'         => $t['postedAt'],
            'amount'            => (float) $t['amount'],
            'currency'          => $t['currency'],
            'description'       => $t['description'],
            'merchant_name'     => $t['merchant'] ?? null,
            'channel'           => $t['channel'] ?? null,
            'installment_no'    => null,
            'installment_total' => null,
        ];
    }
}
