import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
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
const _heroBgFrom = Color(0xFF0A1929);
const _heroBgTo   = Color(0xFF0D2240);

// ── Dashboard page ─────────────────────────────────────────────────────────
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: _cardBg,
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _GreetingHeader()),
            dashboard.when(
              loading: () => const SliverFillRemaining(
                child: _DashboardSkeleton(),
              ),
              error: (e, __) => SliverFillRemaining(
                child: ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(dashboardProvider),
                ),
              ),
              data: (data) => _DashboardBody(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const SkeletonCard(height: 180),
        const SizedBox(height: 16),
        const SkeletonCard(height: 88),
        const SizedBox(height: 16),
        const SkeletonCard(height: 56),
        const SizedBox(height: 16),
        ...List.generate(4, (_) => const SkeletonListItem()),
      ],
    );
  }
}

// ── Greeting header ────────────────────────────────────────────────────────
class _GreetingHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Günaydın' : hour < 18 ? 'İyi günler' : 'İyi akşamlar';
    final firstName = user?.name.split(' ').first ?? 'Kullanıcı';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
      child: Row(
        children: [
          // Hamburger menu
          _HeaderIconBtn(
            icon: Icons.menu,
            onTap: () => shellScaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          // Center greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
              ),
              Text(
                firstName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text1),
              ),
            ],
          ),
          const Spacer(),
          // AI Insights button
          AiInsightsButton(page: 'dashboard'),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Icon(icon, size: 18, color: _text2),
      ),
    );
  }
}

// ── Dashboard body ─────────────────────────────────────────────────────────
class _DashboardBody extends StatefulWidget {
  final DashboardData data;
  const _DashboardBody({required this.data});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool _hideBalance = false;
  late List<SmartAlert> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = List.from(widget.data.smartAlerts);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Hero balance card ──
        _HeroBalanceCard(
          summary: data.summary,
          hide: _hideBalance,
          onToggleHide: () => setState(() => _hideBalance = !_hideBalance),
        ),
        const SizedBox(height: 16),
        // ── Quick stats 2×2 grid ──
        _QuickStatsGrid(summary: data.summary, hide: _hideBalance),
        const SizedBox(height: 20),
        // ── Quick access chips ──
        _QuickAccessSection(),
        const SizedBox(height: 20),
        // ── Health score card ──
        _HealthScoreCard(score: data.summary.healthScore),
        const SizedBox(height: 20),
        // ── Cash flow chart ──
        if (data.cashFlow.isNotEmpty) ...[
          _SectionHeader(
            title: 'Nakit Akışı',
            action: 'Detay',
            onAction: () => context.push('/reports'),
          ),
          _CashFlowChart(cashFlow: data.cashFlow),
          const SizedBox(height: 20),
        ],
        // ── AI smart alerts / insight card ──
        if (_alerts.isNotEmpty) ...[
          _SectionHeader(
            title: 'AI Öngörüleri',
            action: '${_alerts.length}',
          ),
          ..._alerts.take(2).map((a) => _AiInsightCard(
                alert: a,
                onDismiss: () => setState(() => _alerts.remove(a)),
              )),
          const SizedBox(height: 20),
        ],
        // ── Budget summary ──
        if (data.budgetSummary.isNotEmpty) ...[
          _SectionHeader(
            title: 'Bütçeler',
            action: 'Tümünü gör',
            onAction: () => context.push('/budgets'),
          ),
          _BudgetCard(items: data.budgetSummary),
          const SizedBox(height: 20),
        ],
        // ── Category spend ──
        if (data.categorySpend.isNotEmpty) ...[
          _SectionHeader(
            title: 'Bu ay nereye harcadın',
            action: 'Tümü',
            onAction: () => context.push('/transactions'),
          ),
          _CategorySpendCard(items: data.categorySpend),
          const SizedBox(height: 20),
        ],
        // ── Personal inflation ──
        if (data.personalInflation != null) ...[
          _InflationCard(inflation: data.personalInflation!),
          const SizedBox(height: 20),
        ],
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Hero balance card ──────────────────────────────────────────────────────
class _HeroBalanceCard extends StatelessWidget {
  final DashboardSummary summary;
  final bool hide;
  final VoidCallback onToggleHide;

