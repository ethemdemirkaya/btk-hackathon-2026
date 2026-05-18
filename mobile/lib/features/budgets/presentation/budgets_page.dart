import 'dart:async';
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

// ── Predefined categories (used as local fallback) ────────────────────
class _CatOption {
  final String name;
  final IconData icon;
  const _CatOption(this.name, this.icon);
}

const _kPredefinedCats = [
  _CatOption('Giyim', Icons.checkroom_outlined),
  _CatOption('Market', Icons.local_grocery_store_outlined),
  _CatOption('Sağlık', Icons.health_and_safety_outlined),
  _CatOption('Teknoloji', Icons.computer_outlined),
  _CatOption('Hobi', Icons.sports_esports_outlined),
  _CatOption('Eğlence', Icons.movie_outlined),
  _CatOption('Ulaşım', Icons.directions_car_outlined),
  _CatOption('Yemek', Icons.restaurant_outlined),
  _CatOption('Fatura', Icons.receipt_outlined),
  _CatOption('Diğer', Icons.category_outlined),
];

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  String _monthLabel() {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
  }

  void _showBudgetForm(Map<String, dynamic>? existing) {
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

  void _showAiSuggest() {
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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final async = ref.watch(_budgetsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetForm(null),
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
              isSearching: _isSearching,
              onSearchTap: _toggleSearch,
            ),
            // Arama çubuğu
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(fontSize: 14, color: c.text1),
                        decoration: InputDecoration(
                          hintText: 'Kategori ara…',
                          hintStyle: TextStyle(color: c.text3),
                          prefixIcon: Icon(Icons.search, size: 20, color: c.text3),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() {
                                    _searchQuery = '';
                                    _searchCtrl.clear();
                                  }),
                                  child: Icon(Icons.close, size: 18, color: c.text3),
                                )
                              : null,
                          filled: true,
                          fillColor: c.card,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 1.5),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
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
                    // Alfabetik sırala
                    final budgets = ((data['budgets'] as List? ?? [])
                        .cast<Map<String, dynamic>>()
                      ..sort((a, b) {
                        final nameA = ((a['category'] as Map<String, dynamic>?)?['name']
                                as String? ?? '')
                            .toLowerCase();
                        final nameB = ((b['category'] as Map<String, dynamic>?)?['name']
                                as String? ?? '')
                            .toLowerCase();
                        return nameA.compareTo(nameB);
                      }));

                    final totalLimit = budgets.fold<double>(
                        0, (s, b) => s + ((b['amount'] as num?)?.toDouble() ?? 0));
                    final totalSpent = budgets.fold<double>(
                        0, (s, b) => s + ((b['spent'] as num?)?.toDouble() ?? 0));
                    final overCount =
                        budgets.where((b) => b['over_budget'] == true).length;
                    final pctTotal =
                        totalLimit > 0 ? (totalSpent / totalLimit * 100) : 0.0;

                    // Arama filtreleme
                    final filtered = _searchQuery.isEmpty
                        ? budgets
                        : budgets.where((b) {
                            final name = ((b['category'] as Map<String, dynamic>?)?['name']
                                    as String? ?? '')
                                .toLowerCase();
                            return name.contains(_searchQuery.toLowerCase());
                          }).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        if (budgets.isNotEmpty) ...[
                          _HeroCard(
                            totalSpent: totalSpent,
                            totalLimit: totalLimit,
                            pctTotal: pctTotal,
                            overCount: overCount,
                            budgetCount: budgets.length,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _AiSuggestButton(onTap: _showAiSuggest),
                        const SizedBox(height: 16),
                        if (budgets.isEmpty)
                          _EmptyBudgetHint(
                            onManualAdd: () => _showBudgetForm(null),
                          )
                        else if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              '"$_searchQuery" için bütçe bulunamadı.',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: c.text3),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else ...[
                          ...filtered.map((b) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _BudgetCard(
                                  budget: b,
                                  onEdit: () => _showBudgetForm(b),
                                ),
                              )),
                          if (_searchQuery.isEmpty)
                            _DashedAddButton(
                              label: 'Yeni bütçe ekle',
                              onTap: () => _showBudgetForm(null),
                            ),
                        ],
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
}

// ── Standard Header ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSearching;
  final VoidCallback onSearchTap;
  const _Header({
    required this.title,
    required this.subtitle,
    required this.isSearching,
    required this.onSearchTap,
  });

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
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSearching
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSearching
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : c.border,
                ),
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.search,
                size: 20,
                color: isSearching ? AppColors.accent : c.text2,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                      Icon(Icons.warning_amber_rounded, size: 12, color: c.warning),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.accent),
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

