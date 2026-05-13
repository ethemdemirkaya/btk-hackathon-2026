import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _reportProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, month) async {
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
      () => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
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
      final file = File('${dir.path}/paranette-rapor-$_monthKey.pdf');
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: const Icon(Icons.menu,
                          size: 16, color: AppColors.text2Dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Aylık Rapor',
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: AppColors.text1Dark)),
                  ),
                  GestureDetector(
                    onTap: _pdfLoading ? null : _downloadPdf,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: _pdfLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined,
                              size: 16, color: AppColors.text2Dark),
                    ),
                  ),
                ],
              ),
            ),
            _MonthSelector(
              month: _selectedMonth,
              onPrev: _prevMonth,
              onNext: _canGoNext ? _nextMonth : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(_reportProvider(_monthKey)),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_reportProvider(_monthKey)),
                  ),
                  data: (data) => _ReportBody(data: data),
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
  const _MonthSelector({required this.month, required this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(AppFormatters.dateMonth(month), style: AppTextStyles.titleMedium),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: onNext == null ? Colors.grey.shade400 : null),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReportBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final income = (data['income'] as num?)?.toDouble() ?? 0;
    final expense = (data['expense'] as num?)?.toDouble() ?? 0;
    final net = (data['net_flow'] as num?)?.toDouble() ?? 0;
    final cashFlow = (data['cash_flow'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final categories = (data['categories'] as List?)?.cast<dynamic>() ?? [];
    final topMerchants = (data['top_merchants'] as List?)?.cast<dynamic>() ?? [];
    final healthScore = (data['health_score'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryRow(income: income, expense: expense, net: net),
        const SizedBox(height: 16),
        if (healthScore > 0) ...[
          _HealthScoreCard(score: healthScore),
          const SizedBox(height: 16),
        ],
        if (cashFlow.isNotEmpty) ...[
          Text('6 Aylık Nakit Akışı', style: AppTextStyles.labelMedium),
          const SizedBox(height: 12),
          _CashFlowChart(cashFlow: cashFlow),
          const SizedBox(height: 16),
        ],
        if (categories.isNotEmpty) ...[
          Text('Harcama Kategorileri', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          ...categories.map((c) {
            final cat = c as Map<String, dynamic>;
            final total = (cat['total'] as num?)?.toDouble() ?? 0;
            return _CategoryRow(
              name: cat['merchant_category'] as String? ?? 'Diğer',
              total: total,
              maxTotal: (categories.first as Map<String, dynamic>)['total'] as num? ?? 1,
            );
          }),
          const SizedBox(height: 16),
        ],
        if (topMerchants.isNotEmpty) ...[
          Text('En Çok Harcanan Yerler', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          ...topMerchants.take(5).map((m) {
            final merch = m as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (merch['merchant_name'] as String? ?? '?')[0].toUpperCase(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(merch['merchant_name'] as String? ?? '',
                  style: AppTextStyles.bodyMedium),
              subtitle: Text(
                '${merch['cnt']} işlem',
                style: AppTextStyles.bodySmall,
              ),
              trailing: Text(
                AppFormatters.currency((merch['total'] as num?)?.toDouble() ?? 0),
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final double net;
  const _SummaryRow({required this.income, required this.expense, required this.net});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard('Gelir', income, AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard('Gider', expense, AppColors.danger)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard('Net', net, net >= 0 ? AppColors.success : AppColors.danger)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryCard(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            AppFormatters.currencyCompact(amount.abs()),
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
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
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _color.withValues(alpha: 0.2),
            child: Text(
              '$score',
              style: AppTextStyles.titleMedium.copyWith(color: _color),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Finansal Sağlık Skoru', style: AppTextStyles.bodySmall),
              Text(
                score >= 80 ? 'Mükemmel' : score >= 60 ? 'İyi' : 'Geliştirilmeli',
                style: AppTextStyles.bodyMedium.copyWith(color: _color, fontWeight: FontWeight.w700),
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

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= cashFlow.length) return const SizedBox();
                  final month = cashFlow[idx]['month'] as String? ?? '';
                  final parts = month.split('-');
                  return Text(
                    parts.length == 2 ? parts[1] : month,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
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
            final exp = (row['expense'] as num?)?.toDouble() ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: inc,
                  color: AppColors.success.withValues(alpha: 0.8),
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: exp,
                  color: AppColors.danger.withValues(alpha: 0.8),
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
  const _CategoryRow({required this.name, required this.total, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final fraction = maxTotal > 0 ? (total / maxTotal.toDouble()).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Diğer' : name,
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                AppFormatters.currencyCompact(total),
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.borderLight,
            color: AppColors.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
