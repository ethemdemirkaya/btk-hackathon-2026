<?php

namespace App\Providers;

use App\Services\DashboardService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Schema::defaultStringLength(191);

        // Share smart alerts with the app layout for the notification bell
        View::composer('layouts.app', function ($view) {
            $user = Auth::user();
            if (! $user) {
                $view->with('navAlerts', []);
                return;
            }
            try {
                $service = app(DashboardService::class);
                $view->with('navAlerts', $service->getSmartAlerts($user));
            } catch (\Throwable) {
                $view->with('navAlerts', []);
            }
        });
    }
}