// ── Empty Budget Hint ─────────────────────────────────────────────────
class _EmptyBudgetHint extends StatelessWidget {
  final VoidCallback onManualAdd;
  const _EmptyBudgetHint({required this.onManualAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 40, color: c.text3),
              const SizedBox(height: 12),
              Text(
                'Henüz bütçe oluşturulmadı',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'AI önerisiyle otomatik oluştur veya kendin ekle.',
                style: TextStyle(fontSize: 12, color: c.text3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onManualAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Manuel ekle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          border: Border.all(color: c.border, style: BorderStyle.solid, width: 1.5),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text1),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: catColor),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '%${pct.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: progressColor),
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
                valueColor: AlwaysStoppedAnimation(progressColor),
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
  final Set<int> _selectedIndices = {};
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
      final suggestions = (data['suggestions'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() {
        _suggestions = suggestions;
        // Select all by default
        _selectedIndices.addAll(List.generate(suggestions.length, (i) => i));
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
    if (_selectedIndices.isEmpty) return;
    setState(() => _applying = true);
    try {
      final selected = _selectedIndices.map((i) => _suggestions[i]).toList();
      final payload = {
        'suggestions': selected
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      builder: (_, ctrl) => Material(
        color: c.card,
        child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('AI Bütçe Önerisi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text1)),
                ),
                if (!_loading && _error == null && _suggestions.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_selectedIndices.length == _suggestions.length) {
                        _selectedIndices.clear();
                      } else {
                        _selectedIndices.addAll(
                            List.generate(_suggestions.length, (i) => i));
                      }
                    }),
                    child: Text(
                      _selectedIndices.length == _suggestions.length
                          ? 'Tümünü kaldır'
                          : 'Tümünü seç',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const _AgentLoadingWidget()
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!,
                              style: TextStyle(fontSize: 14, color: c.text2),
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
                              (s['suggested'] as num?)?.toDouble() ?? 0;
                          final catName = s['category_name'] as String? ?? '';
                          final catColor = _colorForName(catName);
                          final isSelected = _selectedIndices.contains(i);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selectedIndices.remove(i);
                              } else {
                                _selectedIndices.add(i);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                // Sheet bg = c.card, so use c.bg for contrast
                                color: isSelected
                                    ? AppColors.accent.withValues(alpha: 0.10)
                                    : c.bg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : c.text3.withValues(alpha: 0.35),
                                  width: isSelected ? 1.5 : 1,
                                ),
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
                                        const SizedBox(height: 2),
                                        if ((s['rationale'] as String?)
                                                ?.isNotEmpty ==
                                            true)
                                          Text(s['rationale'] as String,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: c.text3))
                                        else if (s['has_spending'] == true &&
                                            (s['monthly_avg'] as num?) != null)
                                          Text(
                                            'Ort. ${AppFormatters.currencyCompact((s['monthly_avg'] as num).toDouble())}/ay',
                                            style: TextStyle(fontSize: 11, color: c.text3),
                                          )
                                        else
                                          Text(
                                            'Geçmiş harcama yok',
                                            style: TextStyle(fontSize: 11, color: c.text3),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppFormatters.currencyCompact(amount),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.accent
                                        : c.text2,
                                  ),
                                ],
                              ),
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
                  onPressed: (_applying || _selectedIndices.isEmpty) ? null : _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF051929),
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _applying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF051929)))
                      : const Icon(Icons.check),
                  label: Text(
                    _selectedIndices.isEmpty
                        ? 'Kategori Seçin'
                        : _selectedIndices.length == _suggestions.length
                            ? 'Tümünü Uygula (${_suggestions.length})'
                            : '${_selectedIndices.length} Öneriyi Uygula',
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
  int _alertValue = 80;
  int? _categoryId;
  String _categoryName = '';
  List<Map<String, dynamic>> _apiCategories = [];
  bool _loading = false;
  bool _loadingCats = true;

  bool get _isEdit => widget.existing != null;
  bool get _hasCategory => _categoryName.isNotEmpty;

  static const _months = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  String get _periodLabel {
    final now = DateTime.now();
    return '${_months[now.month]} ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = (e['amount'] as num?)?.toStringAsFixed(2) ?? '';
      _alertValue = (e['alert_threshold'] as num?)?.toInt() ?? 80;
      final cat = e['category'] as Map<String, dynamic>?;
      if (cat != null) {
        _categoryId = (cat['id'] as num?)?.toInt();
        _categoryName = cat['name'] as String? ?? '';
      }
    }
    _loadApiCategories();
  }

  Future<void> _loadApiCategories() async {
    try {
      final res = await DioClient.instance
          .get('/categories', queryParameters: {'flat': true});
      final list =
          (res.data as Map<String, dynamic>)['categories'] as List? ?? [];
      if (mounted) {
        setState(() {
          _apiCategories = list.map((c) => c as Map<String, dynamic>).toList();
          _loadingCats = false;
          if (_categoryName.isNotEmpty && _categoryId == null) {
            _categoryId = _resolveId(_categoryName);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  int? _resolveId(String name) {
    final lower = name.toLowerCase();
    final match = _apiCategories.where(
      (c) => (c['name'] as String?)?.toLowerCase() == lower,
    ).firstOrNull;
    return match != null ? (match['id'] as num?)?.toInt() : null;
  }

  void _openCategoryPicker() {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CategoryPickerSheet(
        apiCategories: _apiCategories,
        currentName: _categoryName,
        onSelect: (id, name) {
          setState(() {
            _categoryId = id ?? _resolveId(name);
            _categoryName = name;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_hasCategory) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kategori seçin')));
      return;
    }
    _categoryId ??= _resolveId(_categoryName);
    setState(() => _loading = true);
    final now = DateTime.now();
    final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    try {
      final payload = <String, dynamic>{
        'amount': double.parse(_amountCtrl.text.replaceAll(',', '.')),
        'alert_threshold': _alertValue,
        'period': period,
        'category_name': _categoryName,
        'category_id': _categoryId,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final c = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bütçeyi Sil',
            style: TextStyle(color: c.text1, fontWeight: FontWeight.w700)),
        content: Text('Bu bütçeyi silmek istediğinizden emin misiniz?',
            style: TextStyle(color: c.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal', style: TextStyle(color: c.text2))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sil',
                  style: TextStyle(
                      color: c.negative, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    setState(() => _loading = true);
    try {
      final id = (widget.existing!['id'] as num).toInt();
      await DioClient.instance.delete('/budgets/$id');
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Silinemedi.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final catColor = _hasCategory ? _colorForName(_categoryName) : c.text3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Drag handle ───────────────────────────────────────
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
              color: c.border, borderRadius: BorderRadius.circular(2)),
        ),

        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Bütçe Düzenle' : 'Bütçe Ekle',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: c.text1,
                                  letterSpacing: -0.4),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _periodLabel,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isEdit)
                        GestureDetector(
                          onTap: _loading ? null : _delete,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c.negative.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: c.negative.withValues(alpha: 0.25)),
                            ),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 20, color: c.negative),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Category section ─────────────────────────
                  Text('KATEGORİ',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.text3,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _loadingCats ? null : _openCategoryPicker,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _hasCategory
                              ? catColor.withValues(alpha: 0.5)
                              : c.border,
                          width: _hasCategory ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _hasCategory
                                  ? catColor.withValues(alpha: 0.15)
                                  : c.border.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: _loadingCats
                                ? Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accent),
                                    ),
                                  )
                                : Center(
                                    child: _hasCategory
                                        ? Text(
                                            _categoryName[0].toUpperCase(),
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: catColor),
                                          )
                                        : Icon(Icons.category_outlined,
                                            size: 20, color: c.text3),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasCategory ? _categoryName : 'Kategori seç',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: _hasCategory
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: _hasCategory ? c.text1 : c.text3),
                                ),
                                if (_hasCategory)
                                  Text(
                                    'Kategoriye dokunarak değiştir',
                                    style: TextStyle(
                                        fontSize: 11, color: c.text3),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 22, color: c.text3),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Amount section ───────────────────────────
                  Text('AYLIK LİMİT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.text3,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 58,
                          decoration: BoxDecoration(
                            border: Border(
                                right: BorderSide(color: c.border, width: 1)),
                          ),
                          child: const Center(
                            child: Text(
                              '₺',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _amountCtrl,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: c.text1),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              hintText: '0,00',
                              hintStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: c.text3),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9,.]'))
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Tutar gerekli';
                              }
                              final n =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (n == null || n <= 0) {
                                return 'Geçerli tutar girin';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Alert threshold ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('UYARI EŞİĞİ',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.text3,
                              letterSpacing: 0.6)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_alertValue >= 90
                                  ? c.negative
                                  : _alertValue >= 75
                                      ? c.warning
                                      : AppColors.accent)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '%$_alertValue',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _alertValue >= 90
                                ? c.negative
                                : _alertValue >= 75
                                    ? c.warning
                                    : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bu orana ulaşınca bildirim alırsın',
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _alertValue >= 90
                          ? c.negative
                          : _alertValue >= 75
                              ? c.warning
                              : AppColors.accent,
                      inactiveTrackColor: c.border,
                      thumbColor: _alertValue >= 90
                          ? c.negative
                          : _alertValue >= 75
                              ? c.warning
                              : AppColors.accent,
                      overlayColor:
                          AppColors.accent.withValues(alpha: 0.15),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 9),
                    ),
                    child: Slider(
                      value: _alertValue.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 18,
                      onChanged: (v) =>
                          setState(() => _alertValue = v.toInt()),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Submit button ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor:
                            AppColors.accent.withValues(alpha: 0.35),
                        foregroundColor: const Color(0xFF051929),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF051929)),
                            )
                          : Text(
                              _isEdit ? 'Güncelle' : 'Kaydet',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Category Picker Sheet ─────────────────────────────────────────────
class _CategoryPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> apiCategories;
  final String currentName;
  final void Function(int? id, String name) onSelect;

  const _CategoryPickerSheet({
    required this.apiCategories,
    required this.currentName,
    required this.onSelect,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  bool _showCustomField = false;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int? _idForName(String name) {
    final match = widget.apiCategories.where(
      (c) => (c['name'] as String?)?.toLowerCase() == name.toLowerCase(),
    ).firstOrNull;
    return match != null ? (match['id'] as num?)?.toInt() : null;
  }

  // Returns display list: API categories with real IDs when available,
  // predefined local list as fallback. Always ends with "Diğer".
  List<Map<String, dynamic>> _effectiveCats() {
    if (widget.apiCategories.isNotEmpty) {
      final result = widget.apiCategories.map((apiCat) {
        final name = apiCat['name'] as String? ?? '';
        final id = (apiCat['id'] as num?)?.toInt();
        final predefined = _kPredefinedCats
            .where((p) => p.name.toLowerCase() == name.toLowerCase())
            .firstOrNull;
        return {
          'id': id,
          'name': name,
          'icon': predefined?.icon ?? Icons.category_outlined,
        };
      }).toList();
      if (!result.any((c) => (c['name'] as String) == 'Diğer')) {
        result.add(
            {'id': null, 'name': 'Diğer', 'icon': Icons.category_outlined});
      }
      return result;
    }
    return _kPredefinedCats
        .map((p) => {'id': null, 'name': p.name, 'icon': p.icon})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final cats = _effectiveCats();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: c.border, borderRadius: BorderRadius.circular(999)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Kategori Seç',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.text1)),
          ),
        ),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat = cats[i];
              final catName = cat['name'] as String;
              final catId = cat['id'] as int?;
              final catIcon = cat['icon'] as IconData;
              final isSelected = widget.currentName == catName ||
                  (_showCustomField && catName == 'Diğer');
              final catColor = _colorForName(catName);
              return GestureDetector(
                onTap: () {
                  if (catName == 'Diğer') {
                    setState(() => _showCustomField = !_showCustomField);
                  } else {
                    widget.onSelect(catId, catName);
                    Navigator.of(context).pop();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? catColor.withValues(alpha: 0.15)
                        : c.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? catColor : c.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(catIcon,
                          size: 26,
                          color: isSelected ? catColor : c.text2),
                      const SizedBox(height: 6),
                      Text(
                        catName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? catColor : c.text1,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_showCustomField) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _customCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Kategori adını yazın…',
                hintStyle: TextStyle(color: c.text3),
                filled: true,
                fillColor: c.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = _customCtrl.text.trim();
                  if (name.isNotEmpty) {
                    widget.onSelect(_idForName(name), name);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF051929),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Seç'),
              ),
            ),
          ),
        ],
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }
}

// ── Agent Loading Widget ──────────────────────────────────────────────
class _AgentLoadingWidget extends StatefulWidget {
  const _AgentLoadingWidget();

  @override
  State<_AgentLoadingWidget> createState() => _AgentLoadingWidgetState();
}

class _AgentLoadingWidgetState extends State<_AgentLoadingWidget> {
  static const _msgs = [
    'Ajan 1  ·  Verileriniz hazırlanıyor…',
    'Ajan 2  ·  Harcama örüntüleri analiz ediliyor…',
    'Ajan 3  ·  Kategori bazlı limitler hesaplanıyor…',
    'Ajan 4  ·  Öneriler optimize ediliyor…',
    'Ajan 5  ·  Sonuçlar hazırlanıyor…',
  ];
  int _i = 0;
  late final Timer _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1800),
        (_) { if (mounted) setState(() => _i = (_i + 1) % _msgs.length); });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                _msgs[_i],
                key: ValueKey(_i),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.text2),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
