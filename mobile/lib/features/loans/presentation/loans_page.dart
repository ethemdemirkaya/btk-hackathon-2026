import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _loansProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.loans);
  return res.data as Map<String, dynamic>;
});

const _loanTypeLabels = {
  'personal': 'İhtiyaç Kredisi',
  'mortgage': 'Konut Kredisi',
  'vehicle': 'Taşıt Kredisi',
  'commercial': 'Ticari Kredi',
};

class LoansPage extends ConsumerWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_loansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kredilerim')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(_loansProvider),
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.refresh(_loansProvider),
          ),
          data: (data) {
            final loans = data['loans'] as List? ?? [];
            if (loans.isEmpty) {
              return const EmptyState(
                icon: Icons.account_balance,
                title: 'Kredi bulunamadı',
                subtitle: 'Banka hesabınızı bağlayınca kredileriniz görünür.',
              );
            }
            final totalBalance =
                (data['total_balance'] as num?)?.toDouble() ?? 0;
            final due30 =
                (data['due_next_30_days'] as num?)?.toDouble() ?? 0;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _LoanSummary(total: totalBalance, due30: due30),
                const SizedBox(height: 16),
                ...loans.map((l) =>
                    _LoanItem(loan: l as Map<String, dynamic>)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoanSummary extends StatelessWidget {
  final double total;
  final double due30;
  const _LoanSummary({required this.total, required this.due30});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toplam Kredi', style: AppTextStyles.bodySmall),
                Text(AppFormatters.currency(total),
                    style: AppTextStyles.amountMedium
                        .copyWith(color: AppColors.warning)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('30 gün içinde', style: AppTextStyles.bodySmall),
                Text(AppFormatters.currency(due30),
                    style: AppTextStyles.amountMedium
                        .copyWith(color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanItem extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _LoanItem({required this.loan});

  @override
  Widget build(BuildContext context) {
    final pct = (loan['progress_pct'] as num?)?.toDouble() ?? 0;
    final type = loan['type'] as String? ?? 'personal';
    final label = _loanTypeLabels[type] ?? type;
    final balance = (loan['current_balance'] as num?)?.toDouble() ?? 0;
    final nextDate = loan['next_payment_date'] as String?;
    final nextAmount = (loan['next_payment_amount'] as num?)?.toDouble() ?? 0;
    final rate = (loan['interest_rate'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTextStyles.titleMedium),
                Text('${rate.toStringAsFixed(2)}%',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              (loan['bank'] as Map?)?['name'] as String? ?? '',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kalan Bakiye', style: AppTextStyles.bodySmall),
                Text(AppFormatters.currency(balance),
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              backgroundColor: AppColors.borderLight,
              color: AppColors.success,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            if (nextDate != null)
              Text(
                'Sonraki ödeme: ${AppFormatters.dateFromIso(nextDate)} · ${AppFormatters.currency(nextAmount)}',
                style: AppTextStyles.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
