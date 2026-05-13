import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppColors.bg1,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                border: Border(
                    bottom: BorderSide(color: AppColors.border2Dark, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        size: 20, color: AppColors.accentText),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paranette',
                          style: AppTextStyles.headlineSmall
                              .copyWith(color: AppColors.text1Dark)),
                      Text('Finansal Yönetim',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.text3Dark)),
                    ],
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection(title: 'Hesaplar & Varlıklar', items: [
                    _DrawerItem(
                      icon: Icons.account_balance_outlined,
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
                      label: 'Karar Simülatörü',
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
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.border2Dark, width: 1)),
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
  const _DrawerSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.text4Dark,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ),
        ...items,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.accent : AppColors.text2Dark,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? AppColors.accent : AppColors.text1Dark,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
