<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NegotiationDraft extends Model
{
    protected $fillable = [
        'user_id',
        'target',
        'recipient_name',
        'subject',
        'body',
        'status',
        'generated_by_agent_id',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function targetLabels(): array
    {
        return [
            'card_interest'      => 'Kredi Kartı Faiz İndirimi',
            'loan_restructure'   => 'Kredi Yeniden Yapılandırma',
            'bank_fee_waiver'    => 'Banka Ücreti İptali',
            'subscription_cancel'=> 'Abonelik İptali / İndirim',
            'insurance_discount' => 'Sigorta Prim İndirimi',
            'salary_raise'       => 'Maaş Zam Talebi',
            'other'              => 'Diğer',
        ];
    }

    public function getTargetLabelAttribute(): string
    {
        return static::targetLabels()[$this->target] ?? $this->target;
    }

    public function getStatusBadgeAttribute(): string
    {
        return match ($this->status) {
            'sent'     => '<span class="badge bg-label-info">Gönderildi</span>',
            'accepted' => '<span class="badge bg-label-success">Kabul Edildi</span>',
            'rejected' => '<span class="badge bg-label-danger">Reddedildi</span>',
            default    => '<span class="badge bg-label-warning">Taslak</span>',
        };
    }
}
