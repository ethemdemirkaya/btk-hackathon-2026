import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
import '../../../core/widgets/bottom_nav_shell.dart';

// ── Page ──────────────────────────────────────────────────────────────
class SimulatorPage extends StatefulWidget {
  const SimulatorPage({super.key});

  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage> {
  // ── Current financial snapshot (from GET /simulator) ─────────────
  Map<String, dynamic>? _current;
  bool _loadingCurrent = true;
  String? _loadError;

  // ── Sliders ───────────────────────────────────────────────────────
  double _incomeChangePct  = 0;
  double _expenseChangePct = 0;
  double _inflationRate    = 38; // default, overridden from API
  int    _monthsHorizon    = 12;

  // ── Calculation state ─────────────────────────────────────────────
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _calcError;

  // ── Last simulated params (to block re-run without changes) ───────
  double? _lastSimIncome;
  double? _lastSimExpense;
  double? _lastSimInflation;
  int?    _lastSimMonths;

  bool get _paramsChanged =>
      _lastSimIncome    != _incomeChangePct  ||
      _lastSimExpense   != _expenseChangePct ||
      _lastSimInflation != _inflationRate    ||
      _lastSimMonths    != _monthsHorizon;

  bool get _canSimulate => !_loading && (_result == null || _paramsChanged);

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    setState(() { _loadingCurrent = true; _loadError = null; });
    try {
      final res = await DioClient.instance.get(ApiEndpoints.simulator);
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _current        = data;
        _inflationRate  = (data['personal_inflation'] as num?)?.toDouble() ?? 38;
        _loadingCurrent = false;
      });
    } catch (e) {
      setState(() {
        _loadError      = e.toString();
        _loadingCurrent = false;
      });
    }
  }

  Future<void> _calculateWithModal() async {
    if (_current == null || !_canSimulate) return;

    // useRootNavigator: false keeps the dialog on the ShellRoute navigator,
    // so Navigator.pop(context) pops the right route after calculation.
    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => const _SimulationLoadingModal(),
    );

    // Give the dialog one frame to mount before starting the async call.
    await Future.delayed(Duration.zero);

    try {
      await _calculate();
    } finally {
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: false);
        if (nav.canPop()) nav.pop();
      }
    }
  }

  Future<void> _calculate() async {
    if (_current == null) return;
    setState(() { _loading = true; _calcError = null; _result = null; });
    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.simulatorCalculate,
        data: {
          'income_change_pct'   : _incomeChangePct,
          'expense_change_pct'  : _expenseChangePct,
          'inflation_rate'      : _inflationRate,
          'months_horizon'      : _monthsHorizon,
          'monthly_income'      : (_current!['monthly_income']      as num?) ?? 0,
          'avg_monthly_expense' : (_current!['avg_monthly_expense'] as num?) ?? 0,
          'total_balance'       : (_current!['total_balance']       as num?) ?? 0,
          'total_card_debt'     : (_current!['total_card_debt']     as num?) ?? 0,
        },
      );
      setState(() {
        _result           = res.data as Map<String, dynamic>;
        _loading          = false;
        _lastSimIncome    = _incomeChangePct;
        _lastSimExpense   = _expenseChangePct;
        _lastSimInflation = _inflationRate;
        _lastSimMonths    = _monthsHorizon;
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['message']
          ?? (e.response?.data?['errors'] as Map?)?.values.firstOrNull?.toString()
          ?? 'Hesaplama yapılamadı.';
      setState(() { _calcError = msg; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loadingCurrent
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _loadError != null
                      ? _RetryView(message: _loadError!, onRetry: _loadCurrentData)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_current != null) _CurrentSnapshotCard(data: _current!),
                              const SizedBox(height: 14),
                              _ParametersCard(
                                incomeChangePct:  _incomeChangePct,
                                expenseChangePct: _expenseChangePct,
                                inflationRate:    _inflationRate,
                                monthsHorizon:    _monthsHorizon,
                                onIncomeChanged:  (v) => setState(() => _incomeChangePct  = v),
                                onExpenseChanged: (v) => setState(() => _expenseChangePct = v),
                                onInflationChanged:(v)=> setState(() => _inflationRate    = v),
                                onMonthsChanged:  (v) => setState(() => _monthsHorizon    = v),
                              ),
                              const SizedBox(height: 14),
                              _CalcButton(loading: _loading, onTap: _canSimulate ? _calculateWithModal : null),
                              if (_calcError != null) ...[
                                const SizedBox(height: 12),
                                _ErrorBanner(message: _calcError!),
                              ],
                              if (_result != null) ...[
                                const SizedBox(height: 20),
                                _ResultSection(result: _result!, months: _monthsHorizon),
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

  Widget _buildHeader() {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => shellScaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.menu, size: 18, color: c.text2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finansal Simülatör',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text1)),
                Text('Senaryoları karşılaştır',
                    style: TextStyle(fontSize: 12, color: c.text3)),
              ],
            ),
          ),
          const AiInsightsButton(page: 'simulator'),
        ],
      ),
    );
  }
}

