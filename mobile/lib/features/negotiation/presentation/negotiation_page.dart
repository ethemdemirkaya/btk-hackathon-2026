import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
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
      appBar: AppBar(title: const Text('Müzakere Mektupları')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerateSheet(context, ref),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Yeni Mektup'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(_negotiationProvider),
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.refresh(_negotiationProvider),
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
              padding: const EdgeInsets.all(16),
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
    );
  }

  void _showGenerateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
        ? AppColors.success
        : status == 'draft'
            ? AppColors.warning
            : AppColors.info;
    final statusLabel = status == 'sent'
        ? 'Gönderildi'
        : status == 'draft'
            ? 'Taslak'
            : 'Oluşturuldu';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeInfo['icon'] as IconData,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            draft['title'] as String? ??
                                typeInfo['label'] as String,
                            style: AppTextStyles.titleMedium),
                        Text(typeInfo['label'] as String,
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: statusColor)),
                  ),
                ],
              ),
              if (draft['summary'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  draft['summary'] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textSecondaryLight),
                  Text('Mektubu görüntüle',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary)),
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

    return DraggableScrollableSheet(
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Müzakere Mektubu Oluştur',
                      style: AppTextStyles.headlineMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Text('Mektup Türü', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _letterTypes.map((t) {
                      final isSelected = _selectedType == t['value'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedType = t['value'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                t['label'] as String,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedType != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _letterTypes.firstWhere(
                          (t) => t['value'] == _selectedType)['desc'] as String,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: _recipientCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alıcı (ör: Garanti BBVA Müşteri Hizmetleri)',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contextCtrl,
                    decoration: const InputDecoration(
                      labelText:
                          'Ek Bağlam (opsiyonel, ör: 5 yıllık müşteriyim, kredi 120.000₺)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_loading ? 'Oluşturuluyor...' : 'Mektup Oluştur'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Mektup Hazır', style: AppTextStyles.headlineMedium),
              const Spacer(),
              IconButton(
                  onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: Markdown(
            data: content,
            padding: const EdgeInsets.all(16),
            styleSheet: MarkdownStyleSheet(
              p: AppTextStyles.bodyMedium,
              h1: AppTextStyles.headlineMedium,
              h2: AppTextStyles.titleMedium,
              strong: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  label: const Text('Kapat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.check),
                  label: const Text('Kaydedildi'),
                ),
              ),
            ],
          ),
        ),
      ],
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
      appBar: AppBar(
        title: Text(draft['title'] as String? ?? typeInfo['label'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Markdown(
        data: content,
        padding: const EdgeInsets.all(20),
        styleSheet: MarkdownStyleSheet(
          p: AppTextStyles.bodyMedium.copyWith(height: 1.6),
          h1: AppTextStyles.headlineMedium,
          h2: AppTextStyles.titleMedium,
          strong:
              AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
