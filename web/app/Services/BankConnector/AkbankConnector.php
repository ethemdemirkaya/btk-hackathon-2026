<?php

namespace App\Services\BankConnector;

use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCard;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankLoan;
use App\Models\FakeBank\FakeBankTransaction;
use Carbon\Carbon;

/**
 * Akbank — Doğrudan model sorgusu (HTTP self-call olmadan)
 * Credentials: { api_key }
 */
class AkbankConnector extends AbstractBankConnector
{
    private const SLUG = 'akbank';
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
                'iban'              => null,
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
        $customer = $this->resolveCustomer();

        return FakeBankCard::where('bank_slug', self::SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($c) => [
                'type'            => $c->type,
                'masked_number'   => $c->masked_number,
                'expiry_month'    => (int) explode('/', $c->expiry)[0],
                'expiry_year'     => (int) explode('/', $c->expiry)[1],
                'holder_name'     => $c->holder_name,
                'credit_limit'    => $c->credit_limit !== null ? (float) $c->credit_limit : null,
                'current_debt'    => (float) ($c->current_debt ?? 0),
                'available_limit' => $c->credit_limit !== null
                    ? (float) $c->credit_limit - (float) ($c->current_debt ?? 0)
                    : null,
                'statement_day'   => $c->statement_day,
                'due_day'         => $c->due_day,
            ])->all();
    }

    public function fetchLoans(): array
    {
        $customer = $this->resolveCustomer();

        return FakeBankLoan::where('bank_slug', self::SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($l) => [
                'external_id'         => $l->external_id,
                'type'                => $l->type,
                'principal'           => (float) $l->principal,
                'current_balance'     => (float) $l->current_balance,
                'interest_rate'       => (float) $l->interest_rate,
                'total_installments'  => (int) $l->total_installments,
                'paid_installments'   => (int) $l->paid_installments,
                'next_payment_date'   => $l->next_payment_date,
                'next_payment_amount' => $l->next_payment_amount !== null
                    ? (float) $l->next_payment_amount : null,
            ])->all();
    }

    private function resolveCustomer(): FakeBankCustomer
    {
        if ($this->customer) {
            return $this->customer;
        }

        $apiKey    = $this->credentials['api_key'] ?? null;
        $customers = FakeBankCustomer::where('bank_slug', self::SLUG)->get();

        $customer = $customers->first(
            fn ($c) => ($c->api_credentials['api_key'] ?? null) === $apiKey
        );

        if (! $customer) {
            throw new \RuntimeException('Akbank: kimlik doğrulama başarısız.');
        }

        return $this->customer = $customer;
    }
}
