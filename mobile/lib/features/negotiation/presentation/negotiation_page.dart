import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _negotiationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.negotiation);
  return res.data as Map<String, dynamic>;
});

const _letterTypes = [
  {'value': 'interest_reduction', 'label': 'Faiz İndirimi', 'icon': Icons.percent, 'desc': 'Kredi veya kredi kartı faiz oranının düşürülmesi'},
  {'value': 'subscription_cancel', 'label': 'Abonelik İptali', 'icon': Icons.cancel_outlined, 'desc': 'Abonelik iptali için müzakere'},
  {'value': 'fee_waiver', 'label': 'Ücret Muafiyeti', 'icon': Icons.money_off, 'desc': 'Banka ücreti veya ceza muafiyeti'},
  {'value': 'credit_limit', 'label': 'Limit Artırımı', 'icon': Icons.trending_up, 'desc': 'Kredi kartı limitinin artırılması'},
  {'value': 'debt_restructure', 'label': 'Borç Yapılandırma', 'icon': Icons.account_balance_outlined, 'desc': 'Kredi taksitlerinin yeniden yapılandırılması'},
  {'value': 'custom', 'label': 'Özel Mektup', 'icon': Icons.edit_note, 'desc': 'Kendi belirttiğiniz konuda müzakere'},
];

