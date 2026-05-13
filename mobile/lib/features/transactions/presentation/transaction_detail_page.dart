import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../shared/providers/dio_provider.dart';
import '../data/transactions_api.dart';
import '../domain/transaction_model.dart';

final _transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionModel, String>((ref, id) {
  final api = TransactionsApi(ref.watch(dioProvider));
  return api.getTransaction(id);
});

class TransactionDetailPage extends ConsumerWidget {
  final String id;
  const TransactionDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_transactionDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('İşlem Detayı')),
      body: async.when(
        loading: () => ListView(children: const [
          SkeletonCard(height: 200),
          SkeletonCard(),
        ]),
        error: (e, __) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(_transactionDetailProvider(id)),
        ),
        data: (t) => _TransactionDetail(transaction: t),
      ),
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionDetail({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isExpense = t.isExpense;
    final amountColor = isExpense ? AppColors.expense : AppColors.income;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Amount hero
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: amountColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: amountColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: amountColor.withOpacity(0.15),
                child: Icon(
                  isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${isExpense ? '-' : '+'}${AppFormatters.currency(t.tryAmount.abs())}',
                style:
                    AppTextStyles.amountHero.copyWith(color: amountColor),
              ),
              const SizedBox(height: 4),
              Text(
                t.merchantName ?? t.description,
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.dateTime(t.postedAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Details card
        _DetailCard(children: [
          _DetailRow(label: 'Açıklama', value: t.description),
          _DetailRow(
              label: 'Kategori', value: t.category.name),
          _DetailRow(
              label: 'Kanal', value: _channelLabel(t.channel)),
          if (t.isInstallment) ...[
            _DetailRow(
              label: 'Taksit',
              value: '${t.installmentNo}. / ${t.installmentTotal} taksit',
            ),
          ],
          if (t.anomalyScore != null && t.anomalyScore! > 0.5) ...[
            _DetailRow(
              label: 'Anomali',
              value: 'Olağandışı işlem tespit edildi',
              valueColor: AppColors.warning,
            ),
          ],
        ]),
      ],
    );
  }

  String _channelLabel(String channel) {
    switch (channel) {
      case 'pos':
        return 'POS / Fiziksel';
      case 'online':
        return 'Online / İnternet';
      case 'atm':
        return 'ATM';
      case 'transfer':
        return 'Transfer';
      default:
        return channel;
    }
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              )),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
