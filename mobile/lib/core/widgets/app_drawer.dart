import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';

const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _positive   = Color(0xFF0DD9A0);
const _negative   = Color(0xFFFF4D6D);
const _warning    = Color(0xFFF59E0B);

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Kullanıcı';
    final email = user?.email ?? '';
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Drawer(
      backgroundColor: const Color(0xFF0A1929),
      child: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1929), Color(0xFF0D2240)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                    bottom: BorderSide(
                        color: _cardBorder, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Initials avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF00D4FF),
                              Color(0xFFC99B5B)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials.isEmpty ? 'U' : initials,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF051929),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _text1)),
                            Text(email.isEmpty ? 'Paranette' : email,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _text3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // BTK Hackathon badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _accent.withValues(alpha: 0.25)),
                    ),
                    child: const Text(
                      'BTK Akademi Hackathon 2026',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection(
                      title: 'Hesaplar & Varlıklar',
                      items: [
                        _DrawerItem(
                          icon:
                              Icons.account_balance_outlined,
                          label: 'Banka Bağlantıları',
                          route: '/bank-connections',
                          current: loc,
                        ),
                        _DrawerItem(
                          icon: Icons.credit_card_outlined,
                          label: 'Kartlarım',
                          route: '/cards',
                          current: loc,
                        ),
                        _DrawerItem(
                          icon: Icons.home_outlined,
                          label: 'Krediler',
                          route: '/loans',
                          current: loc,
                        ),
                        _DrawerItem(
                          icon: Icons.show_chart,
                          label: 'Yatırımlar',
                          route: '/investments',
                          current: loc,
                        ),
                      ]),
                  _DrawerSection(title: 'Ödemeler', items: [
                    _DrawerItem(
                      icon: Icons.receipt_outlined,
                      label: 'Faturalar',
                      route: '/bills',
                      current: loc,
                    ),
                    _DrawerItem(
                      icon: Icons.subscriptions_outlined,
                      label: 'Abonelikler',
                      route: '/subscriptions',
                      current: loc,
                    ),
                  ]),
                  _DrawerSection(title: 'Planlama', items: [
                    _DrawerItem(
                      icon: Icons.pie_chart_outline,
                      label: 'Bütçeler',
                      route: '/budgets',
                      current: loc,
                    ),
                    _DrawerItem(
                      icon: Icons.flag_outlined,
                      label: 'Hedefler',
                      route: '/goals',
                      current: loc,
                    ),
                    _DrawerItem(
                      icon: Icons.people_outline,
                      label: 'Kişisel Borçlar',
                      route: '/personal-debts',
                      current: loc,
                    ),
                  ]),
                  _DrawerSection(title: 'AI Araçları', items: [
                    _DrawerItem(
                      icon: Icons.currency_exchange,
                      label: 'Kur & Altın Alarmları',
                      route: '/fx-alerts',
                      current: loc,
                    ),
                    _DrawerItem(
                      icon: Icons.handshake_outlined,
                      label: 'Müzakere Mektupları',
                      route: '/negotiation',
                      current: loc,
                    ),
                    _DrawerItem(
                      icon: Icons.calculate_outlined,
                      label: 'Kadar Simülatörü',
                      route: '/simulator',
                      current: loc,
                    ),
                    _DrawerItem(
                      icon: Icons.trending_up,
                      label: 'Kişisel Enflasyon',
                      route: '/inflation',
                      current: loc,
                    ),
                  ]),
                  _DrawerSection(title: 'Belgeler', items: [
                    _DrawerItem(
                      icon: Icons.photo_camera_outlined,
                      label: 'Fişler & OCR',
                      route: '/receipts',
                      current: loc,
                    ),
                    _DrawerItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Aylık Rapor',
                      route: '/reports',
                      current: loc,
                    ),
                  ]),
                ],
              ),
            ),
            // Bottom: settings + profile
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: _cardBorder, width: 1)),
              ),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Profilim',
                    route: '/profile',
                    current: loc,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Ayarlar',
                    route: '/settings',
                    current: loc,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _DrawerSection(
      {required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _text3,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items,
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
              color: _cardBorder,
              height: 8,
              thickness: 1),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;
  final EdgeInsetsGeometry? padding;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current.startsWith(route);
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 1),
        padding: padding ??
            const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? _accent.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? const Border(
                  left: BorderSide(
                      color: _accent, width: 3))
              : null,
        ),
        child: Row(
          children: [
            // Icon in 32px container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? _accent.withValues(alpha: 0.12)
                    : _cardBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isActive
                    ? _accent
                    : _text2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isActive
                      ? _accent
                      : _text1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
