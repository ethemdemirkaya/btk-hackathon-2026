<?php

namespace App\Services\Agents\Specialists;

use App\Models\Transaction;
use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AnomalyDetectorAgent extends AbstractAgent
{
    public function getName(): string { return 'anomaly_detector'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen bir finansal anomali tespit uzmanısın. Kullanıcının geçmiş harcama örüntüsünü
        analiz edip olağandışı işlemleri tespit et. Türkçe açıkla. Sadece JSON döndür.
        SYS;
    }

    public function run(array $input): array
    {
        $days = $input['days'] ?? 30;
        $since = Carbon::now()->subDays($days);

        $recentTxns = Transaction::select('id', 'amount', 'description', 'merchant_name', 'posted_at', 'channel')
            ->whereHas('account', fn ($q) => $q->where('user_id', $this->user->id))
            ->where('amount', '<', 0)
            ->where('posted_at', '>=', $since)
            ->orderByDesc('posted_at')
            ->limit(100)
            ->get();

        $avgSpend = (float) DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $this->user->id)
            ->where('t.amount', '<', 0)
            ->where('t.posted_at', '>=', Carbon::now()->subMonths(3))
            ->where('t.posted_at', '<', $since)
            ->avg(DB::raw('ABS(t.amount)'));

        $txData = $recentTxns->map(fn ($t) => [
            'id'          => $t->id,
            'amount'      => abs($t->amount),
            'description' => $t->description,
            'merchant'    => $t->merchant_name,
            'date'        => $t->posted_at->format('Y-m-d'),
            'channel'     => $t->channel,
        ]);

        $prompt = <<<PROMPT
        Son {$days} günün işlemleri (toplam {$recentTxns->count()} adet):
        Ortalama tek işlem tutarı (önceki 90 gün): ₺{$avgSpend}

        İşlemler:
        {$txData->toJson(JSON_UNESCAPED_UNICODE)}

        Olağandışı işlemleri tespit et: büyük tutarlar, alışılmadık saatler, tekrarlayan olmayan büyük harcamalar.
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'anomalies' => [
                    'type'  => 'array',
                    'items' => [
                        'type'       => 'object',
                        'properties' => [
                            'transaction_id' => ['type' => 'string'],
                            'type'           => ['type' => 'string'],
                            'score'          => ['type' => 'number'],
                            'reason'         => ['type' => 'string'],
                        ],
                        'required' => ['transaction_id', 'type', 'score', 'reason'],
                    ],
                ],
                'summary' => ['type' => 'string'],
            ],
            'required' => ['anomalies', 'summary'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema, 0.3);
    }
}
