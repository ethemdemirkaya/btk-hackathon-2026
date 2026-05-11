<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GoalResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'name'                 => $this->name,
            'target_amount'        => (float) $this->target_amount,
            'current_amount'       => (float) $this->current_amount,
            'remaining_amount'     => $this->remainingAmount(),
            'progress_pct'         => $this->progressPct(),
            'target_date'          => $this->target_date?->toDateString(),
            'monthly_contribution' => (float) $this->monthly_contribution,
            'status'               => $this->status,
            'months_to_goal'       => $this->monthlyContribution > 0 && $this->remainingAmount() > 0
                ? (int) ceil($this->remainingAmount() / (float) $this->monthly_contribution)
                : null,
        ];
    }
}
