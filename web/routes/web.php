<?php

use App\Http\Controllers\BankConnectionController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProfileController;
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

    // Bank Connections
    Route::get('/banks', [BankConnectionController::class, 'index'])->name('bank-connections.index');
    Route::get('/banks/create', [BankConnectionController::class, 'create'])->name('bank-connections.create');
    Route::post('/banks', [BankConnectionController::class, 'store'])->name('bank-connections.store');
    Route::delete('/banks/{bankConnection}', [BankConnectionController::class, 'destroy'])->name('bank-connections.destroy');
    Route::post('/banks/{bankConnection}/sync', [BankConnectionController::class, 'sync'])->name('bank-connections.sync');
});

require __DIR__.'/auth.php';
