import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _reportProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
        (ref, month) async {
  final res = await DioClient.instance
      .get(ApiEndpoints.reportSummary, queryParameters: {'month': month});
  return res.data as Map<String, dynamic>;
});

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTime _selectedMonth;
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  void _prevMonth() => setState(
      () => _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final next =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return !next.isAfter(DateTime(now.year, now.month));
  }

  Future<void> _downloadPdf() async {
    setState(() => _pdfLoading = true);
    try {
      final res = await DioClient.instance.get(
        ApiEndpoints.reportPdf,
        queryParameters: {'month': _monthKey},
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/paranette-rapor-$_monthKey.pdf');
      await file.writeAsBytes(res.data as List<int>);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Paranette Raporu $_monthKey',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF indirilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_reportProvider(_monthKey));

    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A2940)),
                      ),
                      child: const Icon(Icons.menu,
                          size: 18, color: Color(0xFF8BA4BC)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Raporlar',
                            style: AppTextStyles.headlineMedium
                                .copyWith(
                                    color: const Color(0xFFE8F4FF))),
                        Text('Aylık ve yıllık özet',
                            style: AppTextStyles.bodySmall
                                .copyWith(
                                    color: const Color(0xFF4A6478))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Month selector
            _MonthSelector(
              month: _selectedMonth,
              onPrev: _prevMonth,
              onNext: _canGoNext ? _nextMonth : null,
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF00D4FF),
                backgroundColor: const Color(0xFF0D1B2A),
                onRefresh: () async =>
                    ref.invalidate(_reportProvider(_monthKey)),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_reportProvider(_monthKey)),
                  ),
                  data: (data) => _ReportBody(
                    data: data,
                    onDownloadPdf: _pdfLoading ? null : _downloadPdf,
                    pdfLoading: _pdfLoading,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  const _MonthSelector(
      {required this.month, required this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2940)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
            Text(AppFormatters.dateMonth(month),
                style: AppTextStyles.titleMedium.copyWith(
                    color: const Color(0xFFE8F4FF),
                    fontWeight: FontWeight.w600)),
            _NavBtn(
                icon: Icons.chevron_right,
                onTap: onNext,
                disabled: onNext == null),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  const _NavBtn(
      {required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF060D18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A2940)),
        ),
        child: Icon(icon,
            size: 18,
            color: disabled
                ? const Color(0xFF4A6478)
                : const Color(0xFF8BA4BC)),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onDownloadPdf;
  final bool pdfLoading;
  const _ReportBody({
    required this.data,
    required this.onDownloadPdf,
    required this.pdfLoading,
  });

  @override
  Widget build(BuildContext context) {
    final income = (data['income'] as num?)?.toDouble() ?? 0;
    final expense = (data['expense'] as num?)?.toDouble() ?? 0;
    final net = (data['net_flow'] as num?)?.toDouble() ?? 0;
    final savingsRate = income > 0
        ? ((income - expense) / income * 100).clamp(0, 100)
        : 0.0;
    final cashFlow =
        (data['cash_flow'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    final categories =
        (data['categories'] as List?)?.cast<dynamic>() ?? [];
    final topMerchants =
        (data['top_merchants'] as List?)?.cast<dynamic>() ?? [];
    final healthScore =
        (data['health_score'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Summary cards row
        Row(
          children: [
            Expanded(
                child: _SummaryCard(
                    'Gelir',
                    income,
                    const Color(0xFF0DD9A0))),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryCard(
                    'Gider',
                    expense,
                    const Color(0xFFFF4D6D))),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryCard(
                    'Net',
                    net,
                    net >= 0
                        ? const Color(0xFF0DD9A0)
                        : const Color(0xFFFF4D6D))),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryCard(
                    'Tasarruf',
                    savingsRate.toDouble(),
                    const Color(0xFF00D4FF),
                    isPercent: true)),
          ],
        ),
        const SizedBox(height: 16),
        if (healthScore > 0) ...[
          _HealthScoreCard(score: healthScore),
          const SizedBox(height: 16),
        ],
        if (cashFlow.isNotEmpty) ...[
          Text('6 Aylık Nakit Akışı',
              style: AppTextStyles.labelSmall
                  .copyWith(color: const Color(0xFF4A6478),
                      letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _CashFlowChart(cashFlow: cashFlow),
          const SizedBox(height: 16),
        ],
        if (categories.isNotEmpty) ...[
          Text('Harcama Kategorileri',
              style: AppTextStyles.labelSmall
                  .copyWith(color: const Color(0xFF4A6478),
                      letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1A2940)),
            ),
            child: Column(
              children: categories.asMap().entries.map((entry) {
                final cat =
                    entry.value as Map<String, dynamic>;
                final total =
                    (cat['total'] as num?)?.toDouble() ?? 0;
                return Padding(
                  padding: EdgeInsets.only(
                      top: entry.key > 0 ? 10 : 0),
                  child: _CategoryRow(
                    name:
                        cat['merchant_category'] as String? ??
                            'Diğer',
                    total: total,
                    maxTotal: (categories.first
                            as Map<String, dynamic>)['total']
                        as num? ??
                        1,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (topMerchants.isNotEmpty) ...[
          Text('En Çok Harcanan Yerler',
              style: AppTextStyles.labelSmall
                  .copyWith(color: const Color(0xFF4A6478),
                      letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1A2940)),
            ),
            child: Column(
              children: topMerchants
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final merch =
                    entry.value as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10),
                  decoration: BoxDecoration(
                    border: entry.key > 0
                        ? const Border(
                            top: BorderSide(
                                color: Color(0xFF1A2940)))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF)
                              .withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            (merch['merchant_name']
                                        as String? ??
                                    '?')[0]
                                .toUpperCase(),
                            style:
                                AppTextStyles.bodySmall.copyWith(
                              color:
                                  const Color(0xFF00D4FF),
                              fontWeight: FontWeight.w700,
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
                            Text(
                                merch['merchant_name']
                                        as String? ??
                                    '',
                                style:
                                    AppTextStyles.bodyMedium
                                        .copyWith(
                                            color: const Color(
                                                0xFFE8F4FF),
                                            fontWeight:
                                                FontWeight
                                                    .w500)),
                            Text('${merch['cnt']} işlem',
                                style:
                                    AppTextStyles.bodySmall
                                        .copyWith(
                                            color: const Color(
                                                0xFF4A6478))),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.currency(
                            (merch['total'] as num?)
                                    ?.toDouble() ??
                                0),
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFFE8F4FF),
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
        // PDF download button
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onDownloadPdf,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D4FF),
              side: const BorderSide(color: Color(0xFF00D4FF)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: pdfLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00D4FF)))
                : const Icon(Icons.download_outlined, size: 18),
            label: Text(
                pdfLoading ? 'İndiriliyor...' : 'PDF İndir',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isPercent;
  const _SummaryCard(this.label, this.amount, this.color,
      {this.isPercent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2940)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: const Color(0xFF4A6478),
                      fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            isPercent
                ? '%${amount.toStringAsFixed(0)}'
                : AppFormatters.currencyCompact(amount.abs()),
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final int score;
  const _HealthScoreCard({required this.score});

  Color get _color {
    if (score >= 80) return const Color(0xFF0DD9A0);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFFF4D6D);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score',
                style: AppTextStyles.titleMedium.copyWith(
                    color: _color, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Finansal Sağlık Skoru',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF8BA4BC))),
              Text(
                score >= 80
                    ? 'Mükemmel'
                    : score >= 60
                        ? 'İyi'
                        : 'Geliştirilmeli',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: _color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<Map<String, dynamic>> cashFlow;
  const _CashFlowChart({required this.cashFlow});

  @override
  Widget build(BuildContext context) {
    final maxVal = cashFlow.fold(0.0, (prev, row) {
      final inc = (row['income'] as num?)?.toDouble() ?? 0;
      final exp = (row['expense'] as num?)?.toDouble() ?? 0;
      return [prev, inc, exp].reduce((a, b) => a > b ? a : b);
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A2940)),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= cashFlow.length) {
                    return const SizedBox();
                  }
                  final month =
                      cashFlow[idx]['month'] as String? ?? '';
                  final parts = month.split('-');
                  return Text(
                    parts.length == 2 ? parts[1] : month,
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF4A6478)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: cashFlow.asMap().entries.map((e) {
            final i = e.key;
            final row = e.value;
            final inc = (row['income'] as num?)?.toDouble() ?? 0;
            final exp =
                (row['expense'] as num?)?.toDouble() ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: inc,
                  color: const Color(0xFF0DD9A0)
                      .withValues(alpha: 0.8),
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: exp,
                  color: const Color(0xFFFF4D6D)
                      .withValues(alpha: 0.8),
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
              barsSpace: 2,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double total;
  final num maxTotal;
  const _CategoryRow(
      {required this.name,
      required this.total,
      required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final fraction = maxTotal > 0
        ? (total / maxTotal.toDouble()).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name.isEmpty ? 'Diğer' : name,
                style: AppTextStyles.bodySmall
                    .copyWith(color: const Color(0xFF8BA4BC)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              AppFormatters.currencyCompact(total),
              style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFFE8F4FF),
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: const Color(0xFF1A2940),
            valueColor: const AlwaysStoppedAnimation(
                Color(0xFF00D4FF)),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
