import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';

class SimulatorPage extends StatefulWidget {
  const SimulatorPage({super.key});

  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage> {
  // Slider values
  double _incomeChangePct = 0; // -50 to +100
  double _expenseChangePct = 0; // -50 to +100
  int _months = 12;

  // Extra income/expense (manual entry)
  final _extraIncomeCtrl = TextEditingController();
  final _extraExpenseCtrl = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _extraIncomeCtrl.dispose();
    _extraExpenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final extraIncome =
          double.tryParse(_extraIncomeCtrl.text.replaceAll(',', '.')) ?? 0;
      final extraExpense =
          double.tryParse(_extraExpenseCtrl.text.replaceAll(',', '.')) ?? 0;

      final res = await DioClient.instance.post(
        ApiEndpoints.simulatorCalculate,
        data: {
          'income_change_pct': _incomeChangePct,
          'expense_change_pct': _expenseChangePct,
          'extra_monthly_income': extraIncome,
          'extra_monthly_expense': extraExpense,
          'months': _months,
        },
      );
      setState(() {
        _result = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Hesaplama yapılamadı.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karar Simülatörü')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScenarioCard(
              incomeChangePct: _incomeChangePct,
              expenseChangePct: _expenseChangePct,
              months: _months,
              extraIncomeCtrl: _extraIncomeCtrl,
              extraExpenseCtrl: _extraExpenseCtrl,
              onIncomeChanged: (v) =>
                  setState(() => _incomeChangePct = v),
              onExpenseChanged: (v) =>
                  setState(() => _expenseChangePct = v),
              onMonthsChanged: (v) => setState(() => _months = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _calculate,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.calculate),
                label: const Text('Simüle Et'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultSection(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final double incomeChangePct;
  final double expenseChangePct;
  final int months;
  final TextEditingController extraIncomeCtrl;
  final TextEditingController extraExpenseCtrl;
  final ValueChanged<double> onIncomeChanged;
  final ValueChanged<double> onExpenseChanged;
  final ValueChanged<int> onMonthsChanged;

  const _ScenarioCard({
    required this.incomeChangePct,
    required this.expenseChangePct,
    required this.months,
    required this.extraIncomeCtrl,
    required this.extraExpenseCtrl,
    required this.onIncomeChanged,
    required this.onExpenseChanged,
    required this.onMonthsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Senaryo Parametreleri',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),

            // Income slider
            _SliderRow(
              label: 'Gelir Değişimi',
              value: incomeChangePct,
              min: -50,
              max: 100,
              suffix: '%',
              color: incomeChangePct >= 0
                  ? AppColors.success
                  : AppColors.danger,
              onChanged: onIncomeChanged,
            ),
            const SizedBox(height: 12),

            // Expense slider
            _SliderRow(
              label: 'Gider Değişimi',
              value: expenseChangePct,
              min: -50,
              max: 100,
              suffix: '%',
              color: expenseChangePct <= 0
                  ? AppColors.success
                  : AppColors.danger,
              onChanged: onExpenseChanged,
            ),
            const SizedBox(height: 16),

            // Extra fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: extraIncomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ek Gelir (₺/ay)',
                      prefixIcon: Icon(Icons.add_circle_outline,
                          color: AppColors.success),
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: extraExpenseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ek Gider (₺/ay)',
                      prefixIcon: Icon(Icons.remove_circle_outline,
                          color: AppColors.danger),
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Months selector
            Text('Süre: $months ay', style: AppTextStyles.bodyMedium),
            Slider(
              value: months.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '$months ay',
              onChanged: (v) => onMonthsChanged(v.toInt()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sign = value >= 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$sign${value.toStringAsFixed(0)}$suffix',
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ResultSection extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final current = result['current'] as Map<String, dynamic>? ?? {};
    final projected = result['projected'] as Map<String, dynamic>? ?? {};
    final months = result['months'] as int? ?? 12;
    final monthlySavingsCurrent =
        (current['monthly_savings'] as num?)?.toDouble() ?? 0;
    final monthlySavingsProjected =
        (projected['monthly_savings'] as num?)?.toDouble() ?? 0;
    final totalSavings =
        (projected['total_savings_over_period'] as num?)?.toDouble() ?? 0;
    final breakEven = result['break_even_month'] as int?;
    final aiComment = result['ai_comment'] as String?;
    final timeline = result['monthly_timeline'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sonuçlar ($months ay)', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Mevcut Aylık Tasarruf',
                value: AppFormatters.currency(monthlySavingsCurrent),
                color: monthlySavingsCurrent >= 0
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Tahmini Aylık Tasarruf',
                value: AppFormatters.currency(monthlySavingsProjected),
                color: monthlySavingsProjected >= 0
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: '$months Ay Toplam Birikim',
          value: AppFormatters.currency(totalSavings),
          color: totalSavings >= 0 ? AppColors.success : AppColors.danger,
          large: true,
        ),
        if (breakEven != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Başabaş noktası: $breakEven. ay',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Monthly timeline mini chart
        if (timeline.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Aylık Tasarruf Trendi',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          _TimelineChart(timeline: timeline),
        ],

        if (aiComment != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text('AI Analizi',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(aiComment,
                    style: const TextStyle(color: Colors.white, height: 1.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool large;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.color,
      this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(value,
              style: large
                  ? AppTextStyles.amountLarge.copyWith(color: color)
                  : AppTextStyles.titleMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TimelineChart extends StatelessWidget {
  final List timeline;
  const _TimelineChart({required this.timeline});

  @override
  Widget build(BuildContext context) {
    final values = timeline
        .map((e) =>
            (e as Map<String, dynamic>)['savings'] as num? ?? 0)
        .map((n) => n.toDouble())
        .toList();

    if (values.isEmpty) return const SizedBox.shrink();

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();
    final effectiveRange = range == 0 ? 1.0 : range;

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.asMap().entries.map((entry) {
          final val = entry.value;
          final normalised = range == 0
              ? 0.5
              : ((val - minVal) / effectiveRange).clamp(0.0, 1.0);
          final color =
              val >= 0 ? AppColors.success : AppColors.danger;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: (0.1 + normalised * 0.9).clamp(0.1, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                  if (values.length <= 12)
                    Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.textSecondaryLight),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
