<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BillResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'name'           => $this->name,
            'type'           => $this->type,
            'type_label'     => \App\Models\Bill::typeLabel($this->type),
            'provider'       => $this->provider,
            'account_number' => $this->account_number,
            'average_amount' => (float) $this->average_amount,
            'due_day'        => $this->due_day,
            'is_autopay'     => (bool) $this->is_autopay,
            'last_paid_at'   => $this->last_paid_at?->toIso8601String(),
            'last_amount'    => (float) $this->last_amount,
        ];
    }
}
