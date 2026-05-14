import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';

// ── Design tokens ────────────────────────────────────────────────────
const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _positive   = Color(0xFF0DD9A0);
const _negative   = Color(0xFFFF4D6D);

// ── Page ──────────────────────────────────────────────────────────────
class SimulatorPage extends StatefulWidget {
  const SimulatorPage({super.key});

  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage>
    with SingleTickerProviderStateMixin {
  // Scenario type
  int _scenarioTab = 0; // 0=Kredi 1=Yatırım 2=Tasarruf

  // Sliders
  double _incomeChangePct = 0;
  double _expenseChangePct = 0;
  int _months = 12;

  // Text fields
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
      final extraIncome = double.tryParse(
              _extraIncomeCtrl.text.replaceAll(',', '.')) ??
          0;
      final extraExpense = double.tryParse(
              _extraExpenseCtrl.text.replaceAll(',', '.')) ??
          0;

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
        _error =
            e.response?.data?['message'] ?? 'Hesaplama yapılamadı.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Icon(Icons.menu,
                          size: 18, color: _text2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finansal Simülatör',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _text1)),
                        Text('Senaryoları karşılaştır',
                            style: TextStyle(
                                fontSize: 12, color: _text3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Scenario type pills ──────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardBorder),
                ),
                child: Row(
                  children: [
                    _PillTab(
                        label: 'Kredi',
                        selected: _scenarioTab == 0,
                        onTap: () =>
                            setState(() => _scenarioTab = 0)),
                    _PillTab(
                        label: 'Yatırım',
                        selected: _scenarioTab == 1,
                        onTap: () =>
                            setState(() => _scenarioTab = 1)),
                    _PillTab(
                        label: 'Tasarruf',
                        selected: _scenarioTab == 2,
                        onTap: () =>
                            setState(() => _scenarioTab = 2)),
                  ],
                ),
              ),
            ),
            // ── Scrollable content ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ── Input card ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Senaryo Parametreleri',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _text1)),
                          const SizedBox(height: 16),
                          // Income slider
                          _SliderRow(
                            label: 'Gelir Değişimi',
                            value: _incomeChangePct,
                            min: -50,
                            max: 100,
                            color: _incomeChangePct >= 0
                                ? _positive
                                : _negative,
                            onChanged: (v) => setState(
                                () => _incomeChangePct = v),
                          ),
                          const SizedBox(height: 12),
                          // Expense slider
                          _SliderRow(
                            label: 'Gider Değişimi',
                            value: _expenseChangePct,
                            min: -50,
                            max: 100,
                            color: _expenseChangePct <= 0
                                ? _positive
                                : _negative,
                            onChanged: (v) => setState(
                                () => _expenseChangePct = v),
                          ),
                          const SizedBox(height: 16),
                          // Extra fields
                          Row(
                            children: [
                              Expanded(
                                child: _darkNumberField(
                                  _extraIncomeCtrl,
                                  'Ek Gelir (₺/ay)',
                                  Icons.add_circle_outline,
                                  _positive,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _darkNumberField(
                                  _extraExpenseCtrl,
                                  'Ek Gider (₺/ay)',
                                  Icons.remove_circle_outline,
                                  _negative,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Months
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Süre',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _text2)),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(
                                      alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_months ay',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: _accent),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context)
                                .copyWith(
                              activeTrackColor: _accent,
                              thumbColor: _accent,
                              inactiveTrackColor:
                                  _accent.withValues(alpha: 0.15),
                              overlayColor:
                                  _accent.withValues(alpha: 0.1),
                            ),
                            child: Slider(
                              value: _months.toDouble(),
                              min: 1,
                              max: 60,
                              divisions: 59,
                              label: '$_months ay',
                              onChanged: (v) => setState(
                                  () => _months = v.toInt()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── Calculate button ──────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _loading ? null : _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor:
                              const Color(0xFF051929),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                            : const Icon(Icons.calculate,
                                size: 18),
                        label: const Text('Simüle Et',
                            style: TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    // ── Error ─────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _negative.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                              color: _negative.withValues(
                                  alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: _negative, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: _negative)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // ── Results ───────────────────────────────
                    if (_result != null) ...[
                      const SizedBox(height: 20),
                      _ResultSection(result: _result!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkNumberField(TextEditingController ctrl,
      String label, IconData icon, Color color) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: _text1, fontSize: 13),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _text3, fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: color),
        isDense: true,
        filled: true,
        fillColor: _scaffoldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cardBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cardBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: _accent, width: 1.5)),
      ),
    );
  }
}

// ── Pill tab ──────────────────────────────────────────────────────────
class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillTab(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF051929)
                      : _text3),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Slider row ────────────────────────────────────────────────────────
