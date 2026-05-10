<?php

namespace App\Models\FakeBank;

use Illuminate\Database\Eloquent\Model;

class FakeBankWebhookLog extends Model
{
    protected $fillable = [
        'bank_slug', 'callback_url', 'event_type', 'payload',
        'status', 'attempts', 'last_attempt_at',
    ];

    protected $casts = [
        'payload'         => 'array',
        'last_attempt_at' => 'datetime',
    ];
}
