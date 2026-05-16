import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'app_drawer.dart';
import '../theme/colors.dart';
import '../theme/context_extensions.dart';

final shellScaffoldKey = GlobalKey<ScaffoldState>();

class BottomNavShell extends StatelessWidget {
  final Widget child;
  final String location;

  const BottomNavShell({
    super.key,
    required this.location,
    required this.child,
  });

  static const _tabs = [
    _NavTab(
      path:       '/dashboard',
      icon:       Iconsax.home_bold,
      activeIcon: Iconsax.home_bold,
      label:      'Ana Sayfa',
    ),
    _NavTab(
      path:       '/transactions',
      icon:       Iconsax.receipt_bold,
      activeIcon: Iconsax.receipt_bold,
      label:      'İşlemler',
    ),
    _NavTab(
      path:       '/chat',
      icon:       Iconsax.message_bold,
      activeIcon: Iconsax.message_bold,
      label:      'AI',
    ),
    _NavTab(
      path:       '/calendar',
      icon:       Iconsax.calendar_bold,
      activeIcon: Iconsax.calendar_bold,
      label:      'Takvim',
    ),
    _NavTab(
      path:       '/insights',
      icon:       Iconsax.chart_bold,
      activeIcon: Iconsax.chart_bold,
      label:      'Öngörüler',
    ),
  ];

  static const _tabPaths = [
    '/dashboard', '/transactions', '/chat', '/calendar', '/insights',
  ];

  bool get _showBottomNav =>
      _tabPaths.any((p) => location == p || location.startsWith('$p/'));

  int get _selectedIndex {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      key: shellScaffoldKey,
      backgroundColor: c.bg,
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: _showBottomNav
          ? _FloatingNavBar(
              selectedIndex: _selectedIndex,
              tabs: _tabs,
              onTap: (i) => context.go(_tabs[i].path),
            )
          : null,
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavTab> tabs;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      color: c.bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.04),
                  blurRadius: 40,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                return _NavItem(
                  tab: tabs[i],
                  isActive: i == selectedIndex,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Builder(
        builder: (context) {
          final c = context.appColors;
          return SizedBox(
            width: 64,
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? tab.activeIcon : tab.icon,
                    size: 22,
                    color: isActive ? AppColors.accent : c.text2,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.accent : c.text2,
                    letterSpacing: 0.2,
                  ),
                  child: Text(tab.label),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavTab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavTab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
