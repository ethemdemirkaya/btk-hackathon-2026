import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _receiptsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.receipts);
  final list = (res.data as Map<String, dynamic>)['receipts'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});

class ReceiptsPage extends ConsumerStatefulWidget {
  const ReceiptsPage({super.key});

  @override
  ConsumerState<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends ConsumerState<ReceiptsPage> {
  bool _uploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(picked.path, filename: 'receipt.jpg'),
      });
      final res = await DioClient.instance.post(
        ApiEndpoints.receipts,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final receipt = (res.data as Map<String, dynamic>)['receipt'] as Map<String, dynamic>?;
      ref.invalidate(_receiptsProvider);
      if (receipt != null && mounted) {
        _showResult(receipt);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showResult(Map<String, dynamic> receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReceiptResultSheet(receipt: receipt),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera ile Çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReceipt(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fişi sil'),
        content: const Text('Bu fiş kaydı silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await DioClient.instance.delete(ApiEndpoints.receipt(id));
      ref.invalidate(_receiptsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silinemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_receiptsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _showPickerOptions,
        icon: _uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.document_scanner),
        label: Text(_uploading ? 'İşleniyor...' : 'Fiş Tara'),
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
                  Text('Fişler',
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: AppColors.text1Dark)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_receiptsProvider),
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_receiptsProvider),
          ),
          data: (receipts) {
            if (receipts.isEmpty) {
              return EmptyState(
                icon: Icons.document_scanner,
                title: 'Henüz fiş yok',
                subtitle: 'Kameranızla fiş çekerek işlemlerinizi otomatik kaydedin.',
                ctaLabel: 'Fiş Tara',
                onCta: _showPickerOptions,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: receipts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ReceiptCard(
                receipt: receipts[i],
                onTap: () => _showResult(receipts[i]),
                onDelete: () => _deleteReceipt(receipts[i]['id'] as int),
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
}

class _ReceiptCard extends StatelessWidget {
  final Map<String, dynamic> receipt;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ReceiptCard({
    required this.receipt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = (receipt['total_amount'] as num?)?.toDouble() ?? 0;
    final merchant = receipt['merchant_name'] as String? ?? 'Bilinmeyen';
    final dateStr = receipt['purchased_at'] as String?;
    final category = receipt['category'] as String?;
    final itemsCount = (receipt['items_count'] as num?)?.toInt() ?? 0;

    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onDelete,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
        ),
        title: Text(merchant, style: AppTextStyles.bodyMedium),
        subtitle: Text(
          [
            if (dateStr != null) AppFormatters.dateFromIso(dateStr),
            if (category != null) category,
            if (itemsCount > 0) '$itemsCount ürün',
          ].join(' · '),
          style: AppTextStyles.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          AppFormatters.currency(total),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ReceiptResultSheet extends StatelessWidget {
  final Map<String, dynamic> receipt;
  const _ReceiptResultSheet({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final merchant = receipt['merchant_name'] as String? ?? 'Bilinmeyen';
    final total = (receipt['total_amount'] as num?)?.toDouble() ?? 0;
    final currency = receipt['currency'] as String? ?? 'TRY';
    final category = receipt['category'] as String?;
    final dateStr = receipt['purchased_at'] as String?;
    final items = receipt['items'] as List? ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: ctrl,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  child: Icon(Icons.check, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fiş Tarandı', style: AppTextStyles.titleMedium),
                      Text(merchant, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow('Toplam', '$currency ${AppFormatters.currency(total)}'),
            if (category != null) _InfoRow('Kategori', category),
            if (dateStr != null) _InfoRow('Tarih', AppFormatters.dateFromIso(dateStr)),
            if (items.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Ürünler (${items.length})', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              ...items.map((item) {
                final i = item as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          i['name'] as String? ?? '',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(
                            (i['total'] as num?)?.toDouble() ?? 0),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
