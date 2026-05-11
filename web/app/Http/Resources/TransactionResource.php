<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'               => $this->id,
            'external_id'      => $this->external_id,
            'posted_at'        => $this->posted_at,
            'amount'           => (float) $this->amount,
            'currency'         => $this->currency,
            'try_amount'       => (float) $this->try_amount,
            'description'      => $this->description,
            'merchant_name'    => $this->merchant_name,
            'merchant_category'=> $this->merchant_category,
            'category'         => $this->whenLoaded('category', fn () => [
                'id'   => $this->category?->id,
                'name' => $this->category?->name,
                'icon' => $this->category?->icon,
            ]),
            'channel'          => $this->channel,
            'is_recurring'     => (bool) $this->is_recurring,
            'installment_no'   => $this->installment_no,
            'installment_total'=> $this->installment_total,
            'anomaly_score'    => $this->anomaly_score,
        ];
    }
}
