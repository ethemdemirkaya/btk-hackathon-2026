<?php

namespace App\Http\Controllers\FakeBank;

use App\Http\Controllers\Controller;
use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCard;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankLoan;
use App\Models\FakeBank\FakeBankTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Akbank Mock — JSON-RPC 2.0
 * POST /api/banks/akbank/jsonrpc
 * Auth: X-Api-Key header (api_credentials.api_key)
 * Body: { "jsonrpc": "2.0", "method": "...", "params": {...}, "id": 1 }
 * Methods: accounts.list, accounts.balance, transactions.list,
 *           cards.list, cards.statement, loans.list
 */
class AkbankController extends Controller
{
    private const BANK_SLUG = 'akbank';
    private const PAGE_SIZE = 30;

    // JSON-RPC 2.0 standard error codes
    private const ERR_PARSE         = -32700;
    private const ERR_INVALID_REQ   = -32600;
    private const ERR_METHOD_NOT_FOUND = -32601;
    private const ERR_INVALID_PARAMS = -32602;
    private const ERR_INTERNAL       = -32603;

    // Application-level error codes (-32000 to -32099)
    private const ERR_UNAUTHORIZED  = -32001;
    private const ERR_NOT_FOUND     = -32002;
    private const ERR_UNAVAILABLE   = -32003;

    public function handle(Request $request): JsonResponse
    {
        $body = $request->json()->all();

        if (! $this->isValidRpcRequest($body)) {
            return $this->rpcError(null, self::ERR_INVALID_REQ, 'Geçersiz JSON-RPC 2.0 isteği.');
        }

        $id     = $body['id'] ?? null;
        $method = $body['method'];
        $params = $body['params'] ?? [];

        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return $this->rpcError($id, self::ERR_UNAUTHORIZED, 'API anahtarı geçersiz veya eksik.');
        }

        $this->simulateDelay();
        if ($this->shouldFail()) {
            return $this->rpcError($id, self::ERR_UNAVAILABLE, 'Servis geçici olarak kullanılamıyor.');
        }

