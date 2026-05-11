<?php

use App\Http\Controllers\Api\AgentChatController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BankConnectionController;
use App\Http\Controllers\Api\BillController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\CardController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\GoalController;
use App\Http\Controllers\Api\InflationController;
use App\Http\Controllers\Api\LoanController;
use App\Http\Controllers\Api\ReceiptController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\FakeBank\AkbankController;
use App\Http\Controllers\FakeBank\GarantiController;
use App\Http\Controllers\FakeBank\IsbankController;
use App\Http\Controllers\FakeBank\ZiraatController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Fake Bank API Routes
|--------------------------------------------------------------------------
|
| Her banka farklı bir kimlik doğrulama ve sayfalama pattern'i kullanır:
|   Ziraat  → Bearer Token (login endpoint)
|   Garanti → OAuth2 Client Credentials (cursor pagination, RFC 7807)
|   İşbank  → HMAC-SHA256 imzalı istek (RFC 5988 Link header pagination)
|   Akbank  → JSON-RPC 2.0 (X-Api-Key header)
|
*/

// ══════════════════════════════════════════════════════════════════════════
// PARANETTE MOBILE API  (v1)
// Auth: Bearer token via Laravel Sanctum  →  Authorization: Bearer {token}
// Base prefix: /api/v1/...  (set in bootstrap/app.php or RouteServiceProvider)
// ══════════════════════════════════════════════════════════════════════════

Route::prefix('v1')->group(function () {

    // ── Auth (public) ───────────────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login',    [AuthController::class, 'login']);
    });

    // ── Authenticated endpoints ─────────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::get   ('auth/me',          [AuthController::class, 'me']);
        Route::patch ('auth/me',          [AuthController::class, 'updateProfile']);
        Route::delete('auth/logout',      [AuthController::class, 'logout']);
        Route::delete('auth/logout-all',  [AuthController::class, 'logoutAll']);

        // Dashboard
        Route::get('dashboard', [DashboardController::class, 'summary']);

        // Bank connections
        Route::get   ('bank-connections',            [BankConnectionController::class, 'index']);
        Route::post  ('bank-connections',            [BankConnectionController::class, 'store']);
        Route::post  ('bank-connections/{bankConnection}/sync', [BankConnectionController::class, 'sync']);
        Route::delete('bank-connections/{bankConnection}',      [BankConnectionController::class, 'destroy']);

        // Transactions
        Route::get('transactions',           [TransactionController::class, 'index']);
        Route::get('transactions/{transaction}', [TransactionController::class, 'show']);

        // Cards
        Route::get('cards', [CardController::class, 'index']);

        // Loans
        Route::get('loans', [LoanController::class, 'index']);

        // Bills
        Route::get   ('bills',        [BillController::class, 'index']);
        Route::post  ('bills',        [BillController::class, 'store']);
        Route::patch ('bills/{bill}', [BillController::class, 'update']);
        Route::delete('bills/{bill}', [BillController::class, 'destroy']);

        // Subscriptions
        Route::get   ('subscriptions',                [SubscriptionController::class, 'index']);
        Route::post  ('subscriptions',                [SubscriptionController::class, 'store']);
        Route::delete('subscriptions/{subscription}', [SubscriptionController::class, 'destroy']);

        // Budgets
        Route::get   ('budgets',          [BudgetController::class, 'index']);
        Route::post  ('budgets',          [BudgetController::class, 'store']);
        Route::delete('budgets/{budget}', [BudgetController::class, 'destroy']);

        // Goals
        Route::get   ('goals',                          [GoalController::class, 'index']);
        Route::post  ('goals',                          [GoalController::class, 'store']);
        Route::post  ('goals/{goal}/add-funds',         [GoalController::class, 'addFunds']);
        Route::delete('goals/{goal}',                   [GoalController::class, 'destroy']);

        // Inflation
        Route::get('inflation', [InflationController::class, 'index']);

        // AI Agent
        Route::post('agent/send',                          [AgentChatController::class, 'send']);
        Route::get ('agent/history',                       [AgentChatController::class, 'history']);
        Route::get ('agent/insights',                      [AgentChatController::class, 'insights']);
        Route::patch('agent/insights/{insight}/dismiss',   [AgentChatController::class, 'dismissInsight']);

        // Receipts (OCR)
        Route::get   ('receipts',           [ReceiptController::class, 'index']);
        Route::post  ('receipts',           [ReceiptController::class, 'store']);
        Route::delete('receipts/{receipt}', [ReceiptController::class, 'destroy']);
    });
});

// ══════════════════════════════════════════════════════════════════════════
// FAKE BANK MOCK APIS
// ══════════════════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────
// Ziraat Bankası — REST + Bearer Token
// ──────────────────────────────────────────────
Route::prefix('banks/ziraat')->group(function () {
    Route::post('auth/login', [ZiraatController::class, 'login']);
    Route::get('accounts', [ZiraatController::class, 'accounts']);
    Route::get('accounts/{accountId}/transactions', [ZiraatController::class, 'transactions']);
    Route::get('cards', [ZiraatController::class, 'cards']);
    Route::get('loans', [ZiraatController::class, 'loans']);
});

// ──────────────────────────────────────────────
// Garanti BBVA — OAuth2 Client Credentials
// ──────────────────────────────────────────────
Route::prefix('banks/garanti')->group(function () {
    Route::post('oauth/token', [GarantiController::class, 'token']);
    Route::get('v2/customers/me/accounts', [GarantiController::class, 'accounts']);
    Route::get('v2/customers/me/accounts/{accountId}/movements', [GarantiController::class, 'movements']);
});

// ──────────────────────────────────────────────
// İş Bankası — HMAC-SHA256 İmzalı REST
// ──────────────────────────────────────────────
Route::prefix('banks/isbank')->group(function () {
    Route::get('accounts', [IsbankController::class, 'accounts']);
    Route::get('accounts/{accountId}/transactions', [IsbankController::class, 'transactions']);
});

// ──────────────────────────────────────────────
// Akbank — JSON-RPC 2.0
// ──────────────────────────────────────────────
Route::post('banks/akbank/jsonrpc', [AkbankController::class, 'handle']);