class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
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
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: _text2)),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$sign${value.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor:
                color.withValues(alpha: 0.15),
            overlayColor: color.withValues(alpha: 0.1),
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

// ── Result section ────────────────────────────────────────────────────
class _ResultSection extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final current =
        result['current'] as Map<String, dynamic>? ?? {};
    final projected =
        result['projected'] as Map<String, dynamic>? ?? {};
    final months = result['months'] as int? ?? 12;
    final monthlyCurrent =
        (current['monthly_savings'] as num?)?.toDouble() ?? 0;
    final monthlyProjected =
        (projected['monthly_savings'] as num?)?.toDouble() ?? 0;
    final totalSavings =
        (projected['total_savings_over_period'] as num?)
                ?.toDouble() ??
            0;
    final breakEven = result['break_even_month'] as int?;
    final aiComment = result['ai_comment'] as String?;
    final timeline =
        result['monthly_timeline'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sonuçlar ($months ay)',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text1)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Mevcut Tasarruf',
                value:
                    AppFormatters.currency(monthlyCurrent),
                color: monthlyCurrent >= 0
                    ? _positive
                    : _negative,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Tahmini Tasarruf',
                value: AppFormatters.currency(
                    monthlyProjected),
                color: monthlyProjected >= 0
                    ? _positive
                    : _negative,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricCard(
          label: '$months Ay Toplam Birikim',
          value: AppFormatters.currency(totalSavings),
          color:
              totalSavings >= 0 ? _positive : _negative,
          large: true,
        ),
        if (breakEven != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _accent.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: _accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Başabaş noktası: $breakEven. ay',
                    style: const TextStyle(
                        fontSize: 13, color: _accent),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (timeline.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Aylık Tasarruf Trendi',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _text1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: _TimelineChart(timeline: timeline),
          ),
        ],
        if (aiComment != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _accent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: _accent, size: 14),
                    SizedBox(width: 6),
                    Text('AI Analizi',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accent)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(aiComment,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _text2,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: _text3)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: large ? 20 : 15,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Timeline chart ────────────────────────────────────────────────────
class _TimelineChart extends StatelessWidget {
  final List timeline;
  const _TimelineChart({required this.timeline});

  @override
  Widget build(BuildContext context) {
    final values = timeline
        .map((e) =>
            ((e as Map<String, dynamic>)['savings'] as num? ?? 0)
                .toDouble())
        .toList();
    if (values.isEmpty) return const SizedBox.shrink();

    final maxVal =
        values.reduce((a, b) => a > b ? a : b);
    final minVal =
        values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();
    final effectiveRange = range == 0 ? 1.0 : range;

    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.asMap().entries.map((entry) {
          final val = entry.value;
          final normalised = range == 0
              ? 0.5
              : ((val - minVal) / effectiveRange)
                  .clamp(0.0, 1.0);
          final color = val >= 0 ? _positive : _negative;
          return Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor:
                          (0.1 + normalised * 0.9)
                              .clamp(0.1, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.7),
                          borderRadius:
                              const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                  if (values.length <= 12)
                    Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                          fontSize: 8, color: _text3),
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
