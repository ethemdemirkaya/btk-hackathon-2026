<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InflationCategoryRate extends Model
{
    protected $fillable = [
        'period_year', 'period_month', 'tuik_category_slug',
        'annual_change_rate', 'fetched_at',
    ];

    protected $casts = [
        'annual_change_rate' => 'decimal:4',
        'fetched_at'         => 'datetime',
    ];
}