// ── Current Snapshot Card ─────────────────────────────────────────────
class _CurrentSnapshotCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CurrentSnapshotCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final income   = (data['monthly_income']      as num?)?.toDouble() ?? 0;
    final expense  = (data['avg_monthly_expense'] as num?)?.toDouble() ?? 0;
    final balance  = (data['total_balance']       as num?)?.toDouble() ?? 0;
    final score    = (data['health_score']        as num?)?.toInt()    ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mevcut Finansal Durum',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.text3)),
          const SizedBox(height: 12),
          Row(
            children: [
              _SnapStat('Aylık Gelir',   AppFormatters.currencyCompact(income),  c.positive),
              _SnapStat('Aylık Gider',   AppFormatters.currencyCompact(expense),  c.negative),
              _SnapStat('Toplam Bakiye', AppFormatters.currencyCompact(balance),  AppColors.accent),
              _SnapStat('Sağlık Skoru',  '$score/100',                            c.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SnapStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: c.text3)),
        ],
      ),
    );
  }
}

// ── Parameters Card ───────────────────────────────────────────────────
class _ParametersCard extends StatelessWidget {
  final double incomeChangePct;
  final double expenseChangePct;
  final double inflationRate;
  final int    monthsHorizon;
  final ValueChanged<double> onIncomeChanged;
  final ValueChanged<double> onExpenseChanged;
  final ValueChanged<double> onInflationChanged;
  final ValueChanged<int>    onMonthsChanged;

  const _ParametersCard({
    required this.incomeChangePct,
    required this.expenseChangePct,
    required this.inflationRate,
    required this.monthsHorizon,
    required this.onIncomeChanged,
    required this.onExpenseChanged,
    required this.onInflationChanged,
    required this.onMonthsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Senaryo Parametreleri',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text1)),
          const SizedBox(height: 18),
          _SliderRow(
            label: 'Gelir Değişimi',
            value: incomeChangePct,
            min: -50, max: 200,
            suffix: '%',
            color: incomeChangePct >= 0 ? c.positive : c.negative,
            onChanged: onIncomeChanged,
          ),
          const SizedBox(height: 14),
          _SliderRow(
            label: 'Gider Değişimi',
            value: expenseChangePct,
            min: -50, max: 100,
            suffix: '%',
            color: expenseChangePct <= 0 ? c.positive : c.negative,
            onChanged: onExpenseChanged,
          ),
          const SizedBox(height: 14),
          _SliderRow(
            label: 'Enflasyon Oranı',
            value: inflationRate,
            min: 0, max: 100,
            suffix: '%',
            color: c.warning,
            onChanged: onInflationChanged,
          ),
          const SizedBox(height: 14),
          _SliderRow(
            label: 'Süre',
            value: monthsHorizon.toDouble(),
            min: 1, max: 60,
            suffix: ' ay',
            color: AppColors.accent,
            onChanged: (v) => onMonthsChanged(v.toInt()),
            divisions: 59,
            showSign: false,
          ),
        ],
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
  final String suffix;
  final Color color;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final bool showSign;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.color,
    required this.onChanged,
    this.divisions,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final sign = (showSign && value >= 0) ? '+' : '';
    final displayDivisions = divisions ?? ((max - min) / 5).toInt().clamp(1, 200);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 13, color: c.text2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$sign${value.toStringAsFixed(0)}$suffix',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   color,
            thumbColor:         color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            overlayColor:       color.withValues(alpha: 0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min, max: max,
            divisions: displayDivisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ── Calculate button ──────────────────────────────────────────────────
class _CalcButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _CalcButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (loading || onTap == null) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF051929),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF051929)),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_graph, size: 18),
                  SizedBox(width: 8),
                  Text('Simüle Et',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.negative.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.negative.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.negative, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: c.negative)),
          ),
        ],
      ),
    );
  }
}

