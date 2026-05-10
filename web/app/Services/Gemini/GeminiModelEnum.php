<?php

namespace App\Services\Gemini;

enum GeminiModelEnum: string
{
    case PRO   = 'gemini-2.5-pro-preview-05-06';
    case FLASH = 'gemini-2.5-flash-preview-04-17';
    case VISION = 'gemini-2.5-flash-preview-04-17'; // vision via same Flash model

    public function label(): string
    {
        return match ($this) {
            self::PRO    => 'Gemini 2.5 Pro',
            self::FLASH  => 'Gemini 2.5 Flash',
            self::VISION => 'Gemini 2.5 Flash (Vision)',
        };
    }
}
