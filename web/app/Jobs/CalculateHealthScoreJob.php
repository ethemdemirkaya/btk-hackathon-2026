<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\FinancialHealthService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class CalculateHealthScoreJob implements ShouldQueue
{
    use Queueable, InteractsWithQueue, SerializesModels;

    public int $tries   = 2;
    public int $timeout = 60;

    public function __construct(public readonly User $user)
    {
    }

    public function handle(FinancialHealthService $service): void
    {
        $service->calculate($this->user);
    }

    public function failed(Throwable $e): void
    {
        logger()->error('CalculateHealthScoreJob failed', [
            'user_id' => $this->user->id,
            'error'   => $e->getMessage(),
        ]);
    }
}
