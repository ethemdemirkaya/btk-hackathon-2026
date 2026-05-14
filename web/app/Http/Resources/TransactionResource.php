<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    /**
     * Sanitise any user-originated string so json_encode cannot bail on a
     * malformed UTF-8 sequence (which surfaces in the mobile client as
     * "FormatException: Unexpected end of input" — a truncated response).
     */
    private function safe(?string $value): ?string
    {
        if ($value === null) return null;
        return mb_convert_encoding($value, 'UTF-8', 'UTF-8');
    }

    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'               => (string) $this->id,
            'external_id'      => $this->safe($this->external_id),
            'posted_at'        => $this->posted_at?->toIso8601String(),
            'amount'           => (float) $this->amount,
            'currency'         => $this->currency,
            'try_amount'       => (float) $this->try_amount,
            'description'      => $this->safe($this->description) ?? '',
            'merchant_name'    => $this->safe($this->merchant_name),
            'merchant_category'=> $this->safe($this->merchant_category),
            'category'         => $this->whenLoaded('category', fn () => [
                'id'   => $this->category?->id,
                'name' => $this->safe($this->category?->name),
                'icon' => $this->safe($this->category?->icon),
            ]),
            'channel'          => $this->safe($this->channel),
            'is_recurring'     => (bool) $this->is_recurring,
            'installment_no'   => $this->installment_no,
            'installment_total'=> $this->installment_total,
            'anomaly_score'    => $this->anomaly_score !== null ? (float) $this->anomaly_score : null,
        ];
    }
}
