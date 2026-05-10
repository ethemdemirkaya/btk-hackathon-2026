<?php

namespace App\Http\Controllers\FakeBank;

use App\Http\Controllers\Controller;
use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * İşbank Mock — HMAC İmzalı REST
 * Headers: X-API-Key, X-Timestamp, X-Signature
 * Signature = HMAC-SHA256(secret, "{METHOD}|{PATH}|{TIMESTAMP}|{BODY_HASH}")
 * Pagination: Link header (RFC 5988)
 */
class IsbankController extends Controller
{
    private const BANK_SLUG = 'isbank';
    private const PAGE_SIZE = 25;

    public function accounts(Request $request): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return response()->json(['error' => 'HMAC imza doğrulama başarısız.', 'code' => 'AUTH_FAILED'], 401);
        }

        $this->simulateDelay();
        if ($this->shouldFail()) {
            return response()->json(['error' => 'Servis geçici olarak kullanılamıyor.', 'code' => 'SERVICE_UNAVAILABLE'], 503);
        }

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
            ]);

        return response()->json(['accounts' => $accounts]);
    }

    public function transactions(Request $request, string $accountId): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return response()->json(['error' => 'HMAC imza doğrulama başarısız.', 'code' => 'AUTH_FAILED'], 401);
        }

        $account = FakeBankAccount::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->where('external_id', $accountId)
            ->first();

        if (! $account) {
            return response()->json(['error' => 'Hesap bulunamadı.', 'code' => 'NOT_FOUND'], 404);
        }

        $this->simulateDelay();
        if ($this->shouldFail()) {
            return response()->json(['error' => 'Servis geçici olarak kullanılamıyor.', 'code' => 'SERVICE_UNAVAILABLE'], 503);
        }

        $page = max(1, (int) $request->query('page', 1));

        $paginated = FakeBankTransaction::where('bank_slug', self::BANK_SLUG)
            ->where('fake_account_id', $account->id)
            ->orderByDesc('posted_at')
            ->paginate(self::PAGE_SIZE, ['*'], 'page', $page);

        $baseUrl  = $request->url();
        $linkHeader = $this->buildRfc5988LinkHeader($baseUrl, $page, $paginated->lastPage());

        $response = response()->json([
            'transactions' => collect($paginated->items())->map(fn ($t) => [
                'transactionId' => $t->external_id,
                'postedAt'      => $t->posted_at,
                'amount'        => (float) $t->amount,
                'currency'      => $t->currency,
                'description'   => $t->description,
                'merchantName'  => $t->merchant_name,
                'channel'       => $t->channel,
            ]),
            'totalCount' => $paginated->total(),
        ]);

        if ($linkHeader) {
            $response->header('Link', $linkHeader);
        }

        return $response;
    }

    /**
     * HMAC doğrulaması:
     * X-API-Key → müşteri TCKN'si
     * X-Signature = HMAC-SHA256(secret, "METHOD|PATH|TIMESTAMP|BODY_SHA256")
     */
    private function resolveCustomer(Request $request): ?FakeBankCustomer
    {
        $apiKey    = $request->header('X-API-Key');
        $timestamp = $request->header('X-Timestamp');
        $signature = $request->header('X-Signature');

        if (! $apiKey || ! $timestamp || ! $signature) {
            return null;
        }

        // Timestamp'i 5 dakika içinde olmalı (replay attack koruması)
        if (abs(time() - (int) $timestamp) > 300) {
            return null;
        }

        $customer = FakeBankCustomer::where('bank_slug', self::BANK_SLUG)
            ->where('tckn', $apiKey)
            ->first();

        if (! $customer) {
            return null;
        }

        $secret    = ($customer->api_credentials['hmac_secret'] ?? '');
        $bodyHash  = hash('sha256', $request->getContent());
        $method    = strtoupper($request->method());
        $path      = $request->getPathInfo();
        $payload   = "{$method}|{$path}|{$timestamp}|{$bodyHash}";
        $expected  = hash_hmac('sha256', $payload, $secret);

        if (! hash_equals($expected, $signature)) {
            return null;
        }

        return $customer;
    }

    /** RFC 5988 Link header formatı */
    private function buildRfc5988LinkHeader(string $baseUrl, int $current, int $last): string
    {
        $parts = [];

        if ($current > 1) {
            $parts[] = "<{$baseUrl}?page=" . ($current - 1) . '>; rel="prev"';
        }
        if ($current < $last) {
            $parts[] = "<{$baseUrl}?page=" . ($current + 1) . '>; rel="next"';
        }
        $parts[] = "<{$baseUrl}?page=1>; rel=\"first\"";
        $parts[] = "<{$baseUrl}?page={$last}>; rel=\"last\"";

        return implode(', ', $parts);
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