class NegotiationPage extends ConsumerWidget {
  const NegotiationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_negotiationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerateSheet(context, ref),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: const Color(0xFF051929),
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Yeni Mektup', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A2940)),
                      ),
                      child: const Icon(Icons.menu, size: 18, color: Color(0xFF8BA4BC)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Müzakere Asistanı',
                            style: AppTextStyles.headlineMedium
                                .copyWith(color: const Color(0xFFE8F4FF))),
                        Text('AI destekli taslak oluştur',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: const Color(0xFF4A6478))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Hero card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1A2940)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 22, color: Color(0xFF00D4FF)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('✦ ', style: TextStyle(
                                        color: Color(0xFF00D4FF), fontSize: 10)),
                                    Text('Yapay Zeka',
                                        style: TextStyle(
                                            color: Color(0xFF00D4FF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Banka ve abonelik şirketlerine profesyonel müzakere mektupları oluştur.',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF8BA4BC), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF00D4FF),
                backgroundColor: const Color(0xFF0D1B2A),
                onRefresh: () async => ref.invalidate(_negotiationProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_negotiationProvider),
                  ),
                  data: (data) {
                    final drafts = data['drafts'] as List? ?? [];
                    if (drafts.isEmpty) {
                      return EmptyState(
                        icon: Icons.description_outlined,
                        title: 'Henüz mektup yok',
                        subtitle:
                            'AI ile faiz indirimi, abonelik iptali ve daha fazlası için müzakere mektubu oluşturun.',
                        ctaLabel: '+ Yeni Mektup',
                        onCta: () => _showGenerateSheet(context, ref),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      itemCount: drafts.length,
                      itemBuilder: (_, i) => _DraftCard(
                        draft: drafts[i] as Map<String, dynamic>,
                        onTap: () => _viewDraft(
                            context, drafts[i] as Map<String, dynamic>),
                      ),
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

  void _showGenerateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenerateSheet(
        onGenerated: () => ref.refresh(_negotiationProvider),
      ),
    );
  }

  void _viewDraft(BuildContext context, Map<String, dynamic> draft) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DraftDetailPage(draft: draft)),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final Map<String, dynamic> draft;
  final VoidCallback onTap;
  const _DraftCard({required this.draft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeVal = draft['type'] as String? ?? 'custom';
    final typeInfo = _letterTypes.firstWhere(
        (t) => t['value'] == typeVal,
        orElse: () => _letterTypes.last);
    final status = draft['status'] as String? ?? 'draft';
    final statusColor = status == 'sent'
        ? const Color(0xFF0DD9A0)
        : status == 'draft'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF00D4FF);
    final statusLabel = status == 'sent'
        ? 'Gönderildi'
        : status == 'draft'
            ? 'Taslak'
            : 'Oluşturuldu';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A2940)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeInfo['icon'] as IconData,
                        color: const Color(0xFF00D4FF), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            draft['title'] as String? ??
                                typeInfo['label'] as String,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFFE8F4FF),
                                fontWeight: FontWeight.w600)),
                        Text(typeInfo['label'] as String,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: const Color(0xFF4A6478))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: statusColor,
                                fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (draft['summary'] != null) ...[
                const SizedBox(height: 10),
                Text(
                  draft['summary'] as String,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF8BA4BC), height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: Color(0xFF00D4FF)),
                  const SizedBox(width: 4),
                  Text('Mektubu görüntüle',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: const Color(0xFF00D4FF),
                              fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateSheet extends StatefulWidget {
  final VoidCallback onGenerated;
  const _GenerateSheet({required this.onGenerated});

  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  String? _selectedType;
  final _recipientCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _generated;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mektup türü seçin')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.negotiationGenerate,
        data: {
          'type': _selectedType,
          'recipient': _recipientCtrl.text.trim(),
          'context': _contextCtrl.text.trim(),
        },
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      setState(() {
        _generated = res.data as Map<String, dynamic>;
        _loading = false;
      });
      widget.onGenerated();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Oluşturulamadı.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    if (_generated != null) {
      return _GeneratedView(
        draft: _generated!,
        onClose: () => Navigator.pop(context),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2940),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Color(0xFF00D4FF), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Müzakere Mektubu Oluştur',
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: const Color(0xFFE8F4FF))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text('Mektup Türü',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: const Color(0xFF4A6478),
                                letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _letterTypes.map((t) {
                        final isSelected = _selectedType == t['value'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedType = t['value'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                                  : const Color(0xFF0D1B2A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00D4FF)
                                    : const Color(0xFF1A2940),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(t['icon'] as IconData,
                                    size: 15,
                                    color: isSelected
                                        ? const Color(0xFF00D4FF)
                                        : const Color(0xFF8BA4BC)),
                                const SizedBox(width: 6),
                                Text(
                                  t['label'] as String,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isSelected
                                        ? const Color(0xFF00D4FF)
                                        : const Color(0xFFE8F4FF),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedType != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _letterTypes.firstWhere(
                                (t) => t['value'] == _selectedType)[
                            'desc'] as String,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: const Color(0xFF4A6478)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _DarkTextField(
                      controller: _recipientCtrl,
                      label: 'Alıcı',
                      hint: 'ör: Garanti BBVA Müşteri Hizmetleri',
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 12),
                    _DarkTextField(
                      controller: _contextCtrl,
                      label: 'Ek Bağlam (opsiyonel)',
                      hint: 'ör: 5 yıllık müşteriyim, kredi 120.000₺',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _generate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4FF),
                          foregroundColor: const Color(0xFF051929),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF051929)))
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                            _loading ? 'Oluşturuluyor...' : 'Taslak Oluştur',
                            style: const TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: const Color(0xFF4A6478))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF060D18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2940)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 13, 0, 0),
                child: Icon(icon, size: 16, color: const Color(0xFF4A6478)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: const Color(0xFFE8F4FF)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        color: Color(0xFF4A6478), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 13),
                    isDense: true,
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

class _GeneratedView extends StatelessWidget {
  final Map<String, dynamic> draft;
  final VoidCallback onClose;
  const _GeneratedView({required this.draft, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final content = draft['content'] as String? ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2940),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0DD9A0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Color(0xFF0DD9A0), size: 18),
                ),
                const SizedBox(width: 12),
                Text('Mektup Hazır',
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: const Color(0xFFE8F4FF))),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Panoya kopyalandı')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060D18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1A2940)),
                    ),
                    child: const Icon(Icons.copy_outlined,
                        size: 16, color: Color(0xFF8BA4BC)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060D18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1A2940)),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFF8BA4BC)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Markdown(
              data: content,
              padding: const EdgeInsets.all(20),
              styleSheet: MarkdownStyleSheet(
                p: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFFE8F4FF), height: 1.6),
                h1: AppTextStyles.headlineMedium
                    .copyWith(color: const Color(0xFFE8F4FF)),
                h2: AppTextStyles.titleMedium
                    .copyWith(color: const Color(0xFFE8F4FF)),
                strong: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF00D4FF),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF051929),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Kaydedildi',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftDetailPage extends StatelessWidget {
  final Map<String, dynamic> draft;
  const _DraftDetailPage({required this.draft});

  @override
  Widget build(BuildContext context) {
    final content = draft['content'] as String? ?? '';
    final typeVal = draft['type'] as String? ?? 'custom';
    final typeInfo = _letterTypes.firstWhere(
        (t) => t['value'] == typeVal, orElse: () => _letterTypes.last);

    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A2940)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 15, color: Color(0xFF8BA4BC)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      draft['title'] as String? ?? typeInfo['label'] as String,
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: const Color(0xFFE8F4FF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Panoya kopyalandı')),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A2940)),
                      ),
                      child: const Icon(Icons.copy_outlined,
                          size: 16, color: Color(0xFF8BA4BC)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Markdown(
                data: content,
                padding: const EdgeInsets.all(20),
                styleSheet: MarkdownStyleSheet(
                  p: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFFE8F4FF), height: 1.6),
                  h1: AppTextStyles.headlineMedium
                      .copyWith(color: const Color(0xFFE8F4FF)),
                  h2: AppTextStyles.titleMedium
                      .copyWith(color: const Color(0xFFE8F4FF)),
                  strong: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF00D4FF),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