// ── Retry view ────────────────────────────────────────────────────────
class _RetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _RetryView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: c.text3),
          const SizedBox(height: 12),
          Text('Veriler yüklenemedi',
              style: TextStyle(fontSize: 14, color: c.text2)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.text3)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Text('Tekrar dene',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result section ────────────────────────────────────────────────────
class _ResultSection extends StatelessWidget {
  final Map<String, dynamic> result;
  final int months;
  const _ResultSection({required this.result, required this.months});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final newIncome    = (result['new_income']         as num?)?.toDouble() ?? 0;
    final newExpense   = (result['new_expense']        as num?)?.toDouble() ?? 0;
    final newSavings   = (result['new_savings']        as num?)?.toDouble() ?? 0;
    final savingsRate  = (result['savings_rate_pct']   as num?)?.toDouble() ?? 0;
    final score        = (result['estimated_score']    as num?)?.toInt()    ?? 0;
    final finalBalance = (result['final_balance']      as num?)?.toDouble() ?? 0;
    final realFinal    = (result['real_final_balance'] as num?)?.toDouble() ?? 0;
    final inflLoss     = (result['inflation_loss']     as num?)?.toDouble() ?? 0;
    final emergency    = (result['months_emergency']   as num?)?.toDouble() ?? 0;
    final projections  = (result['projections']        as List?)            ?? [];
    final aiCommentary = result['ai_commentary'] as String?;
    final aiVerdict    = result['ai_verdict']    as String?;
    final aiRisks      = (result['ai_risks']           as List?)?.map((e) => e.toString()).toList() ?? [];
    final aiRecs       = (result['ai_recommendations'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final scoreColor = score >= 75 ? c.positive : score >= 50 ? c.warning : c.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary stats ────────────────────────────────────────
        Text('Simülasyon Sonuçları ($months ay)',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: c.text1)),
        const SizedBox(height: 14),

        // Row 1: income / expense / savings
        Row(
          children: [
            Expanded(child: _StatCard('Yeni Gelir',
                AppFormatters.currencyCompact(newIncome), c.positive)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard('Yeni Gider',
                AppFormatters.currencyCompact(newExpense), c.negative)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatCard(
                'Aylık Tasarruf',
                AppFormatters.currencyCompact(newSavings),
                newSavings >= 0 ? c.positive : c.negative)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(
                'Tasarruf Oranı',
                '%${savingsRate.toStringAsFixed(1)}',
                savingsRate >= 20 ? c.positive : savingsRate >= 10 ? c.warning : c.negative)),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: final balance / real / inflation loss
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              _DetailRow('$months Ay Sonra Bakiye',
                  AppFormatters.currencyCompact(finalBalance), c.text1),
              Divider(color: c.border, height: 20),
              _DetailRow('Reel Bakiye (enflasyon sonrası)',
                  AppFormatters.currencyCompact(realFinal), c.text2),
              Divider(color: c.border, height: 20),
              _DetailRow('Enflasyon Kaybı',
                  '−${AppFormatters.currencyCompact(inflLoss)}', c.negative),
              Divider(color: c.border, height: 20),
              _DetailRow('Acil Fon (ay)',
                  '${emergency.toStringAsFixed(1)} ay', AppColors.accent),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Health score
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.12),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text('$score',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: scoreColor)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tahmini Finansal Sağlık Skoru',
                        style: TextStyle(fontSize: 12, color: c.text3)),
                    const SizedBox(height: 4),
                    Text(
                      score >= 75 ? 'Sağlıklı senaryo' :
                      score >= 50 ? 'Dikkat gerektiriyor' : 'Riskli senaryo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: scoreColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Projection chart ─────────────────────────────────────
        if (projections.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Bakiye Projeksiyonu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: _ProjectionChart(projections: projections),
          ),
        ],

        // ── AI Verdict ───────────────────────────────────────────
        if (aiVerdict != null || aiCommentary != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.accent, size: 14),
                    SizedBox(width: 6),
                    Text('AI Değerlendirmesi',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  ],
                ),
                if (aiVerdict != null) ...[
                  const SizedBox(height: 8),
                  Text(aiVerdict,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: c.text1, height: 1.4)),
                ],
                if (aiCommentary != null) ...[
                  const SizedBox(height: 8),
                  Text(aiCommentary,
                      style: TextStyle(
                          fontSize: 12, color: c.text2, height: 1.5)),
                ],
              ],
            ),
          ),
        ],

        // ── AI Risks ─────────────────────────────────────────────
        if (aiRisks.isNotEmpty) ...[
          const SizedBox(height: 14),
          _AiListCard(
            title: 'Riskler',
            icon: Icons.warning_amber_rounded,
            color: c.warning,
            items: aiRisks,
          ),
        ],

        // ── AI Recommendations ────────────────────────────────────
        if (aiRecs.isNotEmpty) ...[
          const SizedBox(height: 10),
          _AiListCard(
            title: 'Öneriler',
            icon: Icons.lightbulb_outline,
            color: c.positive,
            items: aiRecs,
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: c.text3)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DetailRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: c.text2)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _AiListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  const _AiListCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5, height: 5,
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    Expanded(
                      child: Text(item,
                          style: TextStyle(
                              fontSize: 12, color: c.text2, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Projection chart ──────────────────────────────────────────────────
class _ProjectionChart extends StatelessWidget {
  final List projections;
  const _ProjectionChart({required this.projections});

  @override
  Widget build(BuildContext context) {
    final balances = projections
        .map((e) => ((e as Map<String, dynamic>)['balance'] as num? ?? 0).toDouble())
        .toList();
    final realBals = projections
        .map((e) => ((e as Map<String, dynamic>)['real_balance'] as num? ?? 0).toDouble())
        .toList();

    if (balances.isEmpty) return const SizedBox.shrink();

    final maxVal = [...balances, ...realBals].reduce((a, b) => a > b ? a : b);
    final minVal = [...balances, ...realBals].reduce((a, b) => a < b ? a : b);
    final range  = (maxVal - minVal).abs();
    final effRange = range == 0 ? 1.0 : range;

    double norm(double v) => ((v - minVal) / effRange).clamp(0.0, 1.0);

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(balances.length, (i) {
          final nomH  = 0.05 + norm(balances[i]) * 0.95;
          final realH = 0.05 + norm(realBals[i]) * 0.95;
          final color = balances[i] >= 0 ? context.appColors.positive : context.appColors.negative;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Real balance (faded)
                  FractionallySizedBox(
                    heightFactor: realH,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ),
                  ),
                  // Nominal balance
                  FractionallySizedBox(
                    heightFactor: nomH,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Simülasyon Yükleme Modalı ─────────────────────────────────────────────────
class _SimulationLoadingModal extends StatefulWidget {
  const _SimulationLoadingModal();

  @override
  State<_SimulationLoadingModal> createState() =>
      _SimulationLoadingModalState();
}

class _SimulationLoadingModalState extends State<_SimulationLoadingModal>
    with SingleTickerProviderStateMixin {

  static const _messages = [
    'Gelir akışları analiz ediliyor...',
    'Harcama kalıpları inceleniyor...',
    'Enflasyon etkisi hesaplanıyor...',
    'Monte Carlo simülasyonu çalıştırılıyor...',
    'Nakit akışı projeksiyonu oluşturuluyor...',
    'Finansal risk faktörleri değerlendiriliyor...',
    'Bütçe uyum skoru hesaplanıyor...',
    'Senaryo karşılaştırması yapılıyor...',
    'Tasarruf optimizasyonu analiz ediliyor...',
    'Borç yönetimi simülasyonu tamamlanıyor...',
    'AI değerlendirmesi için veri hazırlanıyor...',
    'Gemini 1.5 Pro modeli çağrılıyor...',
    'Finansal öngörüler derleniyor...',
    'Sonuçlar hazırlanıyor...',
  ];

  int _msgIndex = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();

    _timer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
      if (!mounted) return;
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
        _ctrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60, height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    strokeWidth: 3,
                    value: 1,
                  ),
                  const CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 3,
                  ),
                  const Icon(Icons.auto_awesome,
                      size: 20, color: AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'AI Simülasyonu Çalışıyor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text1,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: FadeTransition(
                opacity: _fade,
                child: Text(
                  _messages[_msgIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.text2,
                    height: 1.4,
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