  const _HeroBalanceCard({
    required this.summary,
    required this.hide,
    required this.onToggleHide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_heroBgFrom, _heroBgTo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cardBorder),
        ),
        child: Stack(
          children: [
            // Cyan left accent bar
            Positioned(
              left: 0,
              top: 24,
              bottom: 24,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, Color(0xFF0066FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: label + eye toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam Varlık',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text2, letterSpacing: 0.6),
                      ),
                      GestureDetector(
                        onTap: onToggleHide,
                        child: Icon(
                          hide
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: _text2,
                        ),
                      ),
                    ],
                  ),
                  // Balance amount
                  Text(
                    hide ? '••••••' : AppFormatters.currency(summary.netWorth),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _text1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  // Change indicator
                  Row(
                    children: [
                      _ChangePill(
                        value: '+%2.4',
                        isPositive: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'geçen aya göre',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                      ),
                    ],
                  ),
                  // Bottom row: banks + last update
                  Row(
                    children: [
                      const Icon(Icons.account_balance_outlined,
                          size: 13, color: _text3),
                      const SizedBox(width: 5),
                      Text(
                        '3 banka bağlı',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: _text3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_outlined,
                          size: 11, color: _text3),
                      const SizedBox(width: 4),
                      Text(
                        'Son güncelleme: bugün',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  final String value;
  final bool isPositive;

  const _ChangePill({required this.value, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? _positive : _negative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick stats 2×2 grid ───────────────────────────────────────────────────
class _QuickStatsGrid extends StatelessWidget {
  final DashboardSummary summary;
  final bool hide;
  const _QuickStatsGrid({required this.summary, required this.hide});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.arrow_downward_rounded,
        iconColor: _positive,
        label: 'Gelir',
        value: hide
            ? '••••'
            : AppFormatters.currencyCompact(summary.totalBalance),
        onTap: () => context.push('/transactions'),
      ),
      _StatItem(
        icon: Icons.arrow_upward_rounded,
        iconColor: _negative,
        label: 'Gider',
        value: hide
            ? '••••'
            : AppFormatters.currencyCompact(summary.totalCardDebt),
        onTap: () => context.push('/cards'),
      ),
      _StatItem(
        icon: Icons.savings_outlined,
        iconColor: _accent,
        label: 'Tasarruf',
        value: hide
            ? '••••'
            : AppFormatters.currencyCompact(summary.totalLoan),
        onTap: () => context.push('/loans'),
      ),
      _StatItem(
        icon: Icons.psychology_outlined,
        iconColor: _warning,
        label: 'AI Skoru',
        value: '${summary.healthScore}',
        onTap: () => context.push('/health-score'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
        children: items
            .map((item) => _QuickStatCard(item: item))
            .toList(),
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });
}

class _QuickStatCard extends StatelessWidget {
  final _StatItem item;
  const _QuickStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 16, color: item.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _text1,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _text3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick access section ───────────────────────────────────────────────────
class _QuickAccessSection extends StatefulWidget {
  @override
  State<_QuickAccessSection> createState() => _QuickAccessSectionState();
}

class _QuickAccessSectionState extends State<_QuickAccessSection> {
  int _activeIndex = -1;

  static const _chips = [
    _ChipItem(icon: Icons.receipt_long_outlined, label: 'İşlemler', route: '/transactions'),
    _ChipItem(icon: Icons.pie_chart_outline, label: 'Bütçeler', route: '/budgets'),
    _ChipItem(icon: Icons.flag_outlined, label: 'Hedefler', route: '/goals'),
    _ChipItem(icon: Icons.trending_up_outlined, label: 'Yatırımlar', route: '/investments'),
    _ChipItem(icon: Icons.account_balance_outlined, label: 'Krediler', route: '/loans'),
    _ChipItem(icon: Icons.bolt_outlined, label: 'Faturalar', route: '/bills'),
    _ChipItem(icon: Icons.repeat_outlined, label: 'Abonelikler', route: '/subscriptions'),
    _ChipItem(icon: Icons.notifications_active_outlined, label: 'Kur Alarmları', route: '/fx-alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'Hızlı Erişim',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text1),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _chips.length,
            itemBuilder: (context, index) {
              final chip = _chips[index];
              final isActive = _activeIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _activeIndex = index);
                  context.push(chip.route);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _accent.withValues(alpha: 0.15)
                        : _cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive ? _accent : _cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chip.icon,
                        size: 14,
                        color: isActive ? _accent : _text2,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        chip.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? _accent : _text2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChipItem {
  final IconData icon;
  final String label;
  final String route;
  const _ChipItem({required this.icon, required this.label, required this.route});
}

// ── Section header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text1),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text2),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Health score card ──────────────────────────────────────────────────────
class _HealthScoreCard extends StatelessWidget {
  final int score;
  const _HealthScoreCard({required this.score});

  Color get _color {
    if (score >= 80) return _positive;
    if (score >= 60) return _warning;
    return _negative;
  }

  String get _label {
    if (score >= 80) return 'İyi gidiyorsun!';
    if (score >= 60) return 'Finansal durumun iyi, geliştirilebilir.';
    return 'Dikkat! Finansal sağlığın zayıf.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push('/health-score'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      backgroundColor: _color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(_color),
                      strokeWidth: 7,
                    ),
                    Text(
                      '$score',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _color),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finansal Sağlık',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text2, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _positive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward,
                              size: 10, color: _positive),
                          const SizedBox(width: 2),
                          Text(
                            '+3 son 30 gün',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _positive),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: _text3),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cash flow chart ────────────────────────────────────────────────────────
class _CashFlowChart extends StatelessWidget {
  final List<CashFlowPoint> cashFlow;
  const _CashFlowChart({required this.cashFlow});

  @override
  Widget build(BuildContext context) {
    if (cashFlow.isEmpty) return const SizedBox();
    final maxVal = cashFlow
        .expand((e) => [e.income, e.expenses])
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.2,
                  barGroups: List.generate(cashFlow.length, (i) {
                    final p = cashFlow[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: p.income,
                          color: _accent,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: p.expenses,
                          color: _negative.withValues(alpha: 0.8),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= cashFlow.length) return const SizedBox();
                          final period = cashFlow[i].period;
                          final parts = period.split('-');
                          return Text(
                            parts.length > 1 ? parts[1] : period,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChartLegend(color: _accent, label: 'Gelir'),
                const SizedBox(width: 16),
                _ChartLegend(
                    color: _negative.withValues(alpha: 0.8), label: 'Gider'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
      ],
    );
  }
}

// ── AI insight card ────────────────────────────────────────────────────────
class _AiInsightCard extends StatelessWidget {
  final SmartAlert alert;
  final VoidCallback onDismiss;
  const _AiInsightCard({required this.alert, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: _heroBgFrom,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: const BorderSide(color: _accent, width: 3),
            top: BorderSide(color: _cardBorder),
            right: BorderSide(color: _cardBorder),
            bottom: BorderSide(color: _cardBorder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 10,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Önerisi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(Icons.close, size: 16, color: _text3),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                alert.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1),
              ),
              const SizedBox(height: 4),
              // Body
              Text(
                alert.body,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text2, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Action row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/chat'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sohbet et',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward,
                            size: 12, color: _accent),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Text(
                      'Sonra',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Budget card ────────────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  final List<BudgetSummaryItem> items;
  const _BudgetCard({required this.items});

  static const _categoryColors = [
    _accent,
    Color(0xFFA78BFA),
    Color(0xFFFF5C7C),
    Color(0xFFFFC857),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: items.take(3).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final color = _categoryColors[idx % _categoryColors.length];
            final pct = (item.pct / 100).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.category,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text1),
                        ),
                      ),
                      Text(
                        '${AppFormatters.currencyCompact(item.spent)} / ${AppFormatters.currencyCompact(item.budgeted)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: item.overBudget ? _negative : _text2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(
                          item.overBudget ? _negative : color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Category spend card ────────────────────────────────────────────────────
class _CategorySpendCard extends StatelessWidget {
  final List<CategorySpend> items;
  const _CategorySpendCard({required this.items});

  static const _colors = [
    _accent,
    Color(0xFFA78BFA),
    _negative,
    _warning,
    Color(0xFF6FB1FC),
  ];

  @override
  Widget build(BuildContext context) {
    final top = items.take(4).toList();
    final total = top.fold(0.0, (s, e) => s + e.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: top.asMap().entries.map((e) {
                    final pct = total > 0 ? e.value.amount / total : 0.0;
                    return Expanded(
                      flex: (pct * 100).toInt().clamp(1, 100),
                      child: Container(
                          color: _colors[e.key % _colors.length]),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...top.asMap().entries.map((entry) {
              final color = _colors[entry.key % _colors.length];
              final item = entry.value;
              final pct = total > 0 ? item.amount / total * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.category,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text1),
                      ),
                    ),
                    Text(
                      '%${pct.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 72,
                      child: Text(
                        AppFormatters.currencyCompact(item.amount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text1),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Inflation card ─────────────────────────────────────────────────────────
class _InflationCard extends StatelessWidget {
  final PersonalInflation inflation;
  const _InflationCard({required this.inflation});

  @override
  Widget build(BuildContext context) {
    final isAbove = inflation.diff > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push('/inflation'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, size: 20, color: _warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senin enflasyonun',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text3),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '%${inflation.personalRate.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text1, letterSpacing: -0.36),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'vs TÜFE %${inflation.tufeRate.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ChangePill(
                value: '${inflation.diff.toStringAsFixed(1)}p',
                isPositive: !isAbove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
