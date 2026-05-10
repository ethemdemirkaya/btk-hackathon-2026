<?php

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
