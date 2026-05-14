import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/auth_provider.dart';

const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _negative   = Color(0xFFFF4D6D);

const _quickActions = [
  (icon: Icons.receipt_long_outlined,    label: 'Fiş çek',  color: Color(0xFF00D4FF),  route: '/receipts'),
  (icon: Icons.science_outlined,         label: 'Simüle et', color: Color(0xFFA78BFA), route: '/simulator'),
  (icon: Icons.handshake_outlined,       label: 'Müzakere',  color: Color(0xFFFFB547),  route: '/negotiation'),
  (icon: Icons.trending_up,              label: 'Portföy',   color: Color(0xFF6FB1FC),  route: '/investments'),
  (icon: Icons.picture_as_pdf_outlined,  label: 'Rapor',     color: Color(0xFFF472B6),  route: '/reports'),
];

final _settingsStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.dashboard);
  final data = res.data as Map<String, dynamic>;
  return {
    'score':      (data['health_score'] as num?)?.toInt() ?? 0,
    'goal_count': (data['active_goals_count'] as num?)?.toInt() ?? (data['goals'] as List?)?.length ?? 0,
    'days':       (data['days_since_joined'] as num?)?.toInt() ?? 0,
  };
});

const _modules = [
  (group: 'Bankacılık', items: [
    (id: 'cards',            icon: Icons.credit_card_outlined,          label: 'Kartlar',          sub: 'Kart borçları ve limitler',   route: '/cards'),
    (id: 'loans',            icon: Icons.account_balance_outlined,       label: 'Krediler',         sub: 'Aktif krediler',              route: '/loans'),
    (id: 'bank-connections', icon: Icons.account_balance_wallet_outlined,label: 'Banka Bağlantıları',sub: 'Bağlı bankalar',             route: '/bank-connections'),
    (id: 'bills',            icon: Icons.bolt_outlined,                  label: 'Faturalar',        sub: 'Fatura takibi',               route: '/bills'),
  ]),
  (group: 'Planlama', items: [
    (id: 'budgets',          icon: Icons.pie_chart_outline,              label: 'Bütçe ve Kategoriler',sub: 'Aylık bütçe limitleri',    route: '/budgets'),
    (id: 'goals',            icon: Icons.flag_outlined,                  label: 'Hedefler',         sub: 'Tasarruf hedefleri',          route: '/goals'),
    (id: 'subscriptions',    icon: Icons.subscriptions_outlined,         label: 'Abonelikler',      sub: 'Tekrarlayan ödemeler',        route: '/subscriptions'),
    (id: 'personal-debts',   icon: Icons.people_outlined,                label: 'Kişisel Borçlar',  sub: 'Borç takibi',                 route: '/personal-debts'),
  ]),
  (group: 'Varlık', items: [
    (id: 'investments',      icon: Icons.trending_up,                    label: 'Yatırım Portföyü', sub: 'Altın, döviz, kripto, hisse', route: '/investments'),
    (id: 'fx-alerts',        icon: Icons.notifications_outlined,         label: 'Kur ve Altın Alarmları',sub: 'Fiyat alarmları',       route: '/fx-alerts'),
    (id: 'inflation',        icon: Icons.show_chart,                     label: 'Enflasyon Takibi', sub: 'Kişisel enflasyon oranı',     route: '/inflation'),
  ]),
  (group: 'Zeka', items: [
    (id: 'simulator',        icon: Icons.science_outlined,               label: 'Karar Simülatörü', sub: 'Finansal senaryolar',         route: '/simulator'),
    (id: 'health',           icon: Icons.shield_outlined,                label: 'Finansal Sağlık Skoru',sub: 'Detaylı analiz',         route: '/health-score'),
    (id: 'negotiation',      icon: Icons.handshake_outlined,             label: 'Müzakere Mektupları',sub: 'Otomatik müzakere',        route: '/negotiation'),
    (id: 'receipts',         icon: Icons.receipt_long_outlined,          label: 'Fişler',           sub: 'OCR fiş tanıma',              route: '/receipts'),
    (id: 'reports',          icon: Icons.picture_as_pdf_outlined,        label: 'Raporlar',         sub: 'Aylık ve yıllık özetler',     route: '/reports'),
  ]),
];

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Kullanıcı';
    final email = user?.email ?? '';
    final income = (user?.monthlyIncome ?? 0).toDouble();

    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // Profile header card with gradient
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B2A), Color(0xFF0A1929)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFFC99B5B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials.isEmpty ? 'U' : initials,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF051929)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _text1)),
                          const SizedBox(height: 2),
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _text3)),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _text3),
                              children: [
                                const TextSpan(text: 'Aylık gelir: '),
                                TextSpan(
                                  text: AppFormatters.currencyCompact(income),
                                  style: const TextStyle(
                                      color: _text1,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _scaffoldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _cardBorder),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 16,
                            color: _text2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick stats from API
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: ref.watch(_settingsStatsProvider).when(
                loading: () => Row(
                  children: List.generate(3, (_) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 60,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cardBorder),
                      ),
                    ),
                  )),
                ),
                error: (_, __) => Row(children: [
                  Expanded(child: _StatCard(value: '—', label: 'SKOR', color: _accent)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(value: '—', label: 'HEDEF', color: _text1)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(value: '—', label: 'GÜN', color: _text1)),
                ]),
                data: (stats) => Row(
                  children: [
                    Expanded(child: _StatCard(
                        value: stats['score'].toString(),
                        label: 'SKOR',
                        color: _accent)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(
                        value: stats['goal_count'].toString(),
                        label: 'HEDEF',
                        color: _text1)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(
                        value: stats['days'].toString(),
                        label: 'GÜN',
                        color: _text1)),
                  ],
                ),
              ),
            ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                        right: 20, left: 2, bottom: 10),
                    child: Text('Hızlı erişim',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _text3,
                            letterSpacing: 0.5)),
                  ),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 20),
                      itemCount: _quickActions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final a = _quickActions[i];
                        return GestureDetector(
                          onTap: () => context.push(a.route),
                          child: Container(
                            width: 88,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: _cardBorder),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: a.color
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(a.icon,
                                      size: 18, color: a.color),
                                ),
                                const SizedBox(height: 8),
                                Text(a.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _text2)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Module groups
            ..._modules.map((group) => Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 2, bottom: 10),
                        child: Text(group.group,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _text3,
                                letterSpacing: 0.5)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _cardBorder),
                        ),
                        child: Column(
                          children: group.items
                              .asMap()
                              .entries
                              .map((entry) {
                            final m = entry.value;
                            return GestureDetector(
                              onTap: () =>
                                  context.push(m.route),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  border: entry.key > 0
                                      ? const Border(
                                          top: BorderSide(
                                              color: _cardBorder))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _scaffoldBg,
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                        border: Border.all(
                                            color: _cardBorder),
                                      ),
                                      child: Icon(m.icon,
                                          size: 16,
                                          color: _text2),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(m.label,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: _text1)),
                                          Text(m.sub,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: _text3)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 16,
                                        color: _text3),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                )),

            // Settings section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                        left: 2, bottom: 10),
                    child: Text('Ayarlar',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _text3,
                            letterSpacing: 0.5)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                            icon: Icons.notifications_outlined,
                            label: 'Bildirimler',
                            value: 'Açık'),
                        _SettingsRow(
                            icon: Icons.fingerprint,
                            label: 'Biyometrik giriş',
                            value: 'Açık'),
                        _SettingsRow(
                            icon: Icons.language_outlined,
                            label: 'Dil',
                            value: 'Türkçe'),
                        _SettingsRow(
                            icon: Icons.currency_lira,
                            label: 'Para birimi',
                            value: 'TRY'),
                        _SettingsRow(
                            icon: Icons.dark_mode_outlined,
                            label: 'Tema',
                            value: 'Koyu'),
                        _SettingsRow(
                            icon: Icons.backup_outlined,
                            label: 'Veri yedekleme',
                            value: ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Account actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  children: [
                    _SettingsRow(
                        icon: Icons.lock_outlined,
                        label: 'Şifre değiştir',
                        value: '',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Yakında aktif olacak.')),
                          );
                        }),
                    _SettingsRow(
                      icon: Icons.logout,
                      label: 'Çıkış yap',
                      value: '',
                      danger: true,
                      onTap: () => _logout(context, ref),
                    ),
                  ],
                ),
              ),
            ),

            // Version
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Paranette v1.2 · 2026',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _text3.withValues(alpha: 0.6))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkış Yap',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _text1)),
        content: const Text(
            'Hesabınızdan çıkmak istediğinize emin misiniz?',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _text2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _negative,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Çıkış Yap',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await DioClient.instance
            .delete(ApiEndpoints.authLogout);
      } catch (_) {}
      if (context.mounted) {
        await ref.read(authProvider.notifier).logout();
        router.go('/login');
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _text3,
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool danger;
  final VoidCallback? onTap;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: _cardBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: danger
                    ? _negative.withValues(alpha: 0.12)
                    : _scaffoldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _cardBorder),
              ),
              child: Icon(icon,
                  size: 15,
                  color: danger
                      ? _negative
                      : _text2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: danger
                          ? _negative
                          : _text1)),
            ),
            if (value.isNotEmpty)
              Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _text3)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 14,
                color: danger
                    ? _negative.withValues(alpha: 0.6)
                    : _text3),
          ],
        ),
      ),
    );
  }
}