        return match ($method) {
            'accounts.list'       => $this->accountsList($id, $customer),
            'accounts.balance'    => $this->accountsBalance($id, $customer, $params),
            'transactions.list'   => $this->transactionsList($id, $customer, $params),
            'cards.list'          => $this->cardsList($id, $customer),
            'cards.statement'     => $this->cardsStatement($id, $customer, $params),
            'loans.list'          => $this->loansList($id, $customer),
            default               => $this->rpcError($id, self::ERR_METHOD_NOT_FOUND, "Metot bulunamadı: {$method}"),
        };
    }

    private function accountsList(mixed $id, FakeBankCustomer $customer): JsonResponse
    {
        $accounts = FakeBankAccount::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($a) => [
                'accountId'        => $a->external_id,
                'accountType'      => $a->account_type,
                'iban'             => $a->iban,
                'currency'         => $a->currency,
                'balance'          => (float) $a->balance,
                'availableBalance' => (float) $a->available_balance,
                'openedAt'         => $a->opened_at,
            ]);

        return $this->rpcSuccess($id, ['accounts' => $accounts, 'count' => $accounts->count()]);
    }

    private function accountsBalance(mixed $id, FakeBankCustomer $customer, array $params): JsonResponse
    {
        if (empty($params['accountId'])) {
            return $this->rpcError($id, self::ERR_INVALID_PARAMS, 'accountId parametresi zorunludur.');
        }

        $account = FakeBankAccount::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->where('external_id', $params['accountId'])
            ->first();

        if (! $account) {
            return $this->rpcError($id, self::ERR_NOT_FOUND, 'Hesap bulunamadı.');
        }

        return $this->rpcSuccess($id, [
            'accountId'        => $account->external_id,
            'balance'          => (float) $account->balance,
            'availableBalance' => (float) $account->available_balance,
            'currency'         => $account->currency,
            'asOf'             => now()->toIso8601String(),
        ]);
    }

    private function transactionsList(mixed $id, FakeBankCustomer $customer, array $params): JsonResponse
    {
        if (empty($params['accountId'])) {
            return $this->rpcError($id, self::ERR_INVALID_PARAMS, 'accountId parametresi zorunludur.');
        }

        $account = FakeBankAccount::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->where('external_id', $params['accountId'])
            ->first();

        if (! $account) {
            return $this->rpcError($id, self::ERR_NOT_FOUND, 'Hesap bulunamadı.');
        }

        $limit  = min(100, max(1, (int) ($params['limit'] ?? self::PAGE_SIZE)));
        $offset = max(0, (int) ($params['offset'] ?? 0));

        $query = FakeBankTransaction::where('bank_slug', self::BANK_SLUG)
            ->where('fake_account_id', $account->id)
            ->orderByDesc('posted_at');

        if (! empty($params['from'])) {
            $query->where('posted_at', '>=', $params['from']);
        }
        if (! empty($params['to'])) {
            $query->where('posted_at', '<=', $params['to']);
        }

        $total = $query->count();
        $items = $query->skip($offset)->take($limit)->get();

        return $this->rpcSuccess($id, [
            'transactions' => $items->map(fn ($t) => [
                'id'          => $t->external_id,
                'postedAt'    => $t->posted_at,
                'amount'      => (float) $t->amount,
                'currency'    => $t->currency,
                'description' => $t->description,
                'merchant'    => $t->merchant_name,
                'channel'     => $t->channel,
            ]),
            'pagination' => [
                'total'  => $total,
                'limit'  => $limit,
                'offset' => $offset,
                'hasMore' => ($offset + $limit) < $total,
            ],
        ]);
    }

    private function cardsList(mixed $id, FakeBankCustomer $customer): JsonResponse
    {
        $cards = FakeBankCard::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($c) => [
                'cardId'       => $c->id,
                'type'         => $c->type,
                'maskedNumber' => $c->masked_number,
                'expiry'       => $c->expiry,
                'holderName'   => $c->holder_name,
                'creditLimit'  => (float) $c->credit_limit,
                'currentDebt'  => (float) $c->current_debt,
                'statementDay' => $c->statement_day,
                'dueDay'       => $c->due_day,
            ]);

        return $this->rpcSuccess($id, ['cards' => $cards]);
    }

    private function cardsStatement(mixed $id, FakeBankCustomer $customer, array $params): JsonResponse
    {
        if (empty($params['cardId'])) {
            return $this->rpcError($id, self::ERR_INVALID_PARAMS, 'cardId parametresi zorunludur.');
        }

        $card = FakeBankCard::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->where('id', $params['cardId'])
            ->first();

        if (! $card) {
            return $this->rpcError($id, self::ERR_NOT_FOUND, 'Kart bulunamadı.');
        }

        // Default: current month statement
        $month = $params['month'] ?? now()->format('Y-m');
        [$year, $mon] = explode('-', $month);
        $from = "{$year}-{$mon}-01 00:00:00";
        $to   = date('Y-m-t 23:59:59', mktime(0, 0, 0, (int) $mon, 1, (int) $year));

        $transactions = FakeBankTransaction::where('bank_slug', self::BANK_SLUG)
            ->where('fake_card_id', $card->id)
            ->whereBetween('posted_at', [$from, $to])
            ->orderByDesc('posted_at')
            ->get()
            ->map(fn ($t) => [
                'id'               => $t->external_id,
                'postedAt'         => $t->posted_at,
                'amount'           => (float) $t->amount,
                'currency'         => $t->currency,
                'description'      => $t->description,
                'merchant'         => $t->merchant_name,
                'installmentNo'    => $t->installment_no,
                'installmentTotal' => $t->installment_total,
            ]);

        $totalSpent = $transactions->where('amount', '<', 0)->sum('amount');

        return $this->rpcSuccess($id, [
            'card'         => ['cardId' => $card->id, 'maskedNumber' => $card->masked_number],
            'month'        => $month,
            'transactions' => $transactions,
            'totalSpent'   => abs((float) $totalSpent),
            'currentDebt'  => (float) $card->current_debt,
            'creditLimit'  => (float) $card->credit_limit,
        ]);
    }

    private function loansList(mixed $id, FakeBankCustomer $customer): JsonResponse
    {
        $loans = FakeBankLoan::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($l) => [
                'loanId'              => $l->external_id,
                'type'                => $l->type,
                'principal'           => (float) $l->principal,
                'currentBalance'      => (float) $l->current_balance,
                'interestRate'        => (float) $l->interest_rate,
                'totalInstallments'   => $l->total_installments,
                'paidInstallments'    => $l->paid_installments,
                'nextPaymentDate'     => $l->next_payment_date,
                'nextPaymentAmount'   => (float) $l->next_payment_amount,
            ]);

        return $this->rpcSuccess($id, ['loans' => $loans]);
    }

    private function resolveCustomer(Request $request): ?FakeBankCustomer
    {
        $apiKey = $request->header('X-Api-Key');
        if (! $apiKey) {
            return null;
        }

        // api_key is stored as api_credentials.api_key
        $customers = FakeBankCustomer::where('bank_slug', self::BANK_SLUG)->get();

        foreach ($customers as $customer) {
            $credentials = $customer->api_credentials ?? [];
            if (($credentials['api_key'] ?? '') === $apiKey) {
                return $customer;
            }
        }

        return null;
    }

    private function isValidRpcRequest(array $body): bool
    {
        return isset($body['jsonrpc'], $body['method'])
            && $body['jsonrpc'] === '2.0'
            && is_string($body['method']);
    }

    private function rpcSuccess(mixed $id, mixed $result): JsonResponse
    {
        return response()->json(['jsonrpc' => '2.0', 'result' => $result, 'id' => $id]);
    }

    private function rpcError(mixed $id, int $code, string $message): JsonResponse
    {
        $httpStatus = match (true) {
            $code === self::ERR_UNAUTHORIZED  => 401,
            $code === self::ERR_NOT_FOUND     => 404,
            $code === self::ERR_UNAVAILABLE   => 503,
            $code >= -32099 && $code <= -32000 => 400,
            default => 200, // JSON-RPC errors should still return 200 by spec
        };

        return response()->json([
            'jsonrpc' => '2.0',
            'error'   => ['code' => $code, 'message' => $message],
            'id'      => $id,
        ], $httpStatus);
    }

    private function shouldFail(): bool
    {
        return rand(1, 100) <= 2;
    }

    private function simulateDelay(): void
    {
        usleep(rand(50000, 300000));
    }
}
