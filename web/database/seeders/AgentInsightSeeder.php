<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AgentInsightSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'demo@paranette.local')->first();
        if (! $user) {
            $this->command->warn('Demo user not found.');
            return;
        }

        DB::table('agent_insights')
            ->where('user_id', $user->id)
            ->where('is_dismissed', false)
            ->delete();

        $insights = [
            [
                'agent_name' => 'SpendingAnalyzerAgent',
                'type'       => 'warning',
                'title'      => 'Harcamalar %23 Arttı',
                'body'       => 'Bu ay harcamalarınız geçen aya göre %23 arttı. Restoran & kafe kategorisinde belirgin yükseliş var — aylık bütçenizin %84\'ünü kullandınız.',
                'action_link'=> '/transactions',
                'importance' => 8,
            ],
            [
                'agent_name' => 'SubscriptionHunterAgent',
                'type'       => 'opportunity',
                'title'      => 'Dijital Abonelik Maliyeti: ₺548/ay',
                'body'       => '6 aktif dijital aboneliğiniz aylık ₺547,96 tutarında. Notion Pro\'nun yıllık planı ayda ₺23 tasarruf sağlıyor. Kullanım analizine göre YouTube Premium ve Netflix örtüşüyor.',
                'action_link'=> '/subscriptions',
                'importance' => 7,
            ],
            [
                'agent_name' => 'ForecasterAgent',
                'type'       => 'tip',
                'title'      => 'Acil Fon 4.2 Ay Kapasitesinde',
                'body'       => 'Acil durum fonunuz mevcut gider hızınızda yaklaşık 4.2 aylık giderinizi karşılayabilir. 6 aylık hedef için ek ₺58.000 biriktirilmesi öneriliyor.',
                'action_link'=> '/goals',
                'importance' => 6,
            ],
            [
                'agent_name' => 'BudgetAdvisorAgent',
                'type'       => 'warning',
                'title'      => 'Kart Limiti %73 Kullanıldı',
                'body'       => 'Garanti BBVA kredi kartı limitinizin %73\'ünü kullanıyorsunuz (₺21.900 / ₺30.000). Kredi skoru açısından %30 altında tutulması öneriliyor.',
                'action_link'=> '/cards',
                'importance' => 9,
            ],
            [
                'agent_name' => 'PersonalInflationAgent',
                'type'       => 'anomaly',
                'title'      => 'Gıda Enflasyonunuz TÜFE\'nin 14 Puan Üzerinde',
                'body'       => 'Son 3 ayda Yiyecek & İçecek kategorisinde kişisel enflasyonunuz %52.3 — TÜFE ortalamasının 14.4 puan üzerinde. Market alışverişi yerine toplu alım tercih edilebilir.',
                'action_link'=> '/inflation',
                'importance' => 7,
            ],
        ];

        foreach ($insights as $insight) {
            DB::table('agent_insights')->insert(array_merge($insight, [
                'user_id'      => $user->id,
                'is_read'      => false,
                'is_dismissed' => false,
                'expires_at'   => now()->addDays(30),
                'created_at'   => now()->subHours(rand(1, 48)),
                'updated_at'   => now(),
            ]));
        }

        $this->command->info('✓ AgentInsightSeeder: ' . count($insights) . ' öngörü eklendi.');
    }
}
