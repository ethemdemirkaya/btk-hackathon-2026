import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _budgetsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final now = DateTime.now();
  final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final res = await DioClient.instance
      .get(ApiEndpoints.budgets, queryParameters: {'period': period});
  return res.data as Map<String, dynamic>;
});

const _catColorPalette = [
  Color(0xFFFFC857),
  Color(0xFF6FB1FC),
  Color(0xFFA78BFA),
  Color(0xFF2BE0A0),
  Color(0xFFFF5C7C),
  Color(0xFFFF7E5C),
  Color(0xFF00D4FF),
  Color(0xFFC084FC),
];

Color _colorForName(String name) {
  final h = name.codeUnits.fold(0, (a, b) => a + b);
  return _catColorPalette[h % _catColorPalette.length];
}

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final async = ref.watch(_budgetsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetForm(context, ref, null),
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF051929),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Bütçe',
              subtitle: _monthLabel(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: c.card,
                onRefresh: () async => ref.invalidate(_budgetsProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_budgetsProvider),
                  ),
                  data: (data) {
                    final budgets = (data['budgets'] as List? ?? [])
                        .cast<Map<String, dynamic>>();

                    if (budgets.isEmpty) {
                      return EmptyState(
                        icon: Icons.pie_chart_outline,
                        title: 'Bütçe oluşturulmadı',
                        subtitle:
                            'AI önerisiyle veya kendiniz bütçe oluşturun.',
                        ctaLabel: '+ Bütçe Ekle',
                        onCta: () => _showBudgetForm(context, ref, null),
                      );
                    }

                    final totalLimit = budgets.fold<double>(
                        0,
                        (s, b) =>
                            s + ((b['amount'] as num?)?.toDouble() ?? 0));
                    final totalSpent = budgets.fold<double>(
                        0,
                        (s, b) =>
                            s + ((b['spent'] as num?)?.toDouble() ?? 0));
                    final overCount =
                        budgets.where((b) => b['over_budget'] == true).length;
                    final pctTotal =
                        totalLimit > 0 ? (totalSpent / totalLimit * 100) : 0.0;

                    return ListView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        // Hero card
                        _HeroCard(
                          totalSpent: totalSpent,
                          totalLimit: totalLimit,
                          pctTotal: pctTotal,
                          overCount: overCount,
                          budgetCount: budgets.length,
                        ),
                        const SizedBox(height: 12),

                        // AI suggest button
                        _AiSuggestButton(
                          onTap: () => _showAiSuggest(context, ref),
                        ),
                        const SizedBox(height: 16),

                        // Budget list
                        ...budgets.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BudgetCard(
                                budget: b,
                                onEdit: () =>
                                    _showBudgetForm(context, ref, b),
                              ),
                            )),

                        // Dashed add button
                        _DashedAddButton(
                          label: 'Yeni bütçe ekle',
                          onTap: () => _showBudgetForm(context, ref, null),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthLabel() {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
  }

  void _showBudgetForm(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BudgetFormSheet(
        existing: existing,
        onSaved: () => ref.invalidate(_budgetsProvider),
      ),
    );
  }

  void _showAiSuggest(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AiSuggestSheet(
        onApplied: () => ref.invalidate(_budgetsProvider),
      ),
    );
  }
}

// ── Standard Header ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => shellScaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.menu, size: 20, color: c.text2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text1)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: c.text3)),
            ],
          ),
          const Spacer(),
          AiInsightsButton(page: 'budgets'),
        ],
      ),
    );
  }
}

// ── Hero Card ────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double totalSpent;
  final double totalLimit;
  final double pctTotal;
  final int overCount;
  final int budgetCount;
  const _HeroCard({
    required this.totalSpent,
    required this.totalLimit,
    required this.pctTotal,
    required this.overCount,
    required this.budgetCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _ScoreRing(value: pctTotal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bu ay toplam bütçe',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3)),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.currencyCompact(totalSpent),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.text1, letterSpacing: -0.52),
                ),
                const SizedBox(height: 4),
                Text(
                  '$budgetCount kategoride ${AppFormatters.currencyCompact(totalLimit)} harcandı',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: c.text3),
                ),
                if (overCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: c.warning),
                      const SizedBox(width: 4),
                      Text('$overCount bütçe aşıldı',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.warning)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Suggest Button ────────────────────────────────────────────────
class _AiSuggestButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AiSuggestButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI bütçe önerisi al',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text1)),
                  const SizedBox(height: 2),
                  Text(
                    'Harcama örüntüne göre kategori bazlı limitler',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.text2),
          ],
        ),
      ),
    );
  }
}

