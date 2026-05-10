<?php

use App\Http\Controllers\AgentChatController;
use App\Http\Controllers\DecisionSimulatorController;
use App\Http\Controllers\BankConnectionController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\NegotiationController;
use App\Http\Controllers\ReceiptController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', [DashboardController::class, 'index'])
    ->middleware(['auth', 'verified'])
    ->name('dashboard');

Route::middleware('auth')->group(function () {
    // Profile
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');

    // Decision Simulator
    Route::get('/simulator', [DecisionSimulatorController::class, 'index'])->name('simulator.index');
    Route::post('/simulator/calculate', [DecisionSimulatorController::class, 'calculate'])->name('simulator.calculate');

    // Agent Chat
    Route::get('/chat', [AgentChatController::class, 'index'])->name('agent-chat.index');
    Route::post('/chat/send', [AgentChatController::class, 'send'])->name('agent-chat.send');
    Route::get('/chat/history', [AgentChatController::class, 'history'])->name('agent-chat.history');
    Route::get('/chat/runs', [AgentChatController::class, 'runs'])->name('agent-chat.runs');

    // Receipts (OCR)
    Route::get('/receipts', [ReceiptController::class, 'index'])->name('receipts.index');
    Route::post('/receipts', [ReceiptController::class, 'store'])->name('receipts.store');
    Route::delete('/receipts/{receipt}', [ReceiptController::class, 'destroy'])->name('receipts.destroy');

    // Negotiation Agent
    Route::get('/negotiation', [NegotiationController::class, 'index'])->name('negotiation.index');
    Route::post('/negotiation/generate', [NegotiationController::class, 'generate'])->name('negotiation.generate');
    Route::patch('/negotiation/{draft}/status', [NegotiationController::class, 'updateStatus'])->name('negotiation.status');
    Route::delete('/negotiation/{draft}', [NegotiationController::class, 'destroy'])->name('negotiation.destroy');

    // Bank Connections
    Route::get('/banks', [BankConnectionController::class, 'index'])->name('bank-connections.index');
    Route::get('/banks/create', [BankConnectionController::class, 'create'])->name('bank-connections.create');
    Route::post('/banks', [BankConnectionController::class, 'store'])->name('bank-connections.store');
    Route::delete('/banks/{bankConnection}', [BankConnectionController::class, 'destroy'])->name('bank-connections.destroy');
    Route::post('/banks/{bankConnection}/sync', [BankConnectionController::class, 'sync'])->name('bank-connections.sync');
});

require __DIR__.'/auth.php';
