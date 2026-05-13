import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _billsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.bills);
  return res.data as Map<String, dynamic>;
});

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

class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_billsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBillForm(context, ref, null),
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
          onRefresh: () async => ref.invalidate(_billsProvider),
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
                  (data['total_monthly_est'] as num?)?.toDouble() ?? 0;

              if (bills.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt,
                  title: 'Fatura bulunamadı',
                  subtitle:
                      'Faturalarınızı ekleyerek ödeme takibini kolaylaştırın.',
                  ctaLabel: '+ Fatura Ekle',
                  onCta: () => _showBillForm(context, ref, null),
                );
              }

              final pending =
                  bills.where((b) => b['status'] != 'paid').toList();
              final pendingTotal = pending.fold(
                  0.0,
                  (s, b) =>
                      s + ((b['last_amount'] as num?)?.toDouble() ?? 0));

              return ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Hero header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Faturalar',
                            style: AppTextStyles.headlineLarge
                                .copyWith(color: AppColors.text1Dark)),
                        const SizedBox(height: 4),
                        Text('Bekleyen ödemeler',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.text3Dark,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.08 * 11)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.currencyCompact(pendingTotal),
                              style: AppTextStyles.amountHero.copyWith(
                                  fontSize: 36,
                                  color: AppColors.text1Dark,
                                  letterSpacing: -0.03 * 36),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('₺',
                                  style: AppTextStyles.headlineMedium
                                      .copyWith(
                                          color: AppColors.text2Dark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pending.length} fatura · Bu ay aylık: ${AppFormatters.currencyCompact(totalMonthly)} ₺',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.text3Dark),
                        ),
                      ],
                    ),
                  ),
                  // Bills list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: bills
                          .map((b) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: _BillCard(
                                  bill: b,
                                  onEdit: () =>
                                      _showBillForm(context, ref, b),
                                  onDelete: () => _deleteBill(context,
                                      ref, (b['id'] as num).toInt()),
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
    );
  }

  void _showBillForm(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BillFormSheet(
        existing: existing,
        onSaved: () => ref.invalidate(_billsProvider),
      ),
    );
  }

  Future<void> _deleteBill(
      BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg1,
        title: const Text('Faturayı Sil'),
        content: const Text('Bu faturayı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: AppColors.danger))),
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

// ── Bill card ────────────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BillCard(
      {required this.bill, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final type = bill['type'] as String? ?? 'other';
    final icon = _billTypeIcons[type] ?? Icons.receipt;
    final iconColor = _billTypeColors[type] ?? AppColors.text3Dark;
    final amount = (bill['last_amount'] as num?)?.toDouble() ?? 0;
    final dueDay = bill['due_day'] as int?;
    final isAutopay = bill['is_autopay'] as bool? ?? false;
    final status = bill['status'] as String? ?? 'upcoming';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'paid':
        statusColor = AppColors.positive;
        statusLabel = 'Ödendi';
        break;
      case 'late':
        statusColor = AppColors.negative;
        statusLabel = 'Gecikti';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'Yaklaşıyor';
    }

    return GestureDetector(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bill['provider'] ?? ''}${dueDay != null ? " · Her ayın ${dueDay}'i" : ''}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.text3Dark),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currencyCompact(amount),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isAutopay ? 'Otomatik' : statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: isAutopay ? AppColors.positive : statusColor,
                        fontWeight: FontWeight.w600),
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

// ── Bill form sheet ──────────────────────────────────────────────────
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
      _dueDayCtrl.text = (e['due_day'] as int?)?.toString() ?? '';
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
        'last_amount': double.parse(_amountCtrl.text.replaceAll(',', '.')),
        'due_day': int.tryParse(_dueDayCtrl.text) ?? 1,
        'is_autopay': _autopay,
      };
      if (_isEdit) {
        final id = (widget.existing!['id'] as num).toInt();
        await DioClient.instance.put(ApiEndpoints.bill(id), data: payload);
      } else {
        await DioClient.instance.post(ApiEndpoints.bills, data: payload);
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
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(_isEdit ? 'Fatura Düzenle' : 'Fatura Ekle',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: AppColors.bg2,
                decoration: const InputDecoration(labelText: 'Tür'),
                items: _billTypeLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Fatura Adı'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _providerCtrl,
                decoration:
                    const InputDecoration(labelText: 'Sağlayıcı (opsiyonel)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Son Tutar (₺)',
                          prefixIcon: Icon(Icons.attach_money)),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Tutar gerekli';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
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
                      decoration: const InputDecoration(
                          labelText: 'Vade Günü (1-31)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1 || n > 31) return '1-31 arası';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Otomatik Ödeme', style: AppTextStyles.bodyMedium),
                value: _autopay,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => _autopay = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
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
