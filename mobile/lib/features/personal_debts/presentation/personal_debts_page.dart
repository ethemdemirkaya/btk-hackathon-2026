import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
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

// ── Provider ─────────────────────────────────────────────────────────
final _personalDebtsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.personalDebts);
  return res.data as Map<String, dynamic>;
});

// ── Page ──────────────────────────────────────────────────────────────
class PersonalDebtsPage extends ConsumerWidget {
  const PersonalDebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_personalDebtsProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
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
                final count =
                    (data['debts'] as List? ?? []).length;
                return _buildHeader('$count kayıt');
              },
            ),
            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
                onRefresh: () async =>
                    ref.invalidate(_personalDebtsProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_personalDebtsProvider),
                  ),
                  data: (data) {
                    final debts = data['debts'] as List? ?? [];
                    final summary =
                        data['summary'] as Map<String, dynamic>?;

                    if (debts.isEmpty) {
                      return EmptyState(
                        icon: Icons.handshake_outlined,
                        title: 'Kişisel borç bulunamadı',
                        subtitle:
                            'Arkadaş ve aile borçlarını takip edin.',
                        ctaLabel: '+ Borç Ekle',
                        onCta: () => _showForm(context, ref, null),
                      );
                    }

                    final iOwe =
                        (summary?['i_owe'] as num?)?.toDouble() ??
                            0;
                    final owedToMe =
                        (summary?['owed_to_me'] as num?)
                                ?.toDouble() ??
                            0;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 100),
                      children: [
                        // ── Summary ──────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                label: 'Verilecek',
                                amount: iOwe,
                                color: _negative,
                                icon: Icons.arrow_upward,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                label: 'Alınacak',
                                amount: owedToMe,
                                color: _positive,
                                icon: Icons.arrow_downward,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ── AI Tespit Butonu ──────────────────
                        _AiDetectButton(
                          onDetected: () => ref.invalidate(_personalDebtsProvider),
                        ),
                        const SizedBox(height: 12),
                        ...debts.map((d) => _DebtCard(
                              debt: d as Map<String, dynamic>,
                              onSettle: () => _settle(
                                  context,
                                  ref,
                                  (d['id'] as num).toInt()),
                              onEdit: () =>
                                  _showForm(context, ref, d),
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
                const Text('Kişisel Borçlar',
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
        ],
      ),
    );
  }

  void _showForm(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
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
        backgroundColor: _cardBg,
        title: const Text('Borcu Kapat',
            style: TextStyle(color: _text1)),
        content: const Text(
            'Bu borcu kapalı olarak işaretlemek istiyor musunuz?',
            style: TextStyle(color: _text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('İptal', style: TextStyle(color: _text2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _positive,
                foregroundColor: Colors.black),
            child: const Text('Kapat'),
          ),
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

// ── Summary card ──────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: _text3)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppFormatters.currencyCompact(amount),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ── Debt card ─────────────────────────────────────────────────────────
class _DebtCard extends StatelessWidget {
  final Map<String, dynamic> debt;
  final VoidCallback onSettle;
  final VoidCallback onEdit;
  const _DebtCard(
      {required this.debt,
      required this.onSettle,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isBorrowed = debt['type'] == 'borrowed';
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final name = debt['counterparty_name'] as String? ?? 'Bilinmiyor';
    final description = debt['description'] as String?;
    final dueDate = debt['due_date'] as String?;
    final isSettled = debt['is_settled'] as bool? ?? false;
    final color = isBorrowed ? _negative : _positive;
    final label = isBorrowed ? 'Borç' : 'Alacak';
    final avatarLetter =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _text1)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ),
                          if (dueDate != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Vade: ${AppFormatters.dateFromIso(dueDate)}',
                              style: const TextStyle(
                                  fontSize: 11, color: _text3),
                            ),
                          ],
                        ],
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(
                      fontSize: 12, color: _text2)),
            ],
            if (isSettled) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: _positive, size: 14),
                  SizedBox(width: 4),
                  Text('Kapatıldı',
                      style: TextStyle(
                          fontSize: 12, color: _positive)),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _scaffoldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: const Center(
                          child: Text('Düzenle',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _text2)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onSettle,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _positive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  _positive.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 14, color: _positive),
                            SizedBox(width: 4),
                            Text('Kapat',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _positive)),
                          ],
                        ),
                      ),
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

