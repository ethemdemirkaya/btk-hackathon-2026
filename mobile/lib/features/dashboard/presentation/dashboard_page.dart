import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.bg2,
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _GreetingHeader()),
            dashboard.when(
              loading: () => const SliverFillRemaining(
                  child: SkeletonListView(count: 6)),
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

// ── Greeting header ────────────────────────────────────────────────
class _GreetingHeader extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends ConsumerState<_GreetingHeader> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Günaydın' : hour < 18 ? 'İyi günler' : 'İyi akşamlar';
    final firstName = user?.name.split(' ').first ?? 'Kullanıcı';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
      child: Row(
        children: [
          // Hamburger menu — far left
          _IconBtn(
            icon: Icons.menu,
            onTap: () => shellScaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 12),
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet,
                size: 18, color: AppColors.accentText),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text3Dark)),
              Text(firstName,
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.text1Dark)),
            ],
          ),
          const Spacer(),
          // Hide balance toggle
          _IconBtn(
            icon: _hideBalance
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onTap: () => setState(() => _hideBalance = !_hideBalance),
          ),
          const SizedBox(width: 8),
          // Notifications
          _IconBtn(
            icon: Icons.notifications_outlined,
            onTap: () => context.push('/insights'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Icon(icon, size: 18, color: AppColors.text2Dark),
      ),
    );
  }
}

// ── Dashboard body ──────────────────────────────────────────────────
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
        // Net worth hero
        _NetWorthHero(
          summary: data.summary,
          hide: _hideBalance,
          onToggleHide: () => setState(() => _hideBalance = !_hideBalance),
          onReport: () => context.push('/reports'),
        ),
        const SizedBox(height: 16),
        // Quick stats 2×2 grid
        _QuickStatsGrid(summary: data.summary, hide: _hideBalance),
        const SizedBox(height: 20),
        // Health score card
        _HealthScoreCard(score: data.summary.healthScore),
        const SizedBox(height: 20),
        // Cash flow chart
        if (data.cashFlow.isNotEmpty) ...[
          _SectionHeader(
              title: 'Nakit Akışı',
              action: 'Detay',
              onAction: () => context.push('/reports')),
          _CashFlowChart(cashFlow: data.cashFlow),
          const SizedBox(height: 20),
        ],
        // AI Smart alerts
        if (_alerts.isNotEmpty) ...[
          _SectionHeader(
              title: 'AI Öngörüleri',
              action: '${_alerts.length}'),
          ..._alerts.take(2).map((a) => _SmartAlertCard(
                alert: a,
                onDismiss: () => setState(() => _alerts.remove(a)),
              )),
          const SizedBox(height: 20),
        ],
        // Budget summary
        if (data.budgetSummary.isNotEmpty) ...[
          _SectionHeader(
              title: 'Bütçeler',
              action: 'Tümünü gör',
              onAction: () => context.push('/budgets')),
          _BudgetCard(items: data.budgetSummary),
          const SizedBox(height: 20),
        ],
        // Category spend
        if (data.categorySpend.isNotEmpty) ...[
          _SectionHeader(
              title: 'Bu ay nereye harcadın',
              action: 'Tümü',
              onAction: () => context.push('/transactions')),
          _CategorySpendCard(items: data.categorySpend),
          const SizedBox(height: 20),
        ],
        // Personal inflation
        if (data.personalInflation != null) ...[
          _InflationCard(inflation: data.personalInflation!),
          const SizedBox(height: 20),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ── Net worth hero ──────────────────────────────────────────────────
class _NetWorthHero extends StatelessWidget {
  final DashboardSummary summary;
  final bool hide;
  final VoidCallback onToggleHide;
  final VoidCallback onReport;
  const _NetWorthHero(
      {required this.summary,
      required this.hide,
      required this.onToggleHide,
      required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net varlık',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.text3Dark,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08 * 11)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hide ? '••••••' : AppFormatters.currency(summary.netWorth),
                style: AppTextStyles.amountHero.copyWith(
                  color: AppColors.text1Dark,
                  fontSize: 40,
                  letterSpacing: -0.03 * 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward,
                        size: 11, color: AppColors.positive),
                    const SizedBox(width: 3),
                    Text(
                      '+2.4%',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.positive),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('geçen aya göre',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text3Dark)),
              const Spacer(),
              GestureDetector(
                onTap: onReport,
                child: Row(
                  children: [
                    Text('Rapor',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.text2Dark)),
                    const Icon(Icons.chevron_right,
                        size: 14, color: AppColors.text2Dark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick stats 2x2 ──────────────────────────────────────────────────
class _QuickStatsGrid extends StatelessWidget {
  final DashboardSummary summary;
  final bool hide;
  const _QuickStatsGrid({required this.summary, required this.hide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.credit_card_outlined,
              label: 'Kart borcu',
              value: hide
                  ? '••••'
                  : AppFormatters.currencyCompact(summary.totalCardDebt),
              onTap: () => context.push('/cards'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.account_balance_outlined,
              label: 'Kredi bakiyesi',
              value: hide
                  ? '••••'
                  : AppFormatters.currencyCompact(summary.totalLoan),
              onTap: () => context.push('/loans'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  const _QuickStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.text3Dark),
                const SizedBox(width: 4),
                Text(label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.text3Dark)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.amountMedium.copyWith(
                color: valueColor ?? AppColors.text1Dark,
                letterSpacing: -0.02 * 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text2Dark)),
            ),
        ],
      ),
    );
  }
}

// ── Health score ───────────────────────────────────────────────────
class _HealthScoreCard extends StatelessWidget {
  final int score;
  const _HealthScoreCard({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.positive;
    if (score >= 60) return AppColors.warning;
    return AppColors.negative;
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
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border1Dark),
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
                    Text('$score',
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: _color)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finansal Sağlık',
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_label,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.text2Dark,
                                height: 1.5)),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.positive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward,
                              size: 10, color: AppColors.positive),
                          const SizedBox(width: 2),
                          Text('+3 son 30 gün',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.positive)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cash flow chart ─────────────────────────────────────────────────
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
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
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
                          color: AppColors.accent,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: p.expenses,
                          color: AppColors.negative.withValues(alpha: 0.8),
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
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.text3Dark),
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
                _ChartLegend(color: AppColors.accent, label: 'Gelir'),
                const SizedBox(width: 16),
                _ChartLegend(
                    color: AppColors.negative.withValues(alpha: 0.8),
                    label: 'Gider'),
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
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.text3Dark)),
      ],
    );
  }
}

