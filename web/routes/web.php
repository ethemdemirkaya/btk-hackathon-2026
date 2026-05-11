<?php

use App\Http\Controllers\AgentChatController;
use App\Http\Controllers\CalendarController;
use App\Http\Controllers\CardController;
use App\Http\Controllers\LoanController;
use App\Http\Controllers\DecisionSimulatorController;
use App\Http\Controllers\BankConnectionController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\GoalController;
use App\Http\Controllers\InflationController;
use App\Http\Controllers\NegotiationController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SubscriptionController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\BillController;
use App\Http\Controllers\ReceiptController;
use App\Http\Controllers\PersonalDebtController;
use App\Http\Controllers\InvestmentController;
use App\Http\Controllers\FxAlertController;
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
    Route::post('/chat/quick-analyze', [AgentChatController::class, 'quickAnalyze'])->name('agent-chat.quick-analyze');
    Route::patch('/chat/insights/{insight}/dismiss', [AgentChatController::class, 'dismissInsight'])->name('agent-chat.insight-dismiss');
    Route::get('/chat/history', [AgentChatController::class, 'history'])->name('agent-chat.history');
    Route::get('/chat/runs', [AgentChatController::class, 'runs'])->name('agent-chat.runs');

    // Receipts (OCR)
    Route::get('/receipts', [ReceiptController::class, 'index'])->name('receipts.index');
    Route::post('/receipts', [ReceiptController::class, 'store'])->name('receipts.store');
    Route::delete('/receipts/{receipt}', [ReceiptController::class, 'destroy'])->name('receipts.destroy');

    // Cards
    Route::get('/cards', [CardController::class, 'index'])->name('cards.index');

    // Loans
    Route::get('/loans', [LoanController::class, 'index'])->name('loans.index');

    // Transactions
    Route::get('/transactions', [TransactionController::class, 'index'])->name('transactions.index');
    Route::get('/transactions/export', [TransactionController::class, 'export'])->name('transactions.export');
    Route::get('/transactions/import', [TransactionController::class, 'showImport'])->name('transactions.import');
    Route::post('/transactions/import', [TransactionController::class, 'previewImport'])->name('transactions.import.preview');
    Route::post('/transactions/import/confirm', [TransactionController::class, 'confirmImport'])->name('transactions.import.confirm');
    Route::post('/transactions/{id}/debt', [TransactionController::class, 'storeDebt'])->name('transactions.debt.store');
    Route::get('/personal-debts', [PersonalDebtController::class, 'index'])->name('personal-debts.index');
    Route::post('/personal-debts', [PersonalDebtController::class, 'store'])->name('personal-debts.store');
    Route::patch('/personal-debts/{id}/settle', [TransactionController::class, 'settleDebt'])->name('personal-debts.settle');
    Route::delete('/personal-debts/{id}', [TransactionController::class, 'destroyDebt'])->name('personal-debts.destroy');

    // Calendar
    Route::get('/calendar', [CalendarController::class, 'index'])->name('calendar.index');

    // Bills
    Route::get('/bills', [BillController::class, 'index'])->name('bills.index');
    Route::post('/bills', [BillController::class, 'store'])->name('bills.store');
    Route::patch('/bills/{bill}', [BillController::class, 'update'])->name('bills.update');
    Route::delete('/bills/{bill}', [BillController::class, 'destroy'])->name('bills.destroy');

    // Subscriptions
    Route::get('/subscriptions', [SubscriptionController::class, 'index'])->name('subscriptions.index');
    Route::post('/subscriptions', [SubscriptionController::class, 'store'])->name('subscriptions.store');
    Route::delete('/subscriptions/{id}', [SubscriptionController::class, 'destroy'])->name('subscriptions.destroy');

    // Budgets
    Route::get('/budgets', [BudgetController::class, 'index'])->name('budgets.index');
    Route::post('/budgets', [BudgetController::class, 'store'])->name('budgets.store');
    Route::delete('/budgets/{id}', [BudgetController::class, 'destroy'])->name('budgets.destroy');
    Route::post('/budgets/ai-suggest', [BudgetController::class, 'aiSuggest'])->name('budgets.ai-suggest');
    Route::post('/budgets/ai-apply', [BudgetController::class, 'aiApply'])->name('budgets.ai-apply');

    // Investments (Portfolio Tracker)
    Route::get('/investments', [InvestmentController::class, 'index'])->name('investments.index');
    Route::post('/investments', [InvestmentController::class, 'store'])->name('investments.store');
    Route::delete('/investments/{id}', [InvestmentController::class, 'destroy'])->name('investments.destroy');

    // FX / Gold Alerts
    Route::get('/fx-alerts', [FxAlertController::class, 'index'])->name('fx-alerts.index');
    Route::get('/fx-alerts/live', [FxAlertController::class, 'liveRates'])->name('fx-alerts.live');
    Route::get('/fx-alerts/market', [FxAlertController::class, 'marketRates'])->name('fx-alerts.market');
    Route::post('/fx-alerts', [FxAlertController::class, 'store'])->name('fx-alerts.store');
    Route::delete('/fx-alerts/{id}', [FxAlertController::class, 'destroy'])->name('fx-alerts.destroy');

    // Goals
    Route::get('/goals', [GoalController::class, 'index'])->name('goals.index');
    Route::post('/goals', [GoalController::class, 'store'])->name('goals.store');
    Route::post('/goals/{id}/funds', [GoalController::class, 'addFunds'])->name('goals.funds');
    Route::get('/goals/{id}/suggest', [GoalController::class, 'suggestContribution'])->name('goals.suggest');
    Route::delete('/goals/{id}', [GoalController::class, 'destroy'])->name('goals.destroy');

    // Personal Inflation
    Route::get('/inflation', [InflationController::class, 'index'])->name('inflation.index');

    // Reports
    Route::get('/report', [ReportController::class, 'index'])->name('report.index');
    Route::get('/report/monthly', [ReportController::class, 'generate'])->name('report.monthly');

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
