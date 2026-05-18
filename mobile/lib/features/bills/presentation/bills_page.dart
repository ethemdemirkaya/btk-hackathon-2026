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

// ── Provider ─────────────────────────────────────────────────────────
final _billsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.bills);
  return res.data as Map<String, dynamic>;
});

// ── Type maps ─────────────────────────────────────────────────────────
const _billTypeIcons = {
  'electricity': Icons.electric_bolt,
  'water': Icons.water_drop,
  'gas': Icons.local_fire_department,
  'internet': Icons.wifi,
  'phone': Icons.phone,
  'rent': Icons.home,
  'insurance': Icons.security,
  'other': Icons.receipt,
};

const _billTypeColors = {
  'electricity': Color(0xFFFFC857),
  'water': Color(0xFF6FB1FC),
  'gas': Color(0xFFFF7E5C),
  'internet': Color(0xFFA78BFA),
  'phone': Color(0xFFC084FC),
  'rent': Color(0xFF2BE0A0),
  'insurance': Color(0xFF6FB1FC),
  'other': Color(0xFF8FA5C2),
};

const _billTypeLabels = {
  'electricity': 'Elektrik',
  'water': 'Su',
  'gas': 'Doğalgaz',
  'internet': 'İnternet',
  'phone': 'Telefon',
  'rent': 'Kira',
  'insurance': 'Sigorta',
  'other': 'Diğer',
};

// ── Page ──────────────────────────────────────────────────────────────
class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final async = ref.watch(_billsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBillForm(context, ref, null),
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF051929),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            async.when(
              loading: () => _buildHeader(context, 'Yükleniyor…'),
              error: (_, __) => _buildHeader(context, ''),
              data: (data) {
                final bills =
                    (data['bills'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                final unpaid =
                    bills.where((b) => b['status'] != 'paid').length;
                return _buildHeader(context,
                    'Bu ay $unpaid ödenmemiş');
              },
            ),
            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: c.card,
                onRefresh: () async =>
                    ref.invalidate(_billsProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_billsProvider),
                  ),
                  data: (data) {
                    final bills = (data['bills'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    final totalMonthly =
                        (data['total_monthly_est'] as num?)
                                ?.toDouble() ??
                            0;

                    if (bills.isEmpty) {
                      return EmptyState(
                        icon: Icons.receipt,
                        title: 'Fatura bulunamadı',
                        subtitle:
                            'Faturalarınızı ekleyerek ödeme takibini kolaylaştırın.',
                        ctaLabel: '+ Fatura Ekle',
                        onCta: () =>
                            _showBillForm(context, ref, null),
                      );
                    }

                    final pending = bills
                        .where((b) => b['status'] != 'paid')
                        .toList();
                    final pendingTotal = pending.fold(
                        0.0,
                        (s, b) =>
                            s +
                            ((b['last_amount'] as num?)
                                    ?.toDouble() ??
                                0));

                    // Tarihe en yakın fatura önce görünsün
                    final today = DateTime.now().day;
                    final now = DateTime.now();
                    final daysInMonth =
                        DateTime(now.year, now.month + 1, 0).day;
                    int daysUntil(int? dueDay) {
                      if (dueDay == null) return 999;
                      if (dueDay >= today) return dueDay - today;
                      return daysInMonth - today + dueDay;
                    }

                    final sortedBills = [...bills]
                      ..sort((a, b) => daysUntil(a['due_day'] as int?)
                          .compareTo(daysUntil(b['due_day'] as int?)));

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        // ── Hero stats ───────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                                  20, 16, 20, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatChip(
                                  label: 'Bekleyen',
                                  value:
                                      AppFormatters.currencyCompact(pendingTotal),
                                  icon: Icons.pending_outlined,
                                  color: c.warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatChip(
                                  label: 'Aylık Est.',
                                  value:
                                      AppFormatters.currencyCompact(totalMonthly),
                                  icon:
                                      Icons.calendar_month_outlined,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: Column(
                            children: sortedBills
                                .map((b) => Padding(
                                      padding:
                                          const EdgeInsets.only(
                                              bottom: 8),
                                      child: _BillCard(
                                        bill: b,
                                        onEdit: () =>
                                            _showBillForm(
                                                context, ref, b),
                                        onDelete: () =>
                                            _deleteBill(
                                                context,
                                                ref,
                                                (b['id'] as num)
                                                    .toInt()),
                                      ),
                                    ))
                                .toList(),
                          ),
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
                Text('Faturalar',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.text1)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: c.text3)),
              ],
            ),
          ),
          AiInsightsButton(page: 'bills'),
        ],
      ),
    );
  }

  void _showBillForm(BuildContext context, WidgetRef ref,
      Map<String, dynamic>? existing) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BillFormSheet(
        existing: existing,
        onSaved: () => ref.invalidate(_billsProvider),
      ),
    );
  }

  Future<void> _deleteBill(
      BuildContext context, WidgetRef ref, int id) async {
    final c = context.appColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Faturayı Sil',
            style: TextStyle(color: c.text1)),
        content: Text(
            'Bu faturayı silmek istediğinize emin misiniz?',
            style: TextStyle(color: c.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal',
                  style: TextStyle(color: c.text2))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sil',
                  style: TextStyle(color: c.negative))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await DioClient.instance.delete(ApiEndpoints.bill(id));
        ref.invalidate(_billsProvider);
      } catch (_) {}
    }
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: c.text3)),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bill card ─────────────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BillCard(
      {required this.bill,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final type = bill['type'] as String? ?? 'other';
    final icon = _billTypeIcons[type] ?? Icons.receipt;
    final iconColor =
        _billTypeColors[type] ?? const Color(0xFF8FA5C2);
    final amount = (bill['last_amount'] as num?)?.toDouble() ?? 0;
    final dueDay = bill['due_day'] as int?;
    final isAutopay = bill['is_autopay'] as bool? ?? false;
    final status = bill['status'] as String? ?? 'upcoming';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'paid':
        statusColor = c.positive;
        statusLabel = 'Ödendi';
        break;
      case 'late':
        statusColor = c.negative;
        statusLabel = 'Gecikti';
        break;
      default:
        statusColor = c.warning;
        statusLabel = 'Yaklaşıyor';
    }

    return GestureDetector(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill['name'] as String? ??
                        _billTypeLabels[type] ??
                        type,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bill['provider'] ?? ''}${dueDay != null ? " · Her ayın $dueDay'i" : ''}',
                    style: TextStyle(
                        fontSize: 11, color: c.text3),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currencyCompact(amount),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.text1),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAutopay
                            ? c.positive
                            : statusColor)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: (isAutopay
                                ? c.positive
                                : statusColor)
                            .withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    isAutopay ? 'Otomatik' : statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAutopay
                            ? c.positive
                            : statusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bill form sheet ───────────────────────────────────────────────────
