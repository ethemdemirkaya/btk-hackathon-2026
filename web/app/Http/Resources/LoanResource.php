<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LoanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'external_id'          => $this->external_id,
            'type'                 => $this->type,
            'principal'            => (float) $this->principal,
            'current_balance'      => (float) $this->current_balance,
            'interest_rate'        => (float) $this->interest_rate,
            'total_installments'   => $this->total_installments,
            'paid_installments'    => $this->paid_installments,
            'remaining_installments' => max(0, $this->total_installments - $this->paid_installments),
            'progress_pct'         => $this->total_installments > 0
                ? round($this->paid_installments / $this->total_installments * 100, 1)
                : 0,
            'next_payment_date'    => $this->next_payment_date?->toDateString(),
            'next_payment_amount'  => (float) $this->next_payment_amount,
            'started_at'           => $this->started_at?->toDateString(),
            'ends_at'              => $this->ends_at?->toDateString(),
            'bank'                 => $this->whenLoaded('bankConnection', fn () => [
                'name' => $this->bankConnection?->bank?->name,
                'slug' => $this->bankConnection?->bank?->slug,
            ]),
        ];
    }
}