// ── Debt form sheet ───────────────────────────────────────────────────
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
        'amount':
            double.parse(_amountCtrl.text.replaceAll(',', '.')),
        'description': _descCtrl.text.trim(),
        if (_dueDate != null)
          'due_date':
              _dueDate!.toIso8601String().split('T').first,
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
              Text(_isEdit ? 'Borç Düzenle' : 'Borç Ekle',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _text1)),
              const SizedBox(height: 16),
              // Type toggle
              Row(
                children: [
                  _TypeBtn(
                    label: 'Borçluyum',
                    selected: _type == 'borrowed',
                    color: _negative,
                    onTap: () =>
                        setState(() => _type = 'borrowed'),
                  ),
                  const SizedBox(width: 8),
                  _TypeBtn(
                    label: 'Alacaklıyım',
                    selected: _type == 'lent',
                    color: _positive,
                    onTap: () => setState(() => _type = 'lent'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                style:
                    const TextStyle(color: _text1, fontSize: 14),
                decoration:
                    _deco('Kişi Adı', icon: Icons.person_outline),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Ad gerekli'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                style:
                    const TextStyle(color: _text1, fontSize: 14),
                decoration:
                    _deco('Tutar (₺)', icon: Icons.attach_money),
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
                  final n = double.tryParse(
                      v.replaceAll(',', '.'));
                  if (n == null || n <= 0) {
                    return 'Geçerli tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                style:
                    const TextStyle(color: _text1, fontSize: 14),
                decoration: _deco('Açıklama (opsiyonel)',
                    icon: Icons.notes_outlined),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    style: const TextStyle(
                        color: _text1, fontSize: 14),
                    decoration: _deco(
                            'Son Ödeme Tarihi (opsiyonel)',
                            icon: Icons.calendar_today_outlined)
                        .copyWith(
                      hintText: _dueDate != null
                          ? AppFormatters.dateShort(_dueDate!)
                          : 'Tarih seçin',
                      hintStyle: const TextStyle(color: _text3),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF051929),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
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
                      : Text(_isEdit ? 'Güncelle' : 'Kaydet',
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

// ── AI Borç Tespit Butonu + Bottom Sheet ─────────────────────────────────
class _AiDetectButton extends StatefulWidget {
  final VoidCallback onDetected;
  const _AiDetectButton({required this.onDetected});

  @override
  State<_AiDetectButton> createState() => _AiDetectButtonState();
}

class _AiDetectButtonState extends State<_AiDetectButton> {
  bool _loading = false;

  Future<void> _scan() async {
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance
          .get(ApiEndpoints.personalDebtsAutoDetect);
      final data = res.data as Map<String, dynamic>;
      final debts = (data['debt_suggestions'] as List?) ?? [];
      final repayments = (data['repayment_suggestions'] as List?) ?? [];

      if (!mounted) return;

      if (debts.isEmpty && repayments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Son 90 günde tespit edilecek borç hareketi bulunamadı.'),
          backgroundColor: Color(0xFF0D1B2A),
        ));
        return;
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0D1B2A),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _DetectionSheet(
          debtSuggestions: debts.cast<Map<String, dynamic>>(),
          repaymentSuggestions: repayments.cast<Map<String, dynamic>>(),
          onChanged: widget.onDetected,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tespit sırasında hata oluştu.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _scan,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: _accent),
                    )
                  : const Icon(Icons.auto_awesome,
                      size: 16, color: _accent),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Borç Tespiti',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _text1)),
                  Text('Hareketlerde borç/geri ödeme ara',
                      style: TextStyle(fontSize: 11, color: _text3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _text3),
          ],
        ),
      ),
    );
  }
}

// ── Tespit Sonuçları Bottom Sheet ────────────────────────────────────────────
class _DetectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> debtSuggestions;
  final List<Map<String, dynamic>> repaymentSuggestions;
  final VoidCallback onChanged;

  const _DetectionSheet({
    required this.debtSuggestions,
    required this.repaymentSuggestions,
    required this.onChanged,
  });

  @override
  State<_DetectionSheet> createState() => _DetectionSheetState();
}

class _DetectionSheetState extends State<_DetectionSheet> {
  final Set<int> _dismissedDebts = {};
  final Set<int> _dismissedRepayments = {};

