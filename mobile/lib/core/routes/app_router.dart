import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/pin_login_page.dart';
import '../../features/auth/presentation/pin_setup_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/transactions/presentation/transactions_page.dart';
import '../../features/transactions/presentation/transaction_detail_page.dart';
import '../../features/agent_chat/presentation/agent_chat_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/bank_connections/presentation/bank_connections_page.dart';
import '../../features/cards/presentation/cards_page.dart';
import '../../features/loans/presentation/loans_page.dart';
import '../../features/bills/presentation/bills_page.dart';
import '../../features/subscriptions/presentation/subscriptions_page.dart';
import '../../features/budgets/presentation/budgets_page.dart';
import '../../features/goals/presentation/goals_page.dart';
import '../../features/personal_debts/presentation/personal_debts_page.dart';
import '../../features/investments/presentation/investments_page.dart';
import '../../features/fx_alerts/presentation/fx_alerts_page.dart';
import '../../features/insights/presentation/insights_page.dart';
import '../../features/negotiation/presentation/negotiation_page.dart';
import '../../features/simulator/presentation/simulator_page.dart';
import '../../features/inflation/presentation/inflation_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/receipts/presentation/receipts_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/settings/presentation/profile_page.dart';
import '../../features/insights/presentation/health_score_page.dart';
import '../widgets/bottom_nav_shell.dart';

final _rootNavigatorKey  = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Notifies GoRouter when auth state changes without recreating the router.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loading = authState.isLoading;
      final authed  = authState.isAuthenticated;
      final loc     = state.matchedLocation;

      if (loading) return '/splash';

      const publicRoutes = ['/splash', '/onboarding', '/login', '/register', '/pin-login'];
      final isPublic = publicRoutes.contains(loc);

      if (!authed && !isPublic) return '/login';
      if (authed  &&  isPublic) return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth (full-screen, no shell) ──────────────────────────────
      GoRoute(path: '/splash',     builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/login',      builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/pin-login',  builder: (_, __) => const PinLoginPage()),
      GoRoute(path: '/pin-setup', builder: (_, state) {
        final extra = state.extra;
        final isChange = extra == true ||
            (extra is Map<String, dynamic> && extra['isChange'] == true);
        final mandatory = extra is Map<String, dynamic> &&
            extra['mandatory'] == true;
        return PinSetupPage(isChange: isChange, mandatory: mandatory);
      }),

      // ── Shell (drawer always mounted) ────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            BottomNavShell(location: state.matchedLocation, child: child),
        routes: [
          // Tab routes (show bottom nav)
          GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardPage()),
          GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionsPage(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) =>
                    TransactionDetailPage(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/chat',      builder: (_, __) => const AgentChatPage()),
          GoRoute(path: '/calendar',  builder: (_, __) => const CalendarPage()),
          GoRoute(path: '/insights',  builder: (_, __) => const InsightsPage()),

          // Non-tab routes (no bottom nav, but drawer stays mounted)
          GoRoute(path: '/bank-connections', builder: (_, __) => const BankConnectionsPage()),
          GoRoute(path: '/cards',            builder: (_, __) => const CardsPage()),
          GoRoute(path: '/loans',            builder: (_, __) => const LoansPage()),
          GoRoute(path: '/bills',            builder: (_, __) => const BillsPage()),
          GoRoute(path: '/subscriptions',    builder: (_, __) => const SubscriptionsPage()),
          GoRoute(path: '/budgets',          builder: (_, __) => const BudgetsPage()),
          GoRoute(path: '/goals',            builder: (_, __) => const GoalsPage()),
          GoRoute(path: '/personal-debts',   builder: (_, __) => const PersonalDebtsPage()),
          GoRoute(path: '/investments',      builder: (_, __) => const InvestmentsPage()),
          GoRoute(path: '/fx-alerts',        builder: (_, __) => const FxAlertsPage()),
          GoRoute(path: '/negotiation',      builder: (_, __) => const NegotiationPage()),
          GoRoute(path: '/simulator',        builder: (_, __) => const SimulatorPage()),
          GoRoute(path: '/inflation',        builder: (_, __) => const InflationPage()),
          GoRoute(path: '/reports',          builder: (_, __) => const ReportsPage()),
          GoRoute(path: '/receipts',         builder: (_, __) => const ReceiptsPage()),
          GoRoute(path: '/settings',         builder: (_, __) => const SettingsPage()),
          GoRoute(path: '/profile',          builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/health-score',     builder: (_, __) => const HealthScorePage()),
        ],
      ),
    ],
  );
});
