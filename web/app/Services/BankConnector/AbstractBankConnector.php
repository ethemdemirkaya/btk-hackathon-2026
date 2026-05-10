<?php

namespace App\Services\BankConnector;

use App\Models\BankConnection;
use Carbon\Carbon;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

abstract class AbstractBankConnector
{
    protected array $credentials;
    protected string $baseUrl;

    public function __construct(protected BankConnection $connection)
    {
        $this->credentials = $connection->getCredentials();
        $this->baseUrl     = rtrim($connection->bank->api_base_url, '/');
    }

    /**
     * Returns list of normalized accounts.
     * Each item: external_id, account_type, iban, currency, balance, available_balance
     */
    abstract public function fetchAccounts(): array;

    /**
     * Returns normalized transactions for a given account.
     * Each item: external_id, posted_at (Y-m-d H:i:s), amount, currency,
     *            description, merchant_name, channel, installment_no, installment_total
     */
    abstract public function fetchTransactions(string $externalAccountId, Carbon $from): array;

    /**
     * Returns normalized cards.
     * Each item: type, masked_number, expiry_month, expiry_year, holder_name,
     *            credit_limit, current_debt, available_limit, statement_day, due_day
     */
    abstract public function fetchCards(): array;

    /**
     * Returns normalized loans.
     * Each item: external_id, type, principal, current_balance, interest_rate,
     *            total_installments, paid_installments, next_payment_date, next_payment_amount
     */
    abstract public function fetchLoans(): array;

    protected function http(): PendingRequest
    {
        return Http::timeout(15)->retry(2, 200);
    }

    protected function apiUrl(string $path): string
    {
        return $this->baseUrl . '/' . ltrim($path, '/');
    }

    /** Parse MM/YYYY expiry string into [month, year] */
    protected function parseExpiry(string $expiry): array
    {
        [$month, $year] = explode('/', $expiry);
        return [(int) $month, (int) $year];
    }
}
