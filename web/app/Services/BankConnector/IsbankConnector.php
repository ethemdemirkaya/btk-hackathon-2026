<?php

namespace App\Services\BankConnector;

use Carbon\Carbon;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

/**
 * İş Bankası — HMAC-SHA256 imzalı REST + RFC 5988 Link header pagination
 * Credentials: { tckn, hmac_secret }
 * Signature = HMAC-SHA256(secret, "METHOD|PATH|TIMESTAMP|BODY_SHA256")
 */
class IsbankConnector extends AbstractBankConnector
{
    public function fetchAccounts(): array
    {
        $response = $this->signedRequest('GET', '/accounts');
        $response->throw();

        return collect($response->json('accounts', []))->map(fn ($a) => [
            'external_id'       => $a['accountId'],
            'account_type'      => $a['accountType'],
            'iban'              => $a['iban'] ?? null,
            'currency'          => $a['currency'],
            'balance'           => (float) $a['balance'],
            'available_balance' => (float) $a['availableBalance'],
        ])->all();
    }

    public function fetchTransactions(string $externalAccountId, Carbon $from): array
    {
        $transactions = [];
        $page         = 1;

        do {
            $response = $this->signedRequest('GET', "/accounts/{$externalAccountId}/transactions", ['page' => $page]);
            $response->throw();

            $items = $response->json('transactions', []);
            foreach ($items as $t) {
                if (Carbon::parse($t['postedAt'])->lt($from)) {
                    return $transactions;
                }
                $transactions[] = $this->normalizeTransaction($t);
            }

            // Parse RFC 5988 Link header for next page
            $linkHeader = $response->header('Link');
            $hasNext    = $linkHeader && str_contains($linkHeader, 'rel="next"');
            $page++;
        } while ($hasNext);

        return $transactions;
    }

    public function fetchCards(): array
    {
        // İşbank mock does not expose cards
        return [];
    }

    public function fetchLoans(): array
    {
        // İşbank mock does not expose loans
        return [];
    }

    private function signedRequest(string $method, string $path, array $query = []): \Illuminate\Http\Client\Response
    {
        $timestamp = (string) time();
        $body      = '';
        $bodyHash  = hash('sha256', $body);
        $tckn      = $this->credentials['tckn'];
        $secret    = $this->credentials['hmac_secret'];

        // Build full path with query string for signature
        $fullPath  = '/api' . $path; // matches Laravel route prefix
        $payload   = strtoupper($method) . '|' . $fullPath . '|' . $timestamp . '|' . $bodyHash;
        $signature = hash_hmac('sha256', $payload, $secret);

        $pending = $this->http()
            ->withHeaders([
                'X-API-Key'   => $tckn,
                'X-Timestamp' => $timestamp,
                'X-Signature' => $signature,
            ]);

        $url = $this->apiUrl(ltrim($path, '/'));

        return $method === 'GET'
            ? $pending->get($url, $query)
            : $pending->post($url, $query);
    }

    private function normalizeTransaction(array $t): array
    {
        return [
            'external_id'       => $t['transactionId'],
            'posted_at'         => $t['postedAt'],
            'amount'            => (float) $t['amount'],
            'currency'          => $t['currency'],
            'description'       => $t['description'],
            'merchant_name'     => $t['merchantName'] ?? null,
            'channel'           => $t['channel'] ?? null,
            'installment_no'    => null,
            'installment_total' => null,
        ];
    }
}
