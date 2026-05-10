<?php

namespace App\Http\Controllers\FakeBank;

use App\Http\Controllers\Controller;
use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankOauthToken;
use App\Models\FakeBank\FakeBankTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Garanti Mock — OAuth2 Client Credentials
 * Token endpoint: POST /api/banks/garanti/oauth/token
 * Accounts: GET /api/banks/garanti/v2/customers/me/accounts
 * Transactions: GET /api/banks/garanti/v2/customers/me/accounts/{id}/movements
 * Pagination: cursor-based (X-Next-Cursor header)
 * Error: RFC 7807 Problem Details
 */
class GarantiController extends Controller
{
    private const BANK_SLUG  = 'garanti';
    private const PAGE_SIZE  = 20;

    public function token(Request $request): JsonResponse
    {
        $request->validate([
            'grant_type'    => 'required|in:client_credentials,password',
            'client_id'     => 'required|string',
            'client_secret' => 'required|string',
        ]);

        // client_id = tckn, client_secret = password (simülasyon için)
        $customer = FakeBankCustomer::where('bank_slug', self::BANK_SLUG)
            ->where('tckn', $request->client_id)
            ->first();

        if (! $customer) {
            return $this->rfc7807(401, 'unauthorized', 'Geçersiz kimlik bilgileri.');
        }

        $credentials = $customer->api_credentials ?? [];
        if (($credentials['client_secret'] ?? '') !== $request->client_secret) {
            return $this->rfc7807(401, 'unauthorized', 'Geçersiz client_secret.');
        }

        $accessToken  = Str::random(80);
        $refreshToken = Str::random(80);
        $expiresAt    = now()->addHour();

        FakeBankOauthToken::create([
            'bank_slug'        => self::BANK_SLUG,
            'access_token'     => $accessToken,
            'refresh_token'    => $refreshToken,
            'fake_customer_id' => $customer->id,
            'scopes'           => ['accounts:read', 'transactions:read'],
            'expires_at'       => $expiresAt,
        ]);

        $this->simulateDelay();

        return response()->json([
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'token_type'    => 'Bearer',
            'expires_in'    => 3600,
            'scope'         => 'accounts:read transactions:read',
        ]);
    }

    public function accounts(Request $request): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return $this->rfc7807(401, 'unauthorized', 'Bearer token geçersiz veya süresi dolmuş.');
        }

        $this->simulateDelay();
        if ($this->shouldFail()) {
            return $this->rfc7807(500, 'internal_error', 'Sunucu hatası.');
        }

        $accounts = FakeBankAccount::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($a) => [
                'id'                => $a->external_id,
                'account_type'      => $a->account_type,
                'iban'              => $a->iban,
                'currency'          => $a->currency,
                'balance'           => (float) $a->balance,
                'available_balance' => (float) $a->available_balance,
            ]);

        return response()->json([
            'data' => $accounts,
            'meta' => ['count' => $accounts->count()],
        ]);
    }

    public function movements(Request $request, string $accountId): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return $this->rfc7807(401, 'unauthorized', 'Bearer token geçersiz veya süresi dolmuş.');
        }

        $account = FakeBankAccount::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->where('external_id', $accountId)
            ->first();

        if (! $account) {
            return $this->rfc7807(404, 'not_found', 'Hesap bulunamadı.');
        }

        $this->simulateDelay();
        if ($this->shouldFail()) {
            return $this->rfc7807(500, 'internal_error', 'Sunucu hatası.');
        }

        // Cursor pagination
        $cursor    = $request->query('cursor');
        $query     = FakeBankTransaction::where('bank_slug', self::BANK_SLUG)
            ->where('fake_account_id', $account->id)
            ->orderByDesc('posted_at')
            ->orderByDesc('id');

        if ($cursor) {
            // cursor = base64(id:posted_at)
            [$cursorId] = explode(':', base64_decode($cursor));
            $query->where('id', '<', (int) $cursorId);
        }

        $items   = $query->limit(self::PAGE_SIZE + 1)->get();
        $hasMore = $items->count() > self::PAGE_SIZE;
        $items   = $items->take(self::PAGE_SIZE);

        $nextCursor = null;
        if ($hasMore && $last = $items->last()) {
            $nextCursor = base64_encode($last->id . ':' . $last->posted_at);
        }

        $response = response()->json([
            'data' => $items->map(fn ($t) => [
                'id'          => $t->external_id,
                'posted_at'   => $t->posted_at,
                'amount'      => (float) $t->amount,
                'currency'    => $t->currency,
                'description' => $t->description,
                'merchant'    => $t->merchant_name,
                'channel'     => $t->channel,
            ]),
            'meta' => [
                'count'      => $items->count(),
                'has_more'   => $hasMore,
                'next_cursor'=> $nextCursor,
            ],
        ]);

        if ($nextCursor) {
            $response->header('X-Next-Cursor', $nextCursor);
        }

        return $response;
    }

    private function resolveCustomer(Request $request): ?FakeBankCustomer
    {
        $token = $request->bearerToken();
        if (! $token) {
            return null;
        }

        $oauthToken = FakeBankOauthToken::where('bank_slug', self::BANK_SLUG)
            ->where('access_token', $token)
            ->where('expires_at', '>', now())
            ->first();

        return $oauthToken?->fakeBankCustomer;
    }

    private function rfc7807(int $status, string $type, string $detail): JsonResponse
    {
        return response()->json([
            'type'   => "https://paranette.local/problems/{$type}",
            'title'  => match ($status) {
                401     => 'Unauthorized',
                404     => 'Not Found',
                429     => 'Too Many Requests',
                default => 'Internal Server Error',
            },
            'status' => $status,
            'detail' => $detail,
        ], $status)->header('Content-Type', 'application/problem+json');
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
