import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
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
    final async = ref.watch(_budgetsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetForm(context, ref, null),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentText,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.bg2,
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
                  subtitle: 'AI önerisiyle veya kendiniz bütçe oluşturun.',
                  ctaLabel: '+ Bütçe Ekle',
                  onCta: () => _showBudgetForm(context, ref, null),
                );
              }

              final totalLimit = budgets.fold<double>(
                  0, (s, b) => s + ((b['amount'] as num?)?.toDouble() ?? 0));
              final totalSpent = budgets.fold<double>(
                  0, (s, b) => s + ((b['spent'] as num?)?.toDouble() ?? 0));
              final overCount =
                  budgets.where((b) => b['over_budget'] == true).length;
              final pctTotal =
                  totalLimit > 0 ? (totalSpent / totalLimit * 100) : 0.0;

              return ListView(
                padding: const EdgeInsets.only(bottom: 100),
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bg2,
                              border: Border.all(color: AppColors.border1Dark),
                            ),
                            child: const Icon(Icons.menu,
                                size: 18, color: AppColors.text2Dark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bütçe',
                                style: AppTextStyles.headlineLarge
                                    .copyWith(color: AppColors.text1Dark)),
                            Text(
                              _monthLabel(),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.text3Dark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hero ring card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.bg1, AppColors.bg2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: Row(
                        children: [
                          _ScoreRing(value: pctTotal),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bu ay toplam',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.text3Dark)),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: AppFormatters.currencyCompact(
                                            totalSpent),
                                        style: AppTextStyles.amountHero
                                            .copyWith(
                                                fontSize: 24,
                                                color: AppColors.text1Dark,
                                                letterSpacing: -0.02 * 24),
                                      ),
                                      TextSpan(
                                        text:
                                            ' / ${AppFormatters.currencyCompact(totalLimit)} ₺',
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                                color: AppColors.text3Dark),
                                      ),
                                    ],
                                  ),
                                ),
                                if (overCount > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          size: 12, color: AppColors.warning),
                                      const SizedBox(width: 4),
                                      Text('$overCount bütçe aşıldı',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color: AppColors.warning)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // AI suggestion banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: GestureDetector(
                      onTap: () => _showAiSuggest(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentDim,
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.accentDim),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                              ),
                              child: const Icon(Icons.auto_awesome,
                                  size: 18, color: AppColors.accentText),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AI bütçe önerisi al',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text1Dark)),
                                  SizedBox(height: 1),
                                  Text(
                                    'Harcama örüntüne göre kategori bazlı limitler',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.text3Dark),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 16, color: AppColors.text2Dark),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Budget list
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        ...budgets.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BudgetCard(
                                budget: b,
                                onEdit: () =>
                                    _showBudgetForm(context, ref, b),
                              ),
                            )),
                        // Dashed add button
                        GestureDetector(
                          onTap: () => _showBudgetForm(context, ref, null),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border2Dark,
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add,
                                    size: 18, color: AppColors.text3Dark),
                                const SizedBox(width: 8),
                                Text('Yeni bütçe ekle',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(
                                            color: AppColors.text3Dark,
                                            fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _monthLabel() {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
  }

  void _showBudgetForm(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BudgetFormSheet(
        existing: existing,
        onSaved: () => ref.invalidate(_budgetsProvider),
      ),
    );
  }

  void _showAiSuggest(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AiSuggestSheet(
        onApplied: () => ref.invalidate(_budgetsProvider),
      ),
    );
  }
}

