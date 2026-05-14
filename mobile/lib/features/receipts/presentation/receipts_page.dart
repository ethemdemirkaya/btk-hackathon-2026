import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _positive   = Color(0xFF0DD9A0);
const _negative   = Color(0xFFFF4D6D);
// ignore: unused_element
const _warning    = Color(0xFFF59E0B);

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
        'image': await MultipartFile.fromFile(picked.path,
            filename: 'receipt.jpg'),
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
      final receipt = (res.data as Map<String, dynamic>)['receipt']
          as Map<String, dynamic>?;
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
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptResultSheet(receipt: receipt),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _PickerOption(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera ile Çek',
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            _PickerOption(
              icon: Icons.photo_library_outlined,
              label: 'Galeriden Seç',
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReceipt(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Fişi Sil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text1)),
        content: const Text('Bu fiş kaydı silinecek.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _text2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _negative,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600)),
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
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _showPickerOptions,
        backgroundColor: _accent,
        foregroundColor: const Color(0xFF051929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: _uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF051929)),
              )
            : const Icon(Icons.camera_alt, size: 22),
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
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Icon(Icons.menu,
                          size: 18, color: _text2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fişler & Makbuzlar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text1)),
                        const Text('OCR ile tara',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
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
                        subtitle:
                            'Kameranızla fiş çekerek işlemlerinizi otomatik kaydedin.',
                        ctaLabel: 'Fiş Tara',
                        onCta: _showPickerOptions,
                      );
                    }
                    // Hero summary card
                    final totalAmount = receipts.fold(
                        0.0,
                        (sum, r) =>
                            sum +
                            ((r['total_amount'] as num?)?.toDouble() ?? 0));
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      children: [
                        _HeroSummaryCard(
                          count: receipts.length,
                          total: totalAmount,
                        ),
                        const SizedBox(height: 16),
                        ...receipts.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReceiptCard(
                                receipt: e.value,
                                onTap: () => _showResult(e.value),
                                onDelete: () =>
                                    _deleteReceipt(e.value['id'] as int),
                              ),
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
}

class _HeroSummaryCard extends StatelessWidget {
  final int count;
  final double total;
  const _HeroSummaryCard({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long,
                size: 24, color: _accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count fiş kaydedildi',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _text1),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppFormatters.currencyCompact(total)} toplam',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400, color: _text3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _scaffoldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: _accent),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _text1)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: _text3),
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

    return GestureDetector(
      onTap: onTap,
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long,
                  color: _accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(merchant,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _text1)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (dateStr != null)
                        AppFormatters.dateFromIso(dateStr),
                      if (category != null) category,
                      if (itemsCount > 0) '$itemsCount ürün',
                    ].join(' · '),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400, color: _text3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              AppFormatters.currency(total),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _text1),
            ),
          ],
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

    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: _positive, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fiş Tarandı',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text1)),
                      Text(merchant,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w400, color: _text3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _scaffoldBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                children: [
                  _InfoRow('Toplam',
                      '$currency ${AppFormatters.currency(total)}'),
                  if (category != null)
                    _InfoRow('Kategori', category),
                  if (dateStr != null)
                    _InfoRow('Tarih', AppFormatters.dateFromIso(dateStr)),
                ],
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Ürünler (${items.length})',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _text3,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _scaffoldBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  children: items.asMap().entries.map((entry) {
                    final i = entry.value as Map<String, dynamic>;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: entry.key > 0
                            ? const Border(
                                top: BorderSide(
                                    color: _cardBorder))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i['name'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _text1),
                            ),
                          ),
                          Text(
                            AppFormatters.currency(
                                (i['total'] as num?)?.toDouble() ?? 0),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _text2),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF051929),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Tamam',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w400, color: _text2)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _text1)),
        ],
      ),
    );
  }
}
