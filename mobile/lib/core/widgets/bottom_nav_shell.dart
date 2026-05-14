import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'app_drawer.dart';

final shellScaffoldKey = GlobalKey<ScaffoldState>();

const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _textMuted  = Color(0xFF8899AA);

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
      icon:       Iconsax.home_outline,
      activeIcon: Iconsax.home_bold,
      label:      'Ana Sayfa',
    ),
    _NavTab(
      path:       '/transactions',
      icon:       Iconsax.receipt_outline,
      activeIcon: Iconsax.receipt_bold,
      label:      'İşlemler',
    ),
    _NavTab(
      path:       '/chat',
      icon:       Iconsax.message_outline,
      activeIcon: Iconsax.message_bold,
      label:      'AI',
    ),
    _NavTab(
      path:       '/calendar',
      icon:       Iconsax.calendar_outline,
      activeIcon: Iconsax.calendar_bold,
      label:      'Takvim',
    ),
    _NavTab(
      path:       '/insights',
      icon:       Iconsax.chart_outline,
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
    return Scaffold(
      key: shellScaffoldKey,
      backgroundColor: _scaffoldBg,
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
    return Container(
      color: _scaffoldBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _accent.withValues(alpha: 0.04),
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
      child: SizedBox(
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
                    ? _accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                size: 22,
                color: isActive ? _accent : _textMuted,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? _accent : _textMuted,
                letterSpacing: 0.2,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
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