class _BillFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _BillFormSheet({this.existing, required this.onSaved});

  @override
  State<_BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<_BillFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dueDayCtrl = TextEditingController();
  String _type = 'electricity';
  bool _autopay = false;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['name'] as String? ?? '';
      _providerCtrl.text = e['provider'] as String? ?? '';
      _amountCtrl.text =
          (e['last_amount'] as num?)?.toStringAsFixed(2) ?? '';
      _dueDayCtrl.text =
          (e['due_day'] as int?)?.toString() ?? '';
      _type = e['type'] as String? ?? 'electricity';
      _autopay = e['is_autopay'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _providerCtrl.dispose();
    _amountCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'provider': _providerCtrl.text.trim(),
        'last_amount':
            double.parse(_amountCtrl.text.replaceAll(',', '.')),
        'due_day': int.tryParse(_dueDayCtrl.text) ?? 1,
        'is_autopay': _autopay,
      };
      if (_isEdit) {
        final id = (widget.existing!['id'] as num).toInt();
        await DioClient.instance
            .put(ApiEndpoints.bill(id), data: payload);
      } else {
        await DioClient.instance
            .post(ApiEndpoints.bills, data: payload);
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

  InputDecoration _deco(BuildContext context, String label, {IconData? icon}) {
    final c = context.appColors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.text3, fontSize: 13),
      prefixIcon:
          icon != null ? Icon(icon, size: 18, color: c.text3) : null,
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
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
              Text(_isEdit ? 'Fatura Düzenle' : 'Fatura Ekle',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.text1)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: c.card,
                style: TextStyle(
                    color: c.text1, fontSize: 14),
                decoration: _deco(context, 'Tür'),
                items: _billTypeLabels.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(
                    color: c.text1, fontSize: 14),
                decoration: _deco(context, 'Fatura Adı'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Ad gerekli'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _providerCtrl,
                style: TextStyle(
                    color: c.text1, fontSize: 14),
                decoration:
                    _deco(context, 'Sağlayıcı (opsiyonel)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      style: TextStyle(
                          color: c.text1, fontSize: 14),
                      decoration: _deco(context, 'Son Tutar (₺)',
                          icon: Icons.attach_money),
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
                        if (double.tryParse(
                                v.replaceAll(',', '.')) ==
                            null) {
                          return 'Geçerli tutar girin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dueDayCtrl,
                      style: TextStyle(
                          color: c.text1, fontSize: 14),
                      decoration:
                          _deco(context, 'Vade Günü (1-31)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly
                      ],
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null ||
                            n < 1 ||
                            n > 31) {
                          return '1-31 arası';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 12),
                  title: Text('Otomatik Ödeme',
                      style: TextStyle(
                          fontSize: 14,
                          color: c.text1)),
                  value: _autopay,
                  activeThumbColor: AppColors.accent,
                  onChanged: (v) =>
                      setState(() => _autopay = v),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor:
                        const Color(0xFF051929),
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
                              color: Colors.white))
                      : Text(
                          _isEdit ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
