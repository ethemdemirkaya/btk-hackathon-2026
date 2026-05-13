import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _inflationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.inflation);
  return res.data as Map<String, dynamic>;
});

class InflationPage extends ConsumerWidget {
  const InflationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_inflationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kişisel Enflasyon')),
      body: async.when(
        loading: () => const SkeletonListView(),
        error: (e, __) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(_inflationProvider),
        ),
        data: (data) {
          final personal = (data['personal_rate'] as num?)?.toDouble();
          final tufe = (data['tufe_rate'] as num?)?.toDouble() ?? 0;
          final diff = (data['diff'] as num?)?.toDouble() ?? 0;

          if (personal == null) {
            return const EmptyState(
              icon: Icons.show_chart,
              title: 'Yeterli veri yok',
              subtitle: 'Kişisel enflasyonunuzu hesaplamak için yeterli işlem geçmişi bulunamadı.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _RateCard(
                      label: 'Kişisel Enflasyon',
                      rate: personal,
                      color: diff > 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RateCard(
                      label: 'Resmi TÜFE',
                      rate: tufe,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (diff > 0 ? AppColors.danger : AppColors.success)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  diff > 0
                      ? 'Resmi enflasyondan %${diff.toStringAsFixed(1)} yüksek yaşıyorsunuz.'
                      : 'Resmi enflasyonun %${diff.abs().toStringAsFixed(1)} altında yaşıyorsunuz.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: color),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('%${rate.toStringAsFixed(1)}',
              style:
                  AppTextStyles.amountMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
