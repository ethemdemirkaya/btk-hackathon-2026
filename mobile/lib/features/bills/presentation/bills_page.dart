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
const _warning    = Color(0xFFF59E0B);

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
    final async = ref.watch(_billsProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBillForm(context, ref, null),
        backgroundColor: _accent,
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
              loading: () => _buildHeader('Yükleniyor…'),
              error: (_, __) => _buildHeader(''),
              data: (data) {
                final bills =
                    (data['bills'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                final unpaid =
                    bills.where((b) => b['status'] != 'paid').length;
                return _buildHeader(
                    'Bu ay $unpaid ödenmemiş');
              },
            ),
            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
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
                                      '₺${AppFormatters.currencyCompact(pendingTotal)}',
                                  icon: Icons.pending_outlined,
                                  color: _warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatChip(
                                  label: 'Aylık Est.',
                                  value:
                                      '₺${AppFormatters.currencyCompact(totalMonthly)}',
                                  icon:
                                      Icons.calendar_month_outlined,
                                  color: _accent,
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
                            children: bills
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

  Widget _buildHeader(String subtitle) {
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
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: const Icon(Icons.menu, size: 18, color: _text2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Faturalar',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _text1)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: _text3)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Faturayı Sil',
            style: TextStyle(color: _text1)),
        content: const Text(
            'Bu faturayı silmek istediğinize emin misiniz?',
            style: TextStyle(color: _text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal',
                  style: TextStyle(color: _text2))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: _negative))),
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
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
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
                  style: const TextStyle(
                      fontSize: 10, color: _text3)),
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
        statusColor = _positive;
        statusLabel = 'Ödendi';
        break;
      case 'late':
        statusColor = _negative;
        statusLabel = 'Gecikti';
        break;
      default:
        statusColor = _warning;
        statusLabel = 'Yaklaşıyor';
    }

    return GestureDetector(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
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
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _text1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bill['provider'] ?? ''}${dueDay != null ? " · Her ayın $dueDay'i" : ''}',
                    style: const TextStyle(
                        fontSize: 11, color: _text3),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${AppFormatters.currencyCompact(amount)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _text1),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAutopay
                            ? _positive
                            : statusColor)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: (isAutopay
                                ? _positive
                                : statusColor)
                            .withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    isAutopay ? 'Otomatik' : statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAutopay
                            ? _positive
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

  InputDecoration _deco(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _text3, fontSize: 13),
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: _text3) : null,
        filled: true,
        fillColor: _scaffoldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cardBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cardBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _accent, width: 1.5)),
      );

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
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _cardBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(_isEdit ? 'Fatura Düzenle' : 'Fatura Ekle',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _text1)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: _cardBg,
                style: const TextStyle(
                    color: _text1, fontSize: 14),
                decoration: _deco('Tür'),
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
                style: const TextStyle(
                    color: _text1, fontSize: 14),
                decoration: _deco('Fatura Adı'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Ad gerekli'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _providerCtrl,
                style: const TextStyle(
                    color: _text1, fontSize: 14),
                decoration:
                    _deco('Sağlayıcı (opsiyonel)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      style: const TextStyle(
                          color: _text1, fontSize: 14),
                      decoration: _deco('Son Tutar (₺)',
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
                      style: const TextStyle(
                          color: _text1, fontSize: 14),
                      decoration:
                          _deco('Vade Günü (1-31)'),
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
                  color: _scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 12),
                  title: const Text('Otomatik Ödeme',
                      style: TextStyle(
                          fontSize: 14,
                          color: _text1)),
                  value: _autopay,
                  activeThumbColor: _accent,
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
                    backgroundColor: _accent,
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
