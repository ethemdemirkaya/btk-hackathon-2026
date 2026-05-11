<?php

namespace App\Services\Gemini;

enum GeminiModelEnum: string
{
    case PRO   = 'gemini-2.5-pro';
    case FLASH = 'gemini-2.5-flash';

    public function label(): string
    {
        return match ($this) {
            self::PRO   => 'Gemini 2.5 Pro',
            self::FLASH => 'Gemini 2.5 Flash',
        };
    }

    public static function vision(): self
    {
        return self::FLASH;
    }
}
