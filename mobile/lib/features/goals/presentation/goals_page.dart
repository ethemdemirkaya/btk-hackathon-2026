import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _goalsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.goals);
  return res.data as Map<String, dynamic>;
});

const _goalIcons = {
  'Acil Fon': Icons.shield_outlined,
  'Tatil': Icons.beach_access_outlined,
  'MacBook': Icons.laptop_outlined,
  'Düğün': Icons.favorite_outline,
  'Araba': Icons.directions_car_outlined,
  'Ev': Icons.home_outlined,
  'Eğitim': Icons.school_outlined,
};

IconData _iconForGoal(String name) {
  for (final entry in _goalIcons.entries) {
    if (name.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return Icons.flag_outlined;
}

// ── Design tokens ────────────────────────────────────────────────────
const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _positive   = Color(0xFF0DD9A0);
const _warning    = Color(0xFFF59E0B);

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  String _filter = 'active';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_goalsProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalForm(context, null),
        backgroundColor: _accent,
        foregroundColor: const Color(0xFF051929),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: 'Hedefler', subtitle: 'Tasarruf hedeflerin'),
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
                onRefresh: () async => ref.invalidate(_goalsProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_goalsProvider),
                  ),
                  data: (data) {
                    final goals = (data['goals'] as List? ?? [])
                        .cast<Map<String, dynamic>>();

                    if (goals.isEmpty) {
                      return EmptyState(
                        icon: Icons.flag_outlined,
                        title: 'Henüz hedef yok',
                        subtitle:
                            'Tasarruf hedefleri oluşturarak finansal hedeflerinize ulaşın.',
                        ctaLabel: '+ Hedef Ekle',
                        onCta: () => _showGoalForm(context, null),
                      );
                    }

                    final active = goals
                        .where((g) =>
                            (g['status'] as String?) == 'active')
                        .toList();
                    final completed = goals
                        .where((g) =>
                            (g['status'] as String?) == 'completed')
                        .toList();
                    final abandoned = goals
                        .where((g) =>
                            (g['status'] as String?) == 'abandoned')
                        .toList();

                    final totalProgress = goals.fold<double>(
                        0,
                        (s, g) =>
                            s +
                            ((g['current_amount'] as num?)
                                    ?.toDouble() ??
                                0));

                    final filtered = _filter == 'active'
                        ? active
                        : _filter == 'done'
                            ? completed
                            : abandoned;

                    return ListView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        // Hero card
                        _HeroCard(
                          activeCount: active.length,
                          totalSaved: totalProgress,
                        ),
                        const SizedBox(height: 16),

                        // Segmented filter
                        _SegmentedToggle(
                          options: [
                            _SegOpt(
                                'active', 'Aktif · ${active.length}'),
                            _SegOpt('done', 'Tamamlanan'),
                            _SegOpt('abandoned', 'Vazgeçilen'),
                          ],
                          value: _filter,
                          onChange: (v) =>
                              setState(() => _filter = v),
                        ),
                        const SizedBox(height: 16),

                        // Goals list
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 32),
                            child: Text(
                              'Bu kategoride hedef yok.',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _text3),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ...filtered.map((g) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: _GoalCard(
                                goal: g,
                                onAddFunds: _filter == 'active'
                                    ? () => _showAddFunds(
                                          context,
                                          (g['id'] as num).toInt(),
                                          g['name'] as String? ?? '',
                                        )
                                    : null,
                                onEdit: _filter == 'active'
                                    ? () =>
                                        _showGoalForm(context, g)
                                    : null,
                              ),
                            )),

                        // Dashed add button
                        _DashedAddButton(
                          label: 'Yeni hedef oluştur',
                          onTap: () => _showGoalForm(context, null),
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

  void _showGoalForm(
      BuildContext context, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GoalFormSheet(
        existing: existing,
        onSaved: () => ref.invalidate(_goalsProvider),
      ),
    );
  }

  void _showAddFunds(
      BuildContext context, int goalId, String goalName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddFundsSheet(
        goalId: goalId,
        goalName: goalName,
        onAdded: () => ref.invalidate(_goalsProvider),
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
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: const Icon(Icons.menu, size: 20, color: _text2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text1)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text3)),
            ],
          ),
          const Spacer(),
          AiInsightsButton(page: 'goals'),
        ],
      ),
    );
  }
}

// ── Hero Card ────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final int activeCount;
  final double totalSaved;
  const _HeroCard(
      {required this.activeCount, required this.totalSaved});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _accent.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.flag_outlined,
                size: 26, color: _accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeCount aktif hedef · ${AppFormatters.currencyCompact(totalSaved)} ₺ biriktirildi',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppFormatters.currencyCompact(totalSaved)} ₺',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _text1, letterSpacing: -0.56),
                ),
                const SizedBox(height: 4),
                Text('Toplam birikim',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashed Add Button ────────────────────────────────────────────────
class _DashedAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DashedAddButton(
      {required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _cardBorder,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: _text3),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text3)),
          ],
        ),
      ),
    );
  }
}

// ── Segmented Toggle ─────────────────────────────────────────────────
class _SegOpt {
  final String value;
  final String label;
  const _SegOpt(this.value, this.label);
}

