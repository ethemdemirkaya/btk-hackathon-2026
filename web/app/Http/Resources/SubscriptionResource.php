<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SubscriptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $monthlyEq = $this->monthlyEquivalent();

        return [
            'id'                         => $this->id,
            'name'                       => $this->name,
            'merchant_name'              => $this->merchant_name,
            'amount'                     => (float) $this->amount,
            'currency'                   => $this->currency,
            'billing_cycle'              => $this->billing_cycle,
            'monthly_equivalent'         => round($monthlyEq, 2),
            'next_billing_date'          => $this->next_billing_date?->toDateString(),
            'started_at'                 => $this->started_at?->toDateString(),
            'auto_detected'              => (bool) $this->auto_detected,
            'cancel_candidate'           => false,
            'status'                     => $this->status,
            'category'                   => $this->whenLoaded('category', fn () => [
                'id'   => $this->category?->id,
                'name' => $this->category?->name,
            ]),
        ];
    }
}
