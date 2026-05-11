<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CardResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'type'            => $this->type,
            'masked_number'   => $this->masked_number,
            'holder_name'     => $this->holder_name,
            'expiry_month'    => $this->expiry_month,
            'expiry_year'     => $this->expiry_year,
            'credit_limit'    => (float) $this->credit_limit,
            'current_debt'    => (float) $this->current_debt,
            'available_limit' => (float) $this->available_limit,
            'statement_day'   => $this->statement_day,
            'due_day'         => $this->due_day,
            'utilization_pct' => $this->credit_limit > 0
                ? round($this->current_debt / $this->credit_limit * 100, 1)
                : 0,
        ];
    }
}
