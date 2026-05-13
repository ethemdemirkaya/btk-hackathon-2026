import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _loansProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.loans);
  return res.data as Map<String, dynamic>;
});

const _loanTypeMap = {
  'personal': 'İhtiyaç',
  'mortgage': 'Konut',
  'vehicle': 'Taşıt',
  'commercial': 'Ticari',
};

IconData _iconForType(String type) {
  switch (type) {
    case 'mortgage':
      return Icons.home_outlined;
    case 'vehicle':
      return Icons.directions_car_outlined;
    case 'commercial':
      return Icons.description_outlined;
    default:
      return Icons.shopping_bag_outlined;
  }
}

class LoansPage extends ConsumerWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_loansProvider);

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.bg2,
          onRefresh: () async => ref.invalidate(_loansProvider),
          child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_loansProvider),
          ),
          data: (data) {
            final loans = (data['loans'] as List? ?? [])
                .cast<Map<String, dynamic>>();
            final totalBalance =
                (data['total_balance'] as num?)?.toDouble() ?? 0;
            final monthlyTotal = loans.fold<double>(
              0,
              (s, l) =>
                  s + ((l['next_payment_amount'] as num?)?.toDouble() ?? 0),
            );

            if (loans.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              shellScaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bg2,
                              border: Border.all(color: AppColors.border1Dark),
                            ),
                            child: const Icon(Icons.menu,
                                size: 18, color: AppColors.text2Dark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Krediler',
                            style: AppTextStyles.headlineMedium
                                .copyWith(color: AppColors.text1Dark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  EmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'Kredi bulunamadı',
                    subtitle:
                        'Konut, taşıt veya ihtiyaç kredilerinizi buradan takip edin.',
                    ctaLabel: '+ Kredi Ekle',
                    onCta: () {},
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            shellScaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bg2,
                            border: Border.all(color: AppColors.border1Dark),
                          ),
                          child: const Icon(Icons.menu,
                              size: 18, color: AppColors.text2Dark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Krediler',
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: AppColors.text1Dark)),
                    ],
                  ),
                ),

                // Summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Toplam kalan bakiye',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.text3Dark)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: AppFormatters.currencyCompact(totalBalance)
                                  .replaceAll(' ₺', ''),
                              style: AppTextStyles.amountHero.copyWith(
                                  fontSize: 36,
                                  color: AppColors.text1Dark,
                                  letterSpacing: -0.03 * 36),
                            ),
                            TextSpan(
                              text: ' ₺',
                              style: AppTextStyles.amountHero.copyWith(
                                  fontSize: 22,
                                  color: AppColors.text2Dark,
                                  letterSpacing: 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${loans.length} aktif kredi · Aylık ${AppFormatters.currencyCompact(monthlyTotal)} taksit',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.text3Dark),
                      ),
                    ],
                  ),
                ),

                // Loan Cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      ...loans.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LoanCard(loan: l),
                          )),

                      // Add button (dashed)
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.border2Dark,
                                width: 1.5,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add,
                                  size: 18, color: AppColors.text3Dark),
                              const SizedBox(width: 8),
                              Text('Yeni kredi ekle',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.text3Dark,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final type = loan['type'] as String? ?? 'personal';
    final label = _loanTypeMap[type] ?? type;
    final icon = _iconForType(type);
    final balance = (loan['current_balance'] as num?)?.toDouble() ?? 0;
    final rate = (loan['interest_rate'] as num?)?.toDouble() ?? 0;
    final bankName = (loan['bank'] as Map?)?['name'] as String? ??
        loan['bank_name'] as String? ?? '';
    final remaining = (loan['remaining_installments'] as num?)?.toInt() ?? 0;
    final total = (loan['total_installments'] as num?)?.toInt() ?? 142;
    final nextDate = loan['next_payment_date'] as String?;
    final nextAmount =
        (loan['next_payment_amount'] as num?)?.toDouble() ?? 0;

    final paidCount = (total - remaining).clamp(0, total);
    final progress = total > 0 ? paidCount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border1Dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + type + bank | balance + remaining
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border1Dark),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border1Dark),
                          ),
                          child: Text('%${rate.toStringAsFixed(1)}',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.text3Dark,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(bankName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.text3Dark, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(balance / 1000).toStringAsFixed(0)}k ₺',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: 2),
                  Text('$remaining taksit kaldı',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text3Dark, fontSize: 11)),
                ],
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 4,
            ),
          ),

          // Next payment box
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SONRAKI TAKSİT',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.text3Dark,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.06 * 10)),
                    const SizedBox(height: 2),
                    Text(
                      nextDate != null
                          ? AppFormatters.dateFromIso(nextDate)
                          : '—',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  AppFormatters.currencyCompact(nextAmount),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),

          // Action buttons
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionBtn(
                label: 'Simüle et',
                icon: Icons.science_outlined,
                onTap: () => context.push('/simulator'),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Müzakere',
                icon: Icons.mail_outline,
                onTap: () => context.push('/negotiation'),
                ghost: true,
              ),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.text3Dark),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool ghost;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : AppColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: ghost ? AppColors.border1Dark : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: ghost ? AppColors.text3Dark : AppColors.text2Dark),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                    color: ghost ? AppColors.text3Dark : AppColors.text2Dark,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
