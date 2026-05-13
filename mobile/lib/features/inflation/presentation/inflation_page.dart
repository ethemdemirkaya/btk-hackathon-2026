import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _inflationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.inflation);
  return res.data as Map<String, dynamic>;
});

class InflationPage extends ConsumerWidget {
  const InflationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_inflationProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_inflationProvider),
          ),
          data: (data) {
            final personal = (data['personal_rate'] as num?)?.toDouble();
            final tufe = (data['tufe_rate'] as num?)?.toDouble() ?? 0;
            final diff = (data['diff'] as num?)?.toDouble() ?? 0;
            final categories =
                (data['categories'] as List?)?.cast<Map<String, dynamic>>() ??
                    [];

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Header
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
                      Text('Kişisel Enflasyon',
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: AppColors.text1Dark)),
                    ],
                  ),
                ),

                if (personal == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: EmptyState(
                      icon: Icons.show_chart,
                      title: 'Yeterli veri yok',
                      subtitle:
                          'Kişisel enflasyonunuzu hesaplamak için yeterli işlem geçmişi bulunamadı.',
                    ),
                  )
                else ...[
                  // Rate cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _RateCard(
                            label: 'Kişisel',
                            rate: personal,
                            color: diff > 0
                                ? AppColors.negative
                                : AppColors.positive,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RateCard(
                            label: 'TÜFE',
                            rate: tufe,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Comparison banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (diff > 0 ? AppColors.negative : AppColors.positive)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (diff > 0
                                  ? AppColors.negative
                                  : AppColors.positive)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            diff > 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: diff > 0
                                ? AppColors.negative
                                : AppColors.positive,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              diff > 0
                                  ? 'Resmi enflasyondan %${diff.toStringAsFixed(1)} yüksek yaşıyorsunuz.'
                                  : 'Resmi enflasyonun %${diff.abs().toStringAsFixed(1)} altında yaşıyorsunuz.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.text2Dark, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category breakdown
                  if (categories.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Text('Kategori Bazlı',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.text3Dark)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bg1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border1Dark),
                        ),
                        child: Column(
                          children: categories.asMap().entries.map((entry) {
                            final i = entry.key;
                            final cat = entry.value;
                            final name =
                                cat['category'] as String? ?? 'Diğer';
                            final rate =
                                (cat['rate'] as num?)?.toDouble() ?? 0;
                            final isHigh = rate > tufe;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: i > 0
                                    ? const Border(
                                        top: BorderSide(
                                            color: AppColors.border1Dark))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(name,
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                                fontWeight: FontWeight.w500)),
                                  ),
                                  Text(
                                    '%${rate.toStringAsFixed(1)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isHigh
                                          ? AppColors.negative
                                          : AppColors.positive,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final String label;
  final double rate;
  final Color color;
  const _RateCard(
      {required this.label, required this.rate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.text3Dark)),
          const SizedBox(height: 6),
          Text('%${rate.toStringAsFixed(1)}',
              style: AppTextStyles.amountMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