  String _fmt(double v) =>
      '₺${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Future<void> _confirmDebt(int idx) async {
    final s = widget.debtSuggestions[idx];
    try {
      await DioClient.instance.post(
        ApiEndpoints.personalDebtsConfirm,
        data: {
          'contact_name':   s['suggested_contact'] ?? 'Bilinmiyor',
          'amount':         s['amount'],
          'direction':      s['direction'],
          'note':           s['description'],
          'transaction_id': s['transaction_id'],
        },
      );
      setState(() => _dismissedDebts.add(idx));
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Borç kaydedildi.'),
            backgroundColor: Color(0xFF0DD9A0)));
      }
    } catch (_) {}
  }

  Future<void> _confirmRepayment(int idx) async {
    final s = widget.repaymentSuggestions[idx];
    final debtId = (s['debt_id'] as num).toInt();
    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.personalDebtMarkRepayment(debtId),
        data: {
          'transaction_id':   s['transaction_id'],
          'repayment_amount': s['repayment_amount'],
        },
      );
      setState(() => _dismissedRepayments.add(idx));
      widget.onChanged();
      final profit = (res.data['profit'] as num?)?.toDouble() ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(profit > 0
              ? '${_fmt(profit)} kar ile borç kapatıldı!'
              : 'Borç kapatıldı.'),
          backgroundColor:
              profit > 0 ? const Color(0xFF0DD9A0) : const Color(0xFF0D1B2A),
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final debts = widget.debtSuggestions
        .asMap()
        .entries
        .where((e) => !_dismissedDebts.contains(e.key))
        .toList();
    final repayments = widget.repaymentSuggestions
        .asMap()
        .entries
        .where((e) => !_dismissedRepayments.contains(e.key))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A2940),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('AI Borç Tespiti',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8F4FF))),
          const SizedBox(height: 4),
          Text('${debts.length + repayments.length} öneri bulundu',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4A6478))),
          const SizedBox(height: 20),

          // ── Borç Önerileri ────────────────────────────────────────────
          if (debts.isNotEmpty) ...[
            const Text('Yeni Borç Önerileri',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8BA4BC))),
            const SizedBox(height: 10),
            ...debts.map((e) => _DebtSuggestionCard(
                  suggestion: e.value,
                  onConfirm: () => _confirmDebt(e.key),
                  onDismiss: () =>
                      setState(() => _dismissedDebts.add(e.key)),
                )),
            const SizedBox(height: 16),
          ],

          // ── Geri Ödeme Önerileri ──────────────────────────────────────
          if (repayments.isNotEmpty) ...[
            const Text('Geri Ödeme Önerileri',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8BA4BC))),
            const SizedBox(height: 10),
            ...repayments.map((e) => _RepaymentSuggestionCard(
                  suggestion: e.value,
                  onConfirm: () => _confirmRepayment(e.key),
                  onDismiss: () =>
                      setState(() => _dismissedRepayments.add(e.key)),
                )),
          ],

          if (debts.isEmpty && repayments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Tüm öneriler işlendi.',
                    style: TextStyle(color: Color(0xFF4A6478))),
              ),
            ),
        ],
      ),
    );
  }
}

class _DebtSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  const _DebtSuggestionCard(
      {required this.suggestion,
      required this.onConfirm,
      required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final amount = (suggestion['amount'] as num?)?.toDouble() ?? 0;
    final dir = suggestion['direction'] as String? ?? 'given';
    final isGiven = dir == 'given';
    final color = isGiven ? const Color(0xFF0DD9A0) : const Color(0xFFFF4D6D);
    final label = isGiven ? 'Verdiğim borç' : 'Aldığım borç';
    final desc = suggestion['description'] as String? ?? '';
    final contact = suggestion['suggested_contact'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF060D18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
            const Spacer(),
            Text('₺${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ]),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF8BA4BC))),
          ],
          if (contact != null) ...[
            const SizedBox(height: 4),
            Text('Kişi: $contact',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF4A6478))),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A6478),
                  side: const BorderSide(color: Color(0xFF1A2940)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Atla', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: const Color(0xFF051929),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Borç Ekle',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _RepaymentSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  const _RepaymentSuggestionCard(
      {required this.suggestion,
      required this.onConfirm,
      required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final debtAmount = (suggestion['debt_amount'] as num?)?.toDouble() ?? 0;
    final repayAmount = (suggestion['repayment_amount'] as num?)?.toDouble() ?? 0;
    final profit = (suggestion['profit'] as num?)?.toDouble() ?? 0;
    final contact = suggestion['debt_contact'] as String? ?? 'Bilinmiyor';
    final desc = suggestion['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF060D18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$contact geri ödüyor mu?',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8F4FF))),
          const SizedBox(height: 8),
          Row(children: [
            _InfoChip('Borç', '₺${debtAmount.toStringAsFixed(2)}',
                const Color(0xFFFF4D6D)),
            const SizedBox(width: 8),
            _InfoChip('Gelen', '₺${repayAmount.toStringAsFixed(2)}',
                const Color(0xFF0DD9A0)),
            if (profit > 0) ...[
              const SizedBox(width: 8),
              _InfoChip('Kar', '+₺${profit.toStringAsFixed(2)}',
                  const Color(0xFFF59E0B)),
            ],
          ]),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF4A6478))),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A6478),
                  side: const BorderSide(color: Color(0xFF1A2940)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Hayır',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF051929),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Evet, Kapat',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF4A6478))),
        ],
      ),
    );
  }
}

// ── _TypeBtn ─────────────────────────────────────────────────────────────────
class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : _scaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.4)
                    : _cardBorder),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : _text3)),
          ),
        ),
      ),
    );
  }
}
