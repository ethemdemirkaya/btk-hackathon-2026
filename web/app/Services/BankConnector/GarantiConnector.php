<?php

namespace App\Services\BankConnector;

use Carbon\Carbon;
use Illuminate\Support\Facades\Http;

/**
 * Garanti BBVA — OAuth2 Client Credentials + cursor pagination
 * Credentials: { client_id (tckn), client_secret }
 */
class GarantiConnector extends AbstractBankConnector
{
    private ?string $accessToken = null;

    public function fetchAccounts(): array
    {
        $token    = $this->authenticate();
        $response = $this->http()->withToken($token)
            ->get($this->apiUrl('v2/customers/me/accounts'));

        $response->throw();

        return collect($response->json('data', []))->map(fn ($a) => [
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
        $token        = $this->authenticate();
        $transactions = [];
        $cursor       = null;

        do {
            $params   = $cursor ? ['cursor' => $cursor] : [];
            $response = $this->http()->withToken($token)
                ->get($this->apiUrl("v2/customers/me/accounts/{$externalAccountId}/movements"), $params);

            $response->throw();

            $data   = $response->json();
            $items  = $data['data'] ?? [];

            foreach ($items as $t) {
                // Stop fetching if we've gone past the from date
                if (Carbon::parse($t['posted_at'])->lt($from)) {
                    return $transactions;
                }

                $transactions[] = $this->normalizeTransaction($t);
            }

            $cursor = $data['meta']['next_cursor'] ?? null;
        } while ($cursor);

        return $transactions;
    }

    public function fetchCards(): array
    {
        // Garanti API does not expose cards in this mock
        return [];
    }

    public function fetchLoans(): array
    {
        // Garanti API does not expose loans in this mock
        return [];
    }

    private function authenticate(): string
    {
        if ($this->accessToken) {
            return $this->accessToken;
        }

        $response = Http::post($this->apiUrl('oauth/token'), [
            'grant_type'    => 'client_credentials',
            'client_id'     => $this->credentials['client_id'],
            'client_secret' => $this->credentials['client_secret'],
        ]);

        $response->throw();

        $this->accessToken = $response->json('access_token');

        return $this->accessToken;
    }

    private function normalizeTransaction(array $t): array
    {
        return [
            'external_id'       => $t['id'],
            'posted_at'         => $t['posted_at'],
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
