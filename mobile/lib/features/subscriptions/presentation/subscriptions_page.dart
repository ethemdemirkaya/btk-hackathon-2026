import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

// ── Provider ─────────────────────────────────────────────────────────
final _subscriptionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.subscriptions);
  return res.data as Map<String, dynamic>;
});

// ── Helpers ───────────────────────────────────────────────────────────
const _cycleLabels = {
  'weekly': 'Haftalık',
  'monthly': 'Aylık',
  'quarterly': '3 Aylık',
  'yearly': 'Yıllık',
};

const _cycleSuffix = {
  'weekly': '/hf',
  'monthly': '/ay',
  'quarterly': '/3ay',
  'yearly': '/yıl',
};

const _subColors = [
  Color(0xFFE50914),
  Color(0xFF1DB954),
  Color(0xFF0066CC),
  Color(0xFFFF6900),
  Color(0xFF5865F2),
  Color(0xFF00D4FF),
  Color(0xFFA78BFA),
  Color(0xFFFFC857),
];

// ── Shared form field ─────────────────────────────────────────────────
Widget _darkField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    IconData icon,
    {String? prefix, TextInputType? keyboardType}) {
  final c = context.appColors;
  return TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: TextStyle(color: c.text1, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.text3, fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: c.text3),
      prefixText: prefix,
      prefixStyle: TextStyle(color: c.text2),
      filled: true,
      fillColor: c.bg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    ),
  );
}

Widget _datePicker(BuildContext context,
    {required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear}) {
  final c = context.appColors;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 18, color: c.text3),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value != null
                  ? AppFormatters.dateShort(value)
                  : 'Sonraki Ödeme Tarihi',
              style: TextStyle(
                  fontSize: 14, color: value != null ? c.text1 : c.text3),
            ),
          ),
          if (value != null)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close, size: 16, color: c.text3),
            ),
        ],
      ),
    ),
  );
}

Widget _cycleDropdown(
    BuildContext context, String value, ValueChanged<String> onChange) {
  final c = context.appColors;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: c.bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.border),
    ),
    child: Row(
      children: [
        Icon(Icons.repeat_outlined, size: 18, color: c.text3),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: c.card,
              style: TextStyle(color: c.text1, fontSize: 14),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                DropdownMenuItem(value: 'quarterly', child: Text('3 Aylık')),
                DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
              ],
              onChanged: (v) => onChange(v!),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Abonelik Ekle sheet ───────────────────────────────────────────────
Future<void> _showAddSubscriptionSheet(
    BuildContext context, WidgetRef ref) async {
  final c = context.appColors;
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  String billingCycle = 'monthly';
  DateTime? nextBillingDate;
  bool saving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> pickDate() async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: ctx,
            initialDate: nextBillingDate ?? now,
            firstDate: now.subtract(const Duration(days: 365)),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) setState(() => nextBillingDate = picked);
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(children: [
                  Expanded(
                      child: Text('Abonelik Ekle',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: c.text1))),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: c.text2, size: 20)),
                ]),
                const SizedBox(height: 16),
                _darkField(
                    ctx, nameCtrl, 'Abonelik Adı', Icons.subscriptions_outlined),
                const SizedBox(height: 12),
                _darkField(ctx, amountCtrl, 'Tutar (₺)', Icons.attach_money,
                    prefix: '₺ ',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _cycleDropdown(
                    ctx, billingCycle, (v) => setState(() => billingCycle = v)),
                const SizedBox(height: 12),
                _datePicker(ctx,
                    value: nextBillingDate,
                    onTap: pickDate,
                    onClear: () => setState(() => nextBillingDate = null)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final amount = double.tryParse(
                                    amountCtrl.text.trim().replaceAll(',', '.')) ??
                                0;
                            if (name.isEmpty || amount <= 0) return;
                            setState(() => saving = true);
                            try {
                              await DioClient.instance.post(
                                ApiEndpoints.subscriptions,
                                data: {
                                  'name': name,
                                  'amount': amount,
                                  'billing_cycle': billingCycle,
                                  if (nextBillingDate != null)
                                    'next_billing_date': nextBillingDate!
                                        .toIso8601String()
                                        .split('T')
                                        .first,
                                },
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              ref.invalidate(_subscriptionsProvider);
                            } catch (_) {
                              setState(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF051929),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ── Karta tıklayınca açılan actions sheet ─────────────────────────────
Future<void> _showSubscriptionActions(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> sub,
    Color color) async {
  final c = context.appColors;
  final name = sub['name'] as String? ?? '';
  final id = (sub['id'] as num).toInt();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Abonelik başlığı
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                        .join(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: c.text1)),
                    Text(
                      _cycleLabels[sub['billing_cycle'] as String? ?? 'monthly'] ?? '',
                      style: TextStyle(fontSize: 12, color: c.text3),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.currencyAuto(
                        (sub['amount'] as num?)?.toDouble() ?? 0),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.text1),
                  ),
                  Text(
                    _cycleSuffix[sub['billing_cycle'] as String? ?? 'monthly'] ?? '/ay',
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Düzenle butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showEditSubscriptionSheet(context, ref, sub);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Düzenle',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF051929),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Sil butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                // _handleDelete ile aynı undo akışını kullan
                // sub referansı _showSubscriptionActions kapsamında mevcut
                bool undone = false;
                // Optimistik kaldır
                ref.invalidate(_subscriptionsProvider);
                final snackResult =
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Abonelik silindi'),
                    duration: const Duration(seconds: 5),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    action: SnackBarAction(
                      label: 'Geri al',
                      textColor: AppColors.accent,
                      onPressed: () => undone = true,
                    ),
                  ),
                );
                snackResult.closed.then((_) {
                  if (!undone) {
                    DioClient.instance
                        .delete(ApiEndpoints.subscription(id))
                        .then((_) => ref.invalidate(_subscriptionsProvider))
                        .catchError((_) =>
                            ref.invalidate(_subscriptionsProvider));
                  }
                });
              },
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.negative),
              label: Text('Sil',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: c.negative)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: c.negative.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Abonelik Düzenle sheet ────────────────────────────────────────────