// ── Dashed Add Button ────────────────────────────────────────────────
class _DashedAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DashedAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: c.border,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: c.text3),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.text3)),
          ],
        ),
      ),
    );
  }
}

// ── Score Ring ──────────────────────────────────────────────────────
class _ScoreRing extends StatelessWidget {
  final double value;
  const _ScoreRing({required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    const double size = 90;
    const double stroke = 9;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value,
          stroke: stroke,
          trackColor: c.border,
          negativeColor: c.negative,
          warningColor: c.warning,
          accentColor: AppColors.accent,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.clamp(0, 999).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.text1),
              ),
              Text('kullanıldı',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: c.text3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color trackColor;
  final Color negativeColor;
  final Color warningColor;
  final Color accentColor;
  const _RingPainter({
    required this.value,
    required this.stroke,
    required this.trackColor,
    required this.negativeColor,
    required this.warningColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final fillColor = value > 100
        ? negativeColor
        : value >= 80
            ? warningColor
            : accentColor;
    final valuePaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (value.clamp(0, 100) / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.negativeColor != negativeColor ||
      old.warningColor != warningColor ||
      old.accentColor != accentColor;
}

// ── Budget Card ──────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  final Map<String, dynamic> budget;
  final VoidCallback onEdit;
  const _BudgetCard({required this.budget, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final pct = (budget['pct'] as num?)?.toDouble() ?? 0;
    final over = budget['over_budget'] as bool? ?? false;
    final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
    final limit = (budget['amount'] as num?)?.toDouble() ?? 0;
    final categoryMap = budget['category'] as Map<String, dynamic>?;
    final catName = categoryMap?['name'] as String? ?? 'Kategori';
    final catColor = _colorForName(catName);
    final remaining = limit - spent;

    // Progress color: accent < 80%, warning 80-99%, red ≥ 100%
    final progressColor = pct >= 100
        ? c.negative
        : pct >= 80
            ? c.warning
            : AppColors.accent;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Category bubble
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      catName.isNotEmpty ? catName[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: catColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(catName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text1)),
                      const SizedBox(height: 3),
                      over
                          ? Text(
                              '${AppFormatters.currencyCompact(spent - limit)} aşıldı',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.negative),
                            )
                          : Text(
                              'Kalan ${AppFormatters.currencyCompact(remaining)}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3),
                            ),
                    ],
                  ),
                ),
                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '%${pct.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: progressColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                backgroundColor: progressColor.withValues(alpha: 0.1),
                valueColor:
                    AlwaysStoppedAnimation(progressColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppFormatters.currencyCompact(spent),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3)),
                Text(AppFormatters.currencyCompact(limit),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Suggest Sheet ─────────────────────────────────────────────────
class _AiSuggestSheet extends StatefulWidget {
  final VoidCallback onApplied;
  const _AiSuggestSheet({required this.onApplied});

  @override
  State<_AiSuggestSheet> createState() => _AiSuggestSheetState();
}

class _AiSuggestSheetState extends State<_AiSuggestSheet> {
  bool _loading = true;
  bool _applying = false;
  List<Map<String, dynamic>> _suggestions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await DioClient.instance.post(ApiEndpoints.budgetsAiSuggest);
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _suggestions = (data['suggestions'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'AI önerisi alınamadı.';
        _loading = false;
      });
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final payload = {
        'suggestions': _suggestions
            .map((s) => {
                  'category_id': s['category_id'],
                  'amount': (s['suggested'] as num?)?.toDouble() ?? 0,
                })
            .toList(),
      };
      await DioClient.instance.post(ApiEndpoints.budgetsAiApply, data: payload);
      widget.onApplied();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Uygulanamadı.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('AI Bütçe Önerisi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text1)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.text2),
                              textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.builder(
                        controller: ctrl,
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _suggestions.length,
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          final amount =
                              (s['suggested'] as num?)
                                      ?.toDouble() ??
                                  0;
                          final catName =
                              s['category_name'] as String? ?? '';
                          final catColor = _colorForName(catName);
                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: catColor
                                        .withValues(alpha: 0.13),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      catName.isNotEmpty
                                          ? catName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: catColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(catName,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: c.text1)),
                                      if ((s['reason'] as String?)
                                              ?.isNotEmpty ==
                                          true)
                                        Text(s['reason'] as String,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: c.text3)),
                                    ],
                                  ),
                                ),
                                Text(
                                    AppFormatters.currencyCompact(
                                        amount),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24,
                  24 + MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applying ? null : _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF051929),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _applying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF051929)))
                      : const Icon(Icons.check),
                  label: const Text('Tümünü Uygula'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Budget Form Sheet ─────────────────────────────────────────────────
class _BudgetFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _BudgetFormSheet({this.existing, required this.onSaved});

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _alertCtrl = TextEditingController(text: '80');
  int? _categoryId;
  String _categoryName = 'Kategori Seçin';
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  bool _loadingCats = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text =
          (e['amount'] as num?)?.toStringAsFixed(2) ?? '';
      _alertCtrl.text =
          (e['alert_threshold'] as num?)?.toString() ?? '80';
      final cat = e['category'] as Map<String, dynamic>?;
      if (cat != null) {
        _categoryId = (cat['id'] as num?)?.toInt();
        _categoryName = cat['name'] as String? ?? 'Kategori';
      }
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await DioClient.instance
          .get('/categories', queryParameters: {'flat': true});
      final list =
          (res.data as Map<String, dynamic>)['categories'] as List? ?? [];
      setState(() {
        _categories =
            list.map((c) => c as Map<String, dynamic>).toList();
        _loadingCats = false;
      });
    } catch (_) {
      setState(() => _loadingCats = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _alertCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kategori seçin')));
      return;
    }
    setState(() => _loading = true);
    final now = DateTime.now();
    final period =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    try {
      final payload = {
        'category_id': _categoryId,
        'amount':
            double.parse(_amountCtrl.text.replaceAll(',', '.')),
        'alert_threshold': int.tryParse(_alertCtrl.text) ?? 80,
        'period': period,
      };
      if (_isEdit) {
        final id = (widget.existing!['id'] as num).toInt();
        await DioClient.instance.put('/budgets/$id', data: payload);
      } else {
        await DioClient.instance
            .post(ApiEndpoints.budgets, data: payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Kaydedilemedi.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEdit ? 'Bütçe Düzenle' : 'Bütçe Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text1)),
              const SizedBox(height: 20),
              _loadingCats
                  ? const LinearProgressIndicator(color: AppColors.accent)
                  : DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      dropdownColor: c.card,
                      decoration:
                          const InputDecoration(labelText: 'Kategori'),
                      hint: Text(_categoryName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.text3)),
                      items: _categories
                          .map((cat) => DropdownMenuItem<int>(
                                value: (cat['id'] as num).toInt(),
                                child: Text(cat['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _categoryId = v;
                          _categoryName = (_categories.firstWhere(
                                  (cat) =>
                                      (cat['id'] as num).toInt() ==
                                      v,
                                  orElse: () => {'name': ''})['name'] as String?) ?? '';
                        });
                      },
                    ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                    labelText: 'Aylık Bütçe (₺)',
                    prefixIcon: Icon(Icons.attach_money)),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Tutar gerekli';
                  }
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) { return 'Geçerli tutar girin'; }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alertCtrl,
                decoration: const InputDecoration(
                    labelText: 'Uyarı Eşiği (%)',
                    prefixIcon: Icon(Icons.notifications_outlined),
                    hintText: '80'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 100) {
                    return '1-100 arası girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF051929),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF051929)),
                        )
                      : Text(_isEdit ? 'Güncelle' : 'Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
