<?php

namespace App\Http\Controllers\FakeBank;

use App\Http\Controllers\Controller;
use App\Models\FakeBank\FakeBankAccount;
use App\Models\FakeBank\FakeBankCard;
use App\Models\FakeBank\FakeBankCustomer;
use App\Models\FakeBank\FakeBankLoan;
use App\Models\FakeBank\FakeBankTransaction;
use App\Models\FakeBank\FakeBankOauthToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Ziraat Mock — REST + Bearer Token
 * Auth: POST /api/banks/ziraat/auth/login → { token }
 * Sonraki istekler: Authorization: Bearer {token}
 * Pagination: page-based
 */
class ZiraatController extends Controller
{
    private const BANK_SLUG = 'ziraat';

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'tckn'     => 'required|string',
            'password' => 'required|string',
        ]);

        $customer = FakeBankCustomer::where('bank_slug', self::BANK_SLUG)
            ->where('tckn', $request->tckn)
            ->first();

        if (! $customer || ! Hash::check($request->password, $customer->password_hash)) {
            return response()->json(['error' => 'Geçersiz kimlik bilgileri.', 'code' => 401], 401);
        }

        $token = Str::random(64);
        $expiresAt = now()->addHours(8);

        FakeBankOauthToken::create([
            'bank_slug'        => self::BANK_SLUG,
            'access_token'     => $token,
            'fake_customer_id' => $customer->id,
            'scopes'           => ['accounts', 'transactions', 'cards', 'loans'],
            'expires_at'       => $expiresAt,
        ]);

        $this->simulateDelay();

        return response()->json([
            'token'      => $token,
            'expires_at' => $expiresAt->toIso8601String(),
            'customer'   => ['id' => $customer->customer_id, 'name' => $customer->name],
        ]);
    }

    public function accounts(Request $request): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return $this->unauthorized();
        }

        $this->simulateDelay();
        if ($this->shouldFail()) {
            return $this->serverError();
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
                'opened_at'         => $a->opened_at,
            ]);

        return response()->json(['accounts' => $accounts]);
    }

    public function transactions(Request $request, string $accountId): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return $this->unauthorized();
        }

        $account = FakeBankAccount::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->where('external_id', $accountId)
            ->first();

        if (! $account) {
            return response()->json(['error' => 'Hesap bulunamadı.', 'code' => 404], 404);
        }

        $this->simulateDelay();
        if ($this->shouldFail()) {
            return $this->serverError();
        }

        $page    = max(1, (int) $request->query('page', 1));
        $perPage = min(100, max(10, (int) $request->query('per_page', 30)));

        $query = FakeBankTransaction::where('bank_slug', self::BANK_SLUG)
            ->where('fake_account_id', $account->id)
            ->orderByDesc('posted_at');

        if ($from = $request->query('from')) {
            $query->where('posted_at', '>=', $from);
        }
        if ($to = $request->query('to')) {
            $query->where('posted_at', '<=', $to);
        }

        $paginated = $query->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'transactions' => collect($paginated->items())->map(fn ($t) => [
                'id'               => $t->external_id,
                'posted_at'        => $t->posted_at,
                'amount'           => (float) $t->amount,
                'currency'         => $t->currency,
                'description'      => $t->description,
                'merchant_name'    => $t->merchant_name,
                'channel'          => $t->channel,
                'installment_no'   => $t->installment_no,
                'installment_total'=> $t->installment_total,
            ]),
            'pagination' => [
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
                'total'        => $paginated->total(),
            ],
        ]);
    }

    public function cards(Request $request): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return $this->unauthorized();
        }

        $this->simulateDelay();

        $cards = FakeBankCard::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($c) => [
                'id'             => $c->id,
                'type'           => $c->type,
                'masked_number'  => $c->masked_number,
                'expiry'         => $c->expiry,
                'holder_name'    => $c->holder_name,
                'credit_limit'   => (float) $c->credit_limit,
                'current_debt'   => (float) $c->current_debt,
                'statement_day'  => $c->statement_day,
                'due_day'        => $c->due_day,
            ]);

        return response()->json(['cards' => $cards]);
    }

    public function loans(Request $request): JsonResponse
    {
        $customer = $this->resolveCustomer($request);
        if (! $customer) {
            return $this->unauthorized();
        }

        $this->simulateDelay();

        $loans = FakeBankLoan::where('bank_slug', self::BANK_SLUG)
            ->where('fake_customer_id', $customer->id)
            ->get()
            ->map(fn ($l) => [
                'id'                  => $l->external_id,
                'type'                => $l->type,
                'principal'           => (float) $l->principal,
                'current_balance'     => (float) $l->current_balance,
                'interest_rate'       => (float) $l->interest_rate,
                'total_installments'  => $l->total_installments,
                'paid_installments'   => $l->paid_installments,
                'next_payment_date'   => $l->next_payment_date,
                'next_payment_amount' => (float) $l->next_payment_amount,
            ]);

        return response()->json(['loans' => $loans]);
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

        if (! $oauthToken) {
            return null;
        }

        return $oauthToken->fakeBankCustomer;
    }

    private function unauthorized(): JsonResponse
    {
        return response()->json(['error' => 'Kimlik doğrulama başarısız.', 'code' => 401], 401);
    }

    private function serverError(): JsonResponse
    {
        return response()->json(['error' => 'Sunucu hatası. Lütfen tekrar deneyin.', 'code' => 500], 500);
    }

    /** %2 ihtimalle 5xx simüle eder */
    private function shouldFail(): bool
    {
        return rand(1, 100) <= 2;
    }

    /** 50-300ms arası yapay gecikme */
    private function simulateDelay(): void
    {
        usleep(rand(50000, 300000));
    }
}
