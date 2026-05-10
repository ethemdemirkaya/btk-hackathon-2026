<?php

namespace App\Services\BankConnector;

use App\Models\BankConnection;
use InvalidArgumentException;

class BankConnectorFactory
{
    public static function make(BankConnection $connection): AbstractBankConnector
    {
        return match ($connection->bank->slug) {
            'ziraat' => new ZiraatConnector($connection),
            'garanti'=> new GarantiConnector($connection),
            'isbank' => new IsbankConnector($connection),
            'akbank' => new AkbankConnector($connection),
            default  => throw new InvalidArgumentException(
                "Desteklenmeyen banka: {$connection->bank->slug}"
            ),
        };
    }
}