// ── Score Ring ──────────────────────────────────────────────────────
class _ScoreRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  const _ScoreRing({required this.value, this.size = 100, this.stroke = 10});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value: value, stroke: stroke),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.clamp(0, 999).toStringAsFixed(0)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1Dark,
                    fontSize: 18),
              ),
              Text('kullanıldı',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.text3Dark, fontSize: 9)),
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
  const _RingPainter({required this.value, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..color = AppColors.bg3
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final fillColor = value > 100
        ? AppColors.negative
        : value >= 80
            ? AppColors.warning
            : AppColors.accent;
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
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ── Budget Card ──────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  final Map<String, dynamic> budget;
  final VoidCallback onEdit;
  const _BudgetCard({required this.budget, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final pct = (budget['pct'] as num?)?.toDouble() ?? 0;
    final over = budget['over_budget'] as bool? ?? false;
    final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
    final limit = (budget['amount'] as num?)?.toDouble() ?? 0;
    final categoryMap = budget['category'] as Map<String, dynamic>?;
    final catName = categoryMap?['name'] as String? ?? 'Kategori';
    final catColor = _colorForName(catName);
    final remaining = limit - spent;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Category bubble
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      catName.isNotEmpty ? catName[0].toUpperCase() : '?',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: catColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(catName,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      over
                          ? Text(
                              '${AppFormatters.currencyCompact(spent - limit)} ₺ aşıldı',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.negative),
                            )
                          : Text(
                              'Kalan ${AppFormatters.currencyCompact(remaining)} ₺',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.text3Dark),
                            ),
                    ],
                  ),
                ),
                Text(
                  '%${pct.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: over
                          ? AppColors.negative
                          : AppColors.text1Dark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                backgroundColor: catColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                    over ? AppColors.negative : catColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppFormatters.currencyCompact(spent),
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.text3Dark)),
                Text('${AppFormatters.currencyCompact(limit)} ₺',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.text3Dark)),
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
      final res = await DioClient.instance.post(ApiEndpoints.budgetsAiSuggest);
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
      await DioClient.instance.post(ApiEndpoints.budgetsAiApply);
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
              color: AppColors.border2Dark,
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
                    style: AppTextStyles.headlineMedium),
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
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.text2Dark),
                              textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.builder(
                        controller: ctrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _suggestions.length,
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          final amount =
                              (s['suggested_amount'] as num?)?.toDouble() ?? 0;
                          final catName =
                              s['category_name'] as String? ?? '';
                          final catColor = _colorForName(catName);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.border1Dark),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      catName.isNotEmpty
                                          ? catName[0].toUpperCase()
                                          : '?',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              color: catColor,
                                              fontWeight: FontWeight.w700),
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
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                      if ((s['reason'] as String?)
                                              ?.isNotEmpty ==
                                          true)
                                        Text(s['reason'] as String,
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                    color:
                                                        AppColors.text3Dark)),
                                    ],
                                  ),
                                ),
                                Text(
                                    AppFormatters.currencyCompact(amount),
                                    style: AppTextStyles.bodyMedium.copyWith(
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
              padding: EdgeInsets.fromLTRB(
                  24, 8, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applying ? null : _apply,
                  icon: _applying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
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
        _categories = list.map((c) => c as Map<String, dynamic>).toList();
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
        'amount': double.parse(_amountCtrl.text.replaceAll(',', '.')),
        'alert_threshold': int.tryParse(_alertCtrl.text) ?? 80,
        'period': period,
      };
      if (_isEdit) {
        final id = (widget.existing!['id'] as num).toInt();
        await DioClient.instance.put('/budgets/$id', data: payload);
      } else {
        await DioClient.instance.post(ApiEndpoints.budgets, data: payload);
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
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 20),
              _loadingCats
                  ? const LinearProgressIndicator(color: AppColors.accent)
                  : DropdownButtonFormField<int>(
                      value: _categoryId,
                      dropdownColor: AppColors.bg2,
                      decoration:
                          const InputDecoration(labelText: 'Kategori'),
                      hint: Text(_categoryName,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.text3Dark)),
                      items: _categories
                          .map((c) => DropdownMenuItem<int>(
                                value: (c['id'] as num).toInt(),
                                child: Text(c['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _categoryId = v;
                          _categoryName = _categories.firstWhere(
                                  (c) => (c['id'] as num).toInt() == v)[
                              'name'] as String;
                        });
                      },
                    ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                    labelText: 'Aylık Bütçe (₺)',
                    prefixIcon: Icon(Icons.attach_money)),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Tutar gerekli';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Geçerli tutar girin';
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
