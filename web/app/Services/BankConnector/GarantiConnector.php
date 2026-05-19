<?php

namespace App\Services\BankConnector;

use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankTransaction;
use Carbon\Carbon;

/**
 * Garanti BBVA — Doğrudan model sorgusu (HTTP self-call olmadan)
 * Credentials: { client_id (tckn), client_secret }
 */
class GarantiConnector extends AbstractBankConnector
{
    private const SLUG = 'garanti';
    private ?FakeBankCustomer $customer = null;

    public function fetchAccounts(): array
    {
        $customer = $this->resolveCustomer();

        return FakeBankAccount::where('bank_slug', self::SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($a) => [
                'external_id'       => $a->external_id,
                'account_type'      => $a->account_type,
                'iban'              => $a->iban,
                'currency'          => $a->currency,
                'balance'           => (float) $a->balance,
                'available_balance' => (float) $a->available_balance,
            ])->all();
    }

    public function fetchTransactions(string $externalAccountId, Carbon $from): array
    {
        $customer = $this->resolveCustomer();

        $account = FakeBankAccount::where('bank_slug', self::SLUG)
            ->where('fake_customer_id', $customer->id)
            ->where('external_id', $externalAccountId)
            ->first();

        if (! $account) {
            return [];
        }

        return FakeBankTransaction::where('bank_slug', self::SLUG)
            ->where('fake_account_id', $account->id)
            ->where('posted_at', '>=', $from->toDateTimeString())
            ->orderByDesc('posted_at')
            ->get()
            ->map(fn ($t) => [
                'external_id'       => $t->external_id,
                'posted_at'         => $t->posted_at,
                'amount'            => (float) $t->amount,
                'currency'          => $t->currency,
                'description'       => $t->description,
                'merchant_name'     => $t->merchant_name,
                'channel'           => $t->channel,
                'installment_no'    => null,
                'installment_total' => null,
            ])->all();
    }

    public function fetchCards(): array
    {
        return [];
    }

    public function fetchLoans(): array
    {
        return [];
    }

    private function resolveCustomer(): FakeBankCustomer
    {
        if ($this->customer) {
            return $this->customer;
        }

        $clientId     = $this->credentials['client_id'] ?? $this->credentials['tckn'] ?? null;
        $clientSecret = $this->credentials['client_secret'] ?? $this->credentials['oauth_token'] ?? null;

        $customer = FakeBankCustomer::where('bank_slug', self::SLUG)
            ->where('tckn', $clientId)
            ->first();

        $stored = $customer?->api_credentials['client_secret'] ?? null;

        if (! $customer || $stored !== $clientSecret) {
            throw new \RuntimeException('Garanti: kimlik doğrulama başarısız.');
        }

        return $this->customer = $customer;
    }
}
