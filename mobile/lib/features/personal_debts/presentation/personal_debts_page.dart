import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _personalDebtsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.personalDebts);
  return res.data as Map<String, dynamic>;
});

class PersonalDebtsPage extends ConsumerWidget {
  const PersonalDebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_personalDebtsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 14, color: AppColors.text2Dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Kişisel Borçlar',
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: AppColors.text1Dark)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_personalDebtsProvider),
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_personalDebtsProvider),
          ),
          data: (data) {
            final debts = data['debts'] as List? ?? [];
            final summary = data['summary'] as Map<String, dynamic>?;

            if (debts.isEmpty) {
              return EmptyState(
                icon: Icons.handshake_outlined,
                title: 'Kişisel borç bulunamadı',
                subtitle: 'Arkadaş ve aile borçlarını takip edin.',
                ctaLabel: '+ Borç Ekle',
                onCta: () => _showForm(context, ref, null),
              );
            }

            final iOwe = (summary?['i_owe'] as num?)?.toDouble() ?? 0;
            final owedToMe = (summary?['owed_to_me'] as num?)?.toDouble() ?? 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        label: 'Borcum',
                        amount: iOwe,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryBox(
                        label: 'Alacağım',
                        amount: owedToMe,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...debts.map((d) => _DebtCard(
                      debt: d as Map<String, dynamic>,
                      onSettle: () => _settle(
                          context, ref, (d['id'] as num).toInt()),
                      onEdit: () => _showForm(context, ref, d),
                    )),
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

  void _showForm(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DebtFormSheet(
        existing: existing,
        onSaved: () => ref.refresh(_personalDebtsProvider),
      ),
    );
  }

  Future<void> _settle(
      BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borcu Kapat'),
        content: const Text('Bu borcu kapalı olarak işaretlemek istiyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kapat')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await DioClient.instance
            .post(ApiEndpoints.personalDebtSettle(id));
        ref.invalidate(_personalDebtsProvider);
      } catch (_) {}
    }
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryBox(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(AppFormatters.currency(amount),
              style: AppTextStyles.titleMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Map<String, dynamic> debt;
  final VoidCallback onSettle;
  final VoidCallback onEdit;
  const _DebtCard(
      {required this.debt, required this.onSettle, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isBorrowed = debt['type'] == 'borrowed'; // i owe
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final name = debt['counterparty_name'] as String? ?? 'Bilinmiyor';
    final description = debt['description'] as String?;
    final dueDate = debt['due_date'] as String?;
    final isSettled = debt['is_settled'] as bool? ?? false;
    final color = isBorrowed ? AppColors.danger : AppColors.success;
    final label = isBorrowed ? 'Borçlu' : 'Alacaklı';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.titleMedium),
                      Text(label,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: color)),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.currency(amount),
                  style:
                      AppTextStyles.titleMedium.copyWith(color: color),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight)),
            ],
            if (dueDate != null) ...[
              const SizedBox(height: 4),
              Text('Vade: ${AppFormatters.dateFromIso(dueDate)}',
                  style: AppTextStyles.bodySmall),
            ],
            if (!isSettled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onEdit,
                      child: const Text('Düzenle'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSettle,
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text('Kapatıldı',
                      style: TextStyle(
                          color: AppColors.success, fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _DebtFormSheet({this.existing, required this.onSaved});

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'borrowed';
  DateTime? _dueDate;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['counterparty_name'] as String? ?? '';
      _amountCtrl.text =
          (e['amount'] as num?)?.toStringAsFixed(2) ?? '';
      _descCtrl.text = e['description'] as String? ?? '';
      _type = e['type'] as String? ?? 'borrowed';
      final dd = e['due_date'] as String?;
      if (dd != null) _dueDate = DateTime.tryParse(dd);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'type': _type,
        'counterparty_name': _nameCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text.replaceAll(',', '.')),
        'description': _descCtrl.text.trim(),
        if (_dueDate != null)
          'due_date': _dueDate!.toIso8601String().split('T').first,
      };
      if (_isEdit) {
        final id = (widget.existing!['id'] as num).toInt();
        await DioClient.instance
            .put(ApiEndpoints.personalDebt(id), data: payload);
      } else {
        await DioClient.instance
            .post(ApiEndpoints.personalDebts, data: payload);
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
              Text(_isEdit ? 'Borç Düzenle' : 'Borç Ekle',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Borçluyum'),
                      value: 'borrowed',
                      groupValue: _type,
                      onChanged: (v) => setState(() => _type = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Alacaklıyım'),
                      value: 'lent',
                      groupValue: _type,
                      onChanged: (v) => setState(() => _type = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Kişi Adı',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                    labelText: 'Tutar (₺)',
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
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Açıklama (opsiyonel)',
                    prefixIcon: Icon(Icons.notes_outlined)),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Son Ödeme Tarihi (opsiyonel)',
                      prefixIcon:
                          const Icon(Icons.calendar_today_outlined),
                      hintText: _dueDate != null
                          ? AppFormatters.dateShort(_dueDate!)
                          : 'Tarih seçin',
                    ),
                    controller: TextEditingController(
                      text: _dueDate != null
                          ? AppFormatters.dateShort(_dueDate!)
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
