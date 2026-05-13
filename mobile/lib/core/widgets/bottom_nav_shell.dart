import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_drawer.dart';

final shellScaffoldKey = GlobalKey<ScaffoldState>();

class BottomNavShell extends StatelessWidget {
  final Widget child;
  final String location;

  const BottomNavShell({
    super.key,
    required this.child,
    required this.location,
  });

  static const _tabs = [
    _NavTab(path: '/dashboard', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Ana Sayfa'),
    _NavTab(path: '/transactions', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'İşlemler'),
    _NavTab(path: '/chat', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'AI'),
    _NavTab(path: '/calendar', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Takvim'),
    _NavTab(path: '/insights', icon: Icons.insights_outlined, activeIcon: Icons.insights, label: 'Öngörüler'),
  ];

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
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
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
