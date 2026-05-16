import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../shared/providers/dio_provider.dart';
import '../data/transactions_api.dart';
import '../domain/transaction_model.dart';

// ── Category helpers (mirrors transactions_page) ──────────────────────
const _categoryIcons = <String, IconData>{
  'market':    Icons.local_grocery_store_outlined,
  'restoran':  Icons.restaurant_outlined,
  'yemek':     Icons.restaurant_outlined,
  'ulaşım':    Icons.directions_car_outlined,
  'giyim':     Icons.checkroom_outlined,
  'eğlence':   Icons.movie_outlined,
  'sağlık':    Icons.health_and_safety_outlined,
  'fatura':    Icons.receipt_outlined,
  'eğitim':    Icons.school_outlined,
  'teknoloji': Icons.computer_outlined,
  'spor':      Icons.fitness_center_outlined,
  'diğer':     Icons.category_outlined,
};

const _categoryColors = <String, Color>{
  'market':    Color(0xFF2BE0A0),
  'restoran':  Color(0xFFFFC857),
  'yemek':     Color(0xFFFFC857),
  'ulaşım':    Color(0xFF6FB1FC),
  'giyim':     Color(0xFFA78BFA),
  'eğlence':   Color(0xFFFF5C7C),
  'sağlık':    Color(0xFF2BE0A0),
  'fatura':    Color(0xFF6FB1FC),
  'eğitim':    Color(0xFFC99B5B),
  'teknoloji': Color(0xFF00D4FF),
  'spor':      Color(0xFF2BE0A0),
  'diğer':     Color(0xFF8FA5C2),
};

IconData _iconForCategory(String name) {
  final lower = name.toLowerCase();
  for (final key in _categoryIcons.keys) {
    if (lower.contains(key)) return _categoryIcons[key]!;
  }
  return Icons.category_outlined;
}

Color _colorForCategory(String name) {
  final lower = name.toLowerCase();
  for (final key in _categoryColors.keys) {
    if (lower.contains(key)) return _categoryColors[key]!;
  }
  return AppColors.accent;
}

String _channelLabel(String channel) {
  switch (channel) {
    case 'pos':      return 'POS / Fiziksel';
    case 'online':   return 'Online / İnternet';
    case 'atm':      return 'ATM';
    case 'transfer': return 'Transfer';
    default:         return channel;
  }
}

IconData _channelIcon(String channel) {
  switch (channel) {
    case 'pos':      return Icons.point_of_sale_outlined;
    case 'online':   return Icons.language_outlined;
    case 'atm':      return Icons.atm_outlined;
    case 'transfer': return Icons.swap_horiz_outlined;
    default:         return Icons.payment_outlined;
  }
}

// ── Provider ──────────────────────────────────────────────────────────
final _transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionModel, String>((ref, id) {
  final api = TransactionsApi(ref.watch(dioProvider));
  return api.getTransaction(id);
});

// ── Page ──────────────────────────────────────────────────────────────
class TransactionDetailPage extends ConsumerWidget {
  final String id;
  const TransactionDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final async = ref.watch(_transactionDetailProvider(id));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => Navigator.of(context).maybePop(),
              onCopy: async.valueOrNull == null
                  ? null
                  : () => _copyToClipboard(context, async.valueOrNull!),
            ),
            Expanded(
              child: async.when(
                loading: () => const _Skeleton(),
                error: (e, __) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.refresh(_transactionDetailProvider(id)),
                ),
                data: (t) => _Body(transaction: t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, TransactionModel t) {
    final text =
        '${t.merchantName ?? t.description} — ${AppFormatters.currency(t.tryAmount.abs())} — ${AppFormatters.dateTime(t.postedAt)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panoya kopyalandı'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onCopy;
  const _TopBar({required this.onBack, this.onCopy});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 16, color: c.text2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'İşlem Detayı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text1),
            ),
          ),
          if (onCopy != null)
            GestureDetector(
              onTap: onCopy,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Icon(Icons.copy_outlined, size: 16, color: c.text2),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final TransactionModel transaction;
  const _Body({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = transaction;
    final catColor = _colorForCategory(t.category.name);
    final amountColor = t.isExpense ? c.negative : c.positive;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        _HeroCard(transaction: t, catColor: catColor, amountColor: amountColor),
        const SizedBox(height: 16),
        _DetailsCard(transaction: t),
        if (t.isInstallment) ...[
          const SizedBox(height: 12),
          _InstallmentCard(transaction: t),
        ],
        if ((t.anomalyScore ?? 0) > 0.5) ...[
          const SizedBox(height: 12),
          _AnomalyCard(score: t.anomalyScore!),
        ],
      ],
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final TransactionModel transaction;
  final Color catColor;
  final Color amountColor;
  const _HeroCard({
    required this.transaction,
    required this.catColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = transaction;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          // Category icon circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: catColor.withValues(alpha: 0.12),
              border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(_iconForCategory(t.category.name), size: 32, color: catColor),
          ),
          const SizedBox(height: 16),

          // Merchant / description
          Text(
            t.merchantName ?? t.description,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text1),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.category.name,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catColor),
            ),
          ),
          const SizedBox(height: 20),

          // Amount
          Text(
            '${t.isExpense ? '-' : '+'}${AppFormatters.currency(t.tryAmount.abs())}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: amountColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Date + time
          Text(
            AppFormatters.dateTime(t.postedAt),
            style: TextStyle(fontSize: 13, color: c.text3),
          ),
          const SizedBox(height: 16),

          // Channel badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_channelIcon(t.channel), size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  _channelLabel(t.channel),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Details card ──────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final TransactionModel transaction;
  const _DetailsCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = transaction;
    final rows = <_RowData>[
      _RowData('Açıklama', t.description),
      _RowData('Kategori', t.category.name),
      _RowData('Kanal', _channelLabel(t.channel)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _DetailRow(label: rows[i].label, value: rows[i].value),
            if (i < rows.length - 1)
              Divider(height: 1, color: c.border, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _RowData {
  final String label;
  final String value;
  const _RowData(this.label, this.value);
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.text3)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.text1,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Installment card ──────────────────────────────────────────────────
class _InstallmentCard extends StatelessWidget {
  final TransactionModel transaction;
  const _InstallmentCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = transaction;
    final current = t.installmentNo ?? 1;
    final total = t.installmentTotal ?? 1;
    final progress = current / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Taksit Bilgisi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2),
              ),
              const Spacer(),
              Text(
                '$current / $total',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: c.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$current. taksit ödendi · ${total - current} taksit kaldı',
            style: TextStyle(fontSize: 11, color: c.text3),
          ),
        ],
      ),
    );
  }
}

// ── Anomaly card ──────────────────────────────────────────────────────
class _AnomalyCard extends StatelessWidget {
  final double score;
  const _AnomalyCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final severity = score > 0.85 ? 'Yüksek Risk' : 'Olağandışı';
    final color = score > 0.85 ? c.negative : c.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$severity Anomali',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bu işlem harcama kalıplarınızdan sapıyor. Skor: ${(score * 100).round()}',
                  style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: const [
        SkeletonCard(height: 260),
        SizedBox(height: 16),
        SkeletonCard(height: 160),
      ],
    );
  }
}