String _cycleAmountLabel(String cycle) => switch (cycle) {
      'weekly' => 'Haftalık Tutar (₺)',
      'quarterly' => '3 Aylık Tutar (₺)',
      'yearly' => 'Yıllık Tutar (₺)',
      _ => 'Aylık Tutar (₺)',
    };

Future<void> _showEditSubscriptionSheet(
    BuildContext context, WidgetRef ref, Map<String, dynamic> sub) async {
  final c = context.appColors;
  final id = (sub['id'] as num).toInt();
  final nameCtrl =
      TextEditingController(text: sub['name'] as String? ?? '');
  // amount: fatura döngüsüne göre gerçek tutar (aylık eşdeğer değil)
  final amountCtrl = TextEditingController(
      text: (sub['amount'] as num?)?.toStringAsFixed(2) ?? '');
  String billingCycle = sub['billing_cycle'] as String? ?? 'monthly';
  final nbRaw = sub['next_billing_date'] as String?;
  DateTime? nextBillingDate =
      nbRaw != null ? DateTime.tryParse(nbRaw) : null;
  bool saving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> pickDate() async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: ctx,
            initialDate: nextBillingDate ?? now,
            firstDate: now.subtract(const Duration(days: 365)),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) setState(() => nextBillingDate = picked);
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(children: [
                  Expanded(
                      child: Text('Aboneliği Düzenle',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: c.text1))),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: c.text2, size: 20)),
                ]),
                const SizedBox(height: 16),
                _darkField(ctx, nameCtrl, 'Abonelik Adı',
                    Icons.subscriptions_outlined),
                const SizedBox(height: 12),
                // Döngü seçimi ÖNCE — tutar label'ı güncellensin
                _cycleDropdown(ctx, billingCycle, (v) {
                  setState(() => billingCycle = v);
                }),
                const SizedBox(height: 12),
                // Tutar label'ı billing cycle'a göre değişiyor
                _darkField(
                    ctx,
                    amountCtrl,
                    _cycleAmountLabel(billingCycle),
                    Icons.attach_money,
                    prefix: '₺ ',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true)),
                const SizedBox(height: 12),
                _datePicker(ctx,
                    value: nextBillingDate,
                    onTap: pickDate,
                    onClear: () => setState(() => nextBillingDate = null)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            // Türkçe virgülü noktaya çevir
                            final rawAmount = amountCtrl.text
                                .trim()
                                .replaceAll(',', '.');
                            final amount =
                                double.tryParse(rawAmount) ?? 0;
                            if (name.isEmpty || amount <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Ad ve tutar alanları gereklidir.')),
                              );
                              return;
                            }
                            setState(() => saving = true);
                            try {
                              await DioClient.instance.put(
                                ApiEndpoints.subscription(id),
                                data: {
                                  'name': name,
                                  'amount': amount,
                                  'billing_cycle': billingCycle,
                                  'next_billing_date': nextBillingDate
                                      ?.toIso8601String()
                                      .split('T')
                                      .first,
                                },
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              ref.invalidate(_subscriptionsProvider);
                            } on DioException catch (e) {
                              setState(() => saving = false);
                              if (!ctx.mounted) return;
                              final msg = e.response?.data?['message'] as String? ??
                                  (e.response?.data?['errors'] != null
                                      ? (e.response!.data['errors']
                                              as Map)
                                          .values
                                          .first
                                          .toString()
                                      : 'Kaydedilemedi (${e.response?.statusCode})');
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            } catch (e) {
                              setState(() => saving = false);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Hata: $e')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF051929),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ── Page ──────────────────────────────────────────────────────────────
class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  int? _selectedId;
  List<Map<String, dynamic>>? _localSubs;

  Future<void> _handleDelete(Map<String, dynamic> sub) async {
    final id = (sub['id'] as num).toInt();

    final currentData = ref.read(_subscriptionsProvider).value;
    final currentSubs = _localSubs ??
        (currentData?['subscriptions'] as List? ?? [])
            .cast<Map<String, dynamic>>();

    setState(() {
      _selectedId = null;
      _localSubs = List.from(currentSubs)
        ..removeWhere((s) => (s['id'] as num).toInt() == id);
    });

    bool undone = false;
    final snackResult = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Abonelik silindi'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Geri al',
          textColor: AppColors.accent,
          onPressed: () => undone = true,
        ),
      ),
    );

    snackResult.closed.then((_) {
      if (undone) {
        if (mounted) setState(() => _localSubs = null);
      } else {
        DioClient.instance.delete(ApiEndpoints.subscription(id)).then((_) {
          if (mounted) {
            setState(() => _localSubs = null);
            ref.invalidate(_subscriptionsProvider);
          }
        }).catchError((_) {
          if (mounted) setState(() => _localSubs = null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final async = ref.watch(_subscriptionsProvider);

    return Scaffold(
        backgroundColor: c.bg,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSubscriptionSheet(context, ref),
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF051929),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 26),
        ),
        body: SafeArea(
          child: Column(
            children: [
              async.when(
                loading: () => _buildHeader(context, 'Yükleniyor…'),
                error: (_, __) => _buildHeader(context, ''),
                data: (data) {
                  final total =
                      (data['total_monthly'] as num?)?.toDouble() ?? 0;
                  return _buildHeader(
                      context, 'Aylık ${AppFormatters.currencyCompact(total)}');
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: c.card,
                  onRefresh: () async => ref.invalidate(_subscriptionsProvider),
                  child: async.when(
                    loading: () => const SkeletonListView(),
                    error: (e, __) => ErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(_subscriptionsProvider),
                    ),
                    data: (data) {
                      final subs = _localSubs ??
                          (data['subscriptions'] as List? ?? [])
                              .cast<Map<String, dynamic>>();
                      final candidates = (data['candidates'] as List? ?? [])
                          .cast<Map<String, dynamic>>();
                      final totalMonthly =
                          (data['total_monthly'] as num?)?.toDouble() ?? 0;

                      if (subs.isEmpty && candidates.isEmpty) {
                        return const EmptyState(
                          icon: Icons.subscriptions,
                          title: 'Abonelik bulunamadı',
                          subtitle:
                              'AI, işlemlerinizden abonelikleri otomatik tespit eder.',
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          // ── Hero card ────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: c.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: c.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AYLIK TOPLAM',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: c.text3,
                                              letterSpacing: 0.8),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppFormatters.currencyCompact(
                                              totalMonthly),
                                          style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: c.text1,
                                              letterSpacing: -0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Yıllık ${AppFormatters.currencyCompact(totalMonthly * 12)} · ${subs.length} aktif',
                                          style: TextStyle(
                                              fontSize: 12, color: c.text3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(
                                        Icons.subscriptions_outlined,
                                        size: 22,
                                        color: AppColors.accent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ── Active subs ──────────────────────────
                          if (subs.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 24, 20, 10),
                              child: Text('Aktif Abonelikler',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: c.text3,
                                      letterSpacing: 0.6)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: subs
                                    .asMap()
                                    .entries
                                    .map((e) {
                                      final subId =
                                          (e.value['id'] as num).toInt();
                                      final isSelected =
                                          _selectedId == subId;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: _SubCard(
                                          sub: e.value,
                                          colorIndex: e.key,
                                          isSelected: isSelected,
                                          onTap: () {
                                            if (_selectedId != null) {
                                              setState(
                                                  () => _selectedId = null);
                                            } else {
                                              _showSubscriptionActions(
                                                context,
                                                ref,
                                                e.value,
                                                _subColors[e.key %
                                                    _subColors.length],
                                              );
                                            }
                                          },
                                          onLongPress: () => setState(() =>
                                              _selectedId = isSelected
                                                  ? null
                                                  : subId),
                                          onDeleteTap: () =>
                                              _handleDelete(e.value),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                          ],
                          // ── Candidates ───────────────────────────
                          if (candidates.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 10),
                              child: Text('Tespit Edilenler',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: c.text3,
                                      letterSpacing: 0.6)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: candidates
                                    .map((cand) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: _CandidateCard(
                                              candidate: cand),
                                        ))
                                    .toList(),
                              ),
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

  Widget _buildHeader(BuildContext context, String subtitle) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
              child: Icon(Icons.menu, size: 18, color: c.text2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Abonelikler',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.text1)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: c.text3)),
              ],
            ),
          ),
          AiInsightsButton(page: 'subscriptions'),
        ],
      ),
    );
  }
}

// ── Sub card ──────────────────────────────────────────────────────────
class _SubCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final int colorIndex;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDeleteTap;
  final bool isSelected;

  const _SubCard({
    required this.sub,
    required this.colorIndex,
    required this.onTap,
    required this.onLongPress,
    required this.onDeleteTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final name = sub['name'] as String? ?? 'S';
    final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
    final cycle = sub['billing_cycle'] as String? ?? 'monthly';
    final aiDetected = sub['auto_detected'] as bool? ?? false;
    final nextBilling = sub['next_billing_date'] as String?;
    final isCancel = sub['cancel_candidate'] as bool? ?? false;

    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final color = _subColors[colorIndex % _subColors.length];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? c.negative.withValues(alpha: 0.5) : c.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.text1)),
                      ),
                      if (aiDetected)
                        const Icon(Icons.auto_awesome,
                            size: 12, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${_cycleLabels[cycle] ?? cycle}${nextBilling != null ? ' · ${AppFormatters.dateShort(DateTime.parse(nextBilling))}' : ''}',
                        style: TextStyle(fontSize: 11, color: c.text3),
                      ),
                      if (isCancel) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: c.warning.withValues(alpha: 0.3)),
                          ),
                          child: Text('İptal Adayı',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: c.warning)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currencyAuto(amount),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.text1),
                ),
                Text(_cycleSuffix[cycle] ?? '/ay',
                    style: TextStyle(fontSize: 11, color: c.text3)),
              ],
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? GestureDetector(
                      key: const ValueKey('delete'),
                      onTap: onDeleteTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.negative.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: c.negative.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: c.negative),
                      ),
                    )
                  : Icon(
                      key: const ValueKey('chevron'),
                      Icons.chevron_right,
                      size: 18,
                      color: c.text3,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Candidate card ────────────────────────────────────────────────────
class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final name = candidate['name'] as String? ?? '';
    final amount = (candidate['amount'] as num?)?.toDouble() ?? 0;
    final confidence = (candidate['confidence'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text1)),
                Text(
                  'Olasılık: %${(confidence * 100).toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: c.text3),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.currencyAuto(amount),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: c.text1),
          ),
        ],
      ),
    );
  }
}
