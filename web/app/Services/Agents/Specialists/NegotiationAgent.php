<?php

namespace App\Services\Agents\Specialists;

use App\Services\Agents\AbstractAgent;
use App\Services\Gemini\GeminiModelEnum;
use Illuminate\Support\Facades\DB;

class NegotiationAgent extends AbstractAgent
{
    public function getName(): string { return 'negotiation'; }
    protected function getModel(): GeminiModelEnum { return GeminiModelEnum::FLASH; }

    protected function getSystemPrompt(): string
    {
        return <<<'SYS'
        Sen Türkiye'de müşterilerin banka ve kurumlarla müzakere mektupları yazan bir
        hukuk & finans uzmanısın. Resmi, ikna edici, nezaket kurallarına uygun Türkçe
        mektuplar yaz. Müşterinin mali profilini, sadakat süresini ve piyasa koşullarını
        argüman olarak kullan. Sadece JSON döndür.
        SYS;
    }

    /**
     * @param  array{
     *   target: string,
     *   recipient_name: string,
     *   user_name: string,
     *   extra_context: string
     * }  $input
     */
    public function run(array $input): array
    {
        $target        = $input['target'] ?? 'bank_fee_waiver';
        $recipientName = $input['recipient_name'] ?? 'İlgili Yetkili';
        $extraContext  = $input['extra_context'] ?? '';
        $userName      = $input['user_name'] ?? $this->user->name;

        // Collect user financial context for stronger arguments
        $monthlyIncome = (float) ($this->user->monthly_income ?? 0);
        $totalBalance  = (float) DB::table('accounts')->where('user_id', $this->user->id)->sum('balance');
        $totalDebt     = (float) DB::table('cards')->where('user_id', $this->user->id)->sum('current_debt');
        $accountCount  = DB::table('accounts')->where('user_id', $this->user->id)->count();
        $txMonths      = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $this->user->id)
            ->selectRaw('TIMESTAMPDIFF(MONTH, MIN(t.posted_at), NOW()) as months')
            ->value('months') ?? 0;

        $targetLabels = [
            'card_interest'      => 'kredi kartı faiz oranının indirilmesi',
            'loan_restructure'   => 'mevcut kredinin yeniden yapılandırılması',
            'bank_fee_waiver'    => 'hesap/kart yıllık ücretlerinin kaldırılması',
            'subscription_cancel'=> 'mevcut aboneliğin iptal edilmesi veya ücret indiriminin sağlanması',
            'insurance_discount' => 'sigorta priminin indirilmesi',
            'salary_raise'       => 'maaş artış talebi',
            'other'              => $extraContext ?: 'talebimin karşılanması',
        ];
        $targetDesc = $targetLabels[$target] ?? $targetLabels['other'];

        $prompt = <<<PROMPT
        Kullanıcı bilgileri:
        - Ad: {$userName}
        - Aylık gelir: ₺{$monthlyIncome}
        - Toplam banka mevduatı: ₺{$totalBalance}
        - Toplam kart borcu: ₺{$totalDebt}
        - Hesap sayısı: {$accountCount}
        - Müşteri süresi (tahmini ay): {$txMonths}

        Hedef: {$targetDesc}
        Alıcı: {$recipientName}
        Ek bağlam: {$extraContext}

        Bu bilgilere dayanarak kullanıcı adına resmi bir müzakere mektubu yaz.
        Mektup güçlü argümanlar içermeli, kullanıcının sadakati ve finansal profilini
        kullanmalı, Türkçe resmi hitap kurallarına uymalı.
        PROMPT;

        $schema = [
            'type'       => 'object',
            'properties' => [
                'subject'         => ['type' => 'string'],
                'body'            => ['type' => 'string'],
                'key_arguments'   => ['type' => 'array', 'items' => ['type' => 'string']],
                'success_tips'    => ['type' => 'array', 'items' => ['type' => 'string']],
                'estimated_chance'=> ['type' => 'string'],
            ],
            'required' => ['subject', 'body', 'key_arguments'],
        ];

        $this->createRun($input);
        return $this->generate($this->buildUserMessage($prompt), $schema, 0.6);
    }
}