// ── Smart alert card ─────────────────────────────────────────────────
class _SmartAlertCard extends StatelessWidget {
  final SmartAlert alert;
  final VoidCallback onDismiss;
  const _SmartAlertCard({required this.alert, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHint(alert.type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bg1, AppColors.bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    alert.body,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.text2Dark, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/chat'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Detay',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.accentText,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Text('Sonra',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.text2Dark)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close,
                  size: 16, color: AppColors.text3Dark),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Budget card ──────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  final List<BudgetSummaryItem> items;
  const _BudgetCard({required this.items});

  static const _categoryColors = [
    AppColors.accent,
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
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
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
                        child: Text(item.category,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        '${AppFormatters.currencyCompact(item.spent)} / ${AppFormatters.currencyCompact(item.budgeted)}',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: item.overBudget
                                ? AppColors.negative
                                : AppColors.text2Dark,
                            fontWeight: FontWeight.w500),
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
                          item.overBudget ? AppColors.negative : color),
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

// ── Category spend card ─────────────────────────────────────────────
class _CategorySpendCard extends StatelessWidget {
  final List<CategorySpend> items;
  const _CategorySpendCard({required this.items});

  static const _colors = [
    AppColors.accent,
    Color(0xFFA78BFA),
    AppColors.negative,
    AppColors.warning,
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
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
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
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.category,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      '%${pct.toStringAsFixed(0)}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text3Dark),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 72,
                      child: Text(
                        AppFormatters.currencyCompact(item.amount),
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ── Inflation card ──────────────────────────────────────────────────
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
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border1Dark),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up,
                    size: 20, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Senin enflasyonun',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.text3Dark)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '%${inflation.personalRate.toStringAsFixed(1)}',
                          style: AppTextStyles.amountMedium.copyWith(
                              letterSpacing: -0.02 * 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'vs TÜFE %${inflation.tufeRate.toStringAsFixed(1)}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.text3Dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isAbove ? AppColors.negative : AppColors.positive)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isAbove
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 10,
                        color: isAbove
                            ? AppColors.negative
                            : AppColors.positive),
                    const SizedBox(width: 2),
                    Text(
                      '${inflation.diff.toStringAsFixed(1)}p',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: isAbove
                              ? AppColors.negative
                              : AppColors.positive),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