class _SegmentedToggle extends StatelessWidget {
  final List<_SegOpt> options;
  final String value;
  final ValueChanged<String> onChange;
  const _SegmentedToggle(
      {required this.options,
      required this.value,
      required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: options.map((o) {
          final active = o.value == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(o.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? _accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: active
                      ? Border.all(
                          color: _accent.withValues(alpha: 0.3))
                      : null,
                ),
                child: Text(
                  o.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? _accent : _text3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Goal Card ────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback? onAddFunds;
  final VoidCallback? onEdit;
  const _GoalCard(
      {required this.goal, this.onAddFunds, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = goal['name'] as String? ?? '';
    final pct =
        (goal['progress_pct'] as num?)?.toDouble() ?? 0;
    final current =
        (goal['current_amount'] as num?)?.toDouble() ?? 0;
    final target =
        (goal['target_amount'] as num?)?.toDouble() ?? 0;
    final targetDateStr = goal['target_date'] as String?;
    final monthsLeft = goal['months_to_goal'] as int?;
    final monthly =
        (goal['monthly_contribution'] as num?)?.toDouble() ?? 0;
    final remaining = target - current;
    final monthlyNeeded =
        (monthsLeft != null && monthsLeft > 0)
            ? (remaining / monthsLeft)
            : 0.0;
    final onTrack = monthly >= monthlyNeeded;

    String deadlineText = '';
    if (targetDateStr != null) {
      try {
        final dt = DateTime.parse(targetDateStr);
        deadlineText = AppFormatters.dateLong(dt);
      } catch (_) {
        deadlineText = targetDateStr;
      }
    }
    if (monthsLeft != null) {
      deadlineText += deadlineText.isNotEmpty
          ? ' · $monthsLeft ay'
          : '$monthsLeft ay';
    }

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: icon + name + circular progress
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(_iconForGoal(name),
                      size: 22, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormatters.currencyCompact(target)} ₺ hedef',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                      ),
                      if (deadlineText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(deadlineText,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
                      ],
                    ],
                  ),
                ),
                // Circular progress indicator 60px
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        strokeWidth: 5,
                        backgroundColor:
                            _accent.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(
                            _accent),
                      ),
                      Text(
                        '%${pct.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _text1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                backgroundColor:
                    _accent.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation(_accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),

            // Bottom: current / target + days chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppFormatters.currencyCompact(current)} ₺ / ${AppFormatters.currencyCompact(target)} ₺',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3),
                ),
                if (monthsLeft != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _cardBorder,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$monthsLeft ay kaldı',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _text2),
                    ),
                  ),
              ],
            ),

            // Add funds row
            if (onAddFunds != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    onTrack
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 14,
                    color:
                        onTrack ? _positive : _warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      onTrack
                          ? 'Hedefe ulaşma yolundasın'
                          : '${AppFormatters.currencyCompact(monthlyNeeded)} ₺/ay gerekli',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text2),
                    ),
                  ),
                  GestureDetector(
                    onTap: onAddFunds,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                _accent.withValues(alpha: 0.3)),
                      ),
                      child: Text('Para Ekle',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _accent)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Add Funds Sheet ──────────────────────────────────────────────────
class _AddFundsSheet extends StatefulWidget {
  final int goalId;
  final String goalName;
  final VoidCallback onAdded;
  const _AddFundsSheet(
      {required this.goalId,
      required this.goalName,
      required this.onAdded});

  @override
  State<_AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends State<_AddFundsSheet> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli tutar girin')));
      return;
    }
    setState(() => _loading = true);
    try {
      await DioClient.instance.post(
        ApiEndpoints.goalAddFunds(widget.goalId),
        data: {'amount': amount},
      );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Para eklenemedi.';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Katkı Ekle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text1)),
          const SizedBox(height: 4),
          Text(widget.goalName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _text3)),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(
              labelText: 'Miktar (₺)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
            ],
            autofocus: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: const Color(0xFF051929),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF051929)))
                  : const Text('Ekle'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal Form Sheet ──────────────────────────────────────────────────
class _GoalFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _GoalFormSheet({this.existing, required this.onSaved});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _initialCtrl = TextEditingController();
  DateTime? _targetDate;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['name'] as String? ?? '';
      _targetCtrl.text =
          (e['target_amount'] as num?)?.toStringAsFixed(2) ?? '';
      _initialCtrl.text =
          (e['current_amount'] as num?)?.toStringAsFixed(2) ?? '';
      final td = e['target_date'] as String?;
      if (td != null) _targetDate = DateTime.tryParse(td);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _initialCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _targetDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'target_amount':
            double.parse(_targetCtrl.text.replaceAll(',', '.')),
        if (_initialCtrl.text.isNotEmpty)
          'initial_amount': double.parse(
              _initialCtrl.text.replaceAll(',', '.')),
        if (_targetDate != null)
          'target_date':
              _targetDate!.toIso8601String().split('T').first,
      };
      if (_isEdit) {
        final id = (widget.existing!['id'] as num).toInt();
        await DioClient.instance
            .put(ApiEndpoints.goal(id), data: payload);
      } else {
        await DioClient.instance
            .post(ApiEndpoints.goals, data: payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Kaydedilemedi.';
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
              Text(_isEdit ? 'Hedef Düzenle' : 'Hedef Ekle',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text1)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Hedef Adı (ör: Araba, Tatil)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Ad gerekli'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetCtrl,
                decoration: const InputDecoration(
                    labelText: 'Hedef Tutar (₺)',
                    prefixIcon: Icon(Icons.flag_outlined)),
                keyboardType:
                    const TextInputType.numberWithOptions(
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mevcut Birikim (₺, opsiyonel)',
                    prefixIcon:
                        Icon(Icons.savings_outlined)),
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9,.]'))
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText:
                          'Hedef Tarihi (opsiyonel)',
                      prefixIcon: const Icon(
                          Icons.calendar_today_outlined),
                      hintText: _targetDate != null
                          ? AppFormatters.dateShort(
                              _targetDate!)
                          : 'Tarih seçin',
                    ),
                    controller: TextEditingController(
                      text: _targetDate != null
                          ? AppFormatters.dateShort(
                              _targetDate!)
                          : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF051929),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF051929)))
                      : Text(_isEdit
                          ? 'Güncelle'
                          : 'Hedef Oluştur'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
