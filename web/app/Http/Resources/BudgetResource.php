<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BudgetResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'period'          => $this->period,
            'amount'          => (float) $this->amount,
            'alert_threshold' => (float) $this->alert_threshold,
            'spent'           => (float) ($this->spent ?? 0),
            'remaining'       => max(0, (float) $this->amount - (float) ($this->spent ?? 0)),
            'pct'             => $this->amount > 0
                ? min(100, round((float) ($this->spent ?? 0) / (float) $this->amount * 100, 1))
                : 0,
            'over_budget'     => (float) ($this->spent ?? 0) > (float) $this->amount,
            'category'        => $this->whenLoaded('category', fn () => [
                'id'   => $this->category?->id,
                'name' => $this->category?->name,
                'icon' => $this->category?->icon,
            ]),
        ];
    }
}
