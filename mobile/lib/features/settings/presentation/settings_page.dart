import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/auth_provider.dart';

const _quickActions = [
  (icon: Icons.receipt_long_outlined, label: 'Fiş çek', color: AppColors.accent, route: '/receipts'),
  (icon: Icons.science_outlined, label: 'Simüle et', color: Color(0xFFA78BFA), route: '/simulator'),
  (icon: Icons.handshake_outlined, label: 'Müzakere', color: Color(0xFFFFB547), route: '/negotiation'),
  (icon: Icons.trending_up, label: 'Portföy', color: AppColors.info, route: '/investments'),
  (icon: Icons.picture_as_pdf_outlined, label: 'Rapor', color: Color(0xFFF472B6), route: '/reports'),
];

const _modules = [
  (group: 'Bankacılık', items: [
    (id: 'cards', icon: Icons.credit_card_outlined, label: 'Kartlar', sub: 'Kart borçları ve limitler', route: '/cards'),
    (id: 'loans', icon: Icons.account_balance_outlined, label: 'Krediler', sub: 'Aktif krediler', route: '/loans'),
    (id: 'bank-connections', icon: Icons.account_balance_wallet_outlined, label: 'Banka Bağlantıları', sub: 'Bağlı bankalar', route: '/bank-connections'),
    (id: 'bills', icon: Icons.bolt_outlined, label: 'Faturalar', sub: 'Fatura takibi', route: '/bills'),
  ]),
  (group: 'Plan', items: [
    (id: 'budgets', icon: Icons.pie_chart_outline, label: 'Bütçe ve Kategoriler', sub: 'Aylık bütçe limitleri', route: '/budgets'),
    (id: 'goals', icon: Icons.flag_outlined, label: 'Hedefler', sub: 'Tasarruf hedefleri', route: '/goals'),
    (id: 'subscriptions', icon: Icons.subscriptions_outlined, label: 'Abonelikler', sub: 'Tekrarlayan ödemeler', route: '/subscriptions'),
    (id: 'personal-debts', icon: Icons.people_outlined, label: 'Kişisel Borçlar', sub: 'Borç takibi', route: '/personal-debts'),
  ]),
  (group: 'Varlık', items: [
    (id: 'investments', icon: Icons.trending_up, label: 'Yatırım Portföyü', sub: 'Altın, döviz, kripto, hisse', route: '/investments'),
    (id: 'fx-alerts', icon: Icons.notifications_outlined, label: 'Kur ve Altın Alarmları', sub: 'Fiyat alarmları', route: '/fx-alerts'),
    (id: 'inflation', icon: Icons.show_chart, label: 'Enflasyon Takibi', sub: 'Kişisel enflasyon oranı', route: '/inflation'),
  ]),
  (group: 'Akıllı', items: [
    (id: 'simulator', icon: Icons.science_outlined, label: 'Karar Simülatörü', sub: 'Finansal senaryolar', route: '/simulator'),
    (id: 'health', icon: Icons.shield_outlined, label: 'Finansal Sağlık Skoru', sub: 'Detaylı analiz', route: '/health-score'),
    (id: 'negotiation', icon: Icons.handshake_outlined, label: 'Müzakere Mektupları', sub: 'Otomatik müzakere', route: '/negotiation'),
    (id: 'receipts', icon: Icons.receipt_long_outlined, label: 'Fişler', sub: 'OCR fiş tanıma', route: '/receipts'),
    (id: 'reports', icon: Icons.picture_as_pdf_outlined, label: 'Raporlar', sub: 'Aylık ve yıllık özetler', route: '/reports'),
  ]),
];

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Kullanıcı';
    final email = user?.email ?? '';
    final income =
        (user?.monthlyIncome ?? 0).toDouble();

    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // Profile header card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.bg1, AppColors.bg2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border1Dark),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.gold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials.isEmpty ? 'U' : initials,
                          style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.accentText,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.02 * 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(email,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.text3Dark)),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.text3Dark),
                              children: [
                                const TextSpan(text: 'Aylık gelir: '),
                                TextSpan(
                                  text:
                                      '${AppFormatters.currencyCompact(income)} ₺',
                                  style: const TextStyle(
                                      color: AppColors.text1Dark,
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
                          shape: BoxShape.circle,
                          color: AppColors.bg3,
                          border: Border.all(color: AppColors.border2Dark),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.text2Dark),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick stats
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          value: '72', label: 'SKOR', color: AppColors.accent)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard(
                          value: '4', label: 'HEDEF', color: AppColors.text1Dark)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard(
                          value: '147', label: 'GÜN', color: AppColors.text1Dark)),
                ],
              ),
            ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20, left: 4, bottom: 10),
                    child: Text('Hızlı erişim',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.text3Dark)),
                  ),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 20),
                      itemCount: _quickActions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final a = _quickActions[i];
                        return GestureDetector(
                          onTap: () => context.push(a.route),
                          child: Container(
                            width: 92,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bg1,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.border1Dark),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        a.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(a.icon,
                                      size: 18, color: a.color),
                                ),
                                const SizedBox(height: 8),
                                Text(a.label,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelSmall.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11)),
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(group.group,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.text3Dark)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bg1,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border1Dark),
                        ),
                        child: Column(
                          children: group.items.asMap().entries.map((entry) {
                            final m = entry.value;
                            return GestureDetector(
                              onTap: () => context.push(m.route),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  border: entry.key > 0
                                      ? const Border(
                                          top: BorderSide(
                                              color: AppColors.border1Dark))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.bg2,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(m.icon,
                                          size: 18,
                                          color: AppColors.text2Dark),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(m.label,
                                              style:
                                                  AppTextStyles.bodyMedium
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight
                                                                  .w500)),
                                          Text(m.sub,
                                              style:
                                                  AppTextStyles.labelSmall
                                                      .copyWith(
                                                          color: AppColors
                                                              .text3Dark)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 16,
                                        color: AppColors.text3Dark),
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
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text('Ayarlar',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text3Dark,
                            letterSpacing: 0.06 * 11)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border1Dark),
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
                  color: AppColors.bg1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border1Dark),
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
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.text3Dark.withValues(alpha: 0.6),
                        fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Çıkış Yap', style: AppTextStyles.headlineMedium),
        content: Text(
            'Hesabınızdan çıkmak istediğinize emin misiniz?',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.text2Dark)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.text2Dark))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative),
            child: const Text('Çıkış Yap',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await DioClient.instance.delete(ApiEndpoints.authLogout);
      } catch (_) {}
      if (context.mounted) {
        await ref.read(authProvider.notifier).logout();
        context.go('/login');
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border1Dark),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.amountHero.copyWith(
                  fontSize: 18, color: color, letterSpacing: -0.02 * 18)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.text3Dark,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06 * 9)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border1Dark)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: danger ? AppColors.negative : AppColors.text3Dark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: danger
                          ? AppColors.negative
                          : AppColors.text1Dark)),
            ),
            if (value.isNotEmpty)
              Text(value,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.text3Dark)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 14, color: AppColors.text3Dark),
          ],
        ),
      ),
    );
  }
}
