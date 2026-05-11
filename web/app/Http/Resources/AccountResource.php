<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AccountResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'                => $this->id,
            'external_id'       => $this->external_id,
            'account_type'      => $this->account_type,
            'iban'              => $this->iban,
            'currency'          => $this->currency,
            'balance'           => (float) $this->balance,
            'available_balance' => (float) $this->available_balance,
            'nickname'          => $this->nickname,
            'bank'              => $this->whenLoaded('bankConnection', fn () => [
                'name' => $this->bankConnection?->bank?->name,
                'slug' => $this->bankConnection?->bank?->slug,
                'logo' => $this->bankConnection?->bank?->logo,
            ]),
            'created_at'        => $this->created_at?->toIso8601String(),
        ];
    }
}
