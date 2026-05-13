import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _subscriptionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.subscriptions);
  return res.data as Map<String, dynamic>;
});

const _cycleLabels = {
  'weekly': 'Haftalık',
  'monthly': 'Aylık',
  'quarterly': '3 Aylık',
  'yearly': 'Yıllık',
};

// Brand colors for subscription logos
const _subColors = [
  Color(0xFFE50914), // Netflix red
  Color(0xFF1DB954), // Spotify green
  Color(0xFF0066CC), // Apple blue
  Color(0xFFFF6900), // Amazon
  Color(0xFF5865F2), // Discord purple
  Color(0xFF00D4FF), // cyan
  Color(0xFFA78BFA), // violet
  Color(0xFFFFC857), // amber
];

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_subscriptionsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentText,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: const Icon(Icons.menu,
                          size: 16, color: AppColors.text2Dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Abonelikler',
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: AppColors.text1Dark)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.bg2,
          onRefresh: () async => ref.invalidate(_subscriptionsProvider),
          child: async.when(
            loading: () => const SkeletonListView(),
            error: (e, __) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(_subscriptionsProvider),
            ),
            data: (data) {
              final subs = (data['subscriptions'] as List? ?? [])
                  .cast<Map<String, dynamic>>();
              final candidates = (data['candidates'] as List? ?? [])
                  .cast<Map<String, dynamic>>();
              final totalMonthly =
                  (data['total_monthly'] as num?)?.toDouble() ?? 0;

              if (subs.isEmpty && candidates.isEmpty) {
                return const EmptyState(
                  icon: Icons.subscriptions,
                  title: 'Abonelik bulunamadı',
                  subtitle:
                      'AI, işlemlerinizden abonelikleri otomatik tespit eder.',
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Hero header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Abonelikler',
                            style: AppTextStyles.headlineLarge
                                .copyWith(color: AppColors.text1Dark)),
                        const SizedBox(height: 4),
                        Text('Aylık toplam',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.text3Dark,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.08 * 11)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.currencyCompact(totalMonthly),
                              style: AppTextStyles.amountHero.copyWith(
                                  fontSize: 36,
                                  color: AppColors.text1Dark,
                                  letterSpacing: -0.03 * 36),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('₺',
                                  style: AppTextStyles.headlineMedium
                                      .copyWith(color: AppColors.text2Dark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yıllık ${AppFormatters.currencyCompact(totalMonthly * 12)} ₺ · ${subs.length} aktif abonelik',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.text3Dark),
                        ),
                      ],
                    ),
                  ),
                  // Active subscriptions
                  if (subs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text('Aktif Abonelikler',
                          style: AppTextStyles.headlineSmall),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: subs
                            .asMap()
                            .entries
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _SubCard(
                                      sub: e.value,
                                      colorIndex: e.key),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                  // Suggested subscriptions
                  if (candidates.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Text('Önerilen Abonelikler',
                          style: AppTextStyles.headlineSmall),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: candidates
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _CandidateCard(candidate: c),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
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

class _SubCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final int colorIndex;
  const _SubCard({required this.sub, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final name = sub['name'] as String? ?? 'S';
    final amount =
        (sub['monthly_equivalent'] as num?)?.toDouble() ?? 0;
    final cycle = sub['billing_cycle'] as String? ?? 'monthly';
    final aiDetected = sub['auto_detected'] as bool? ?? false;
    final nextBilling = sub['next_billing_date'] as String?;

    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final color = _subColors[colorIndex % _subColors.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border1Dark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo/initials
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name,
                            style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600)),
                        if (aiDetected) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.auto_awesome,
                              size: 12, color: AppColors.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_cycleLabels[cycle] ?? cycle}${nextBilling != null ? ' · sonraki: ${AppFormatters.dateShort(DateTime.parse(nextBilling))}' : ''}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text3Dark),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.currencyCompact(amount),
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '/ay',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.text3Dark),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SubAction(
                  icon: Icons.local_offer_outlined, label: 'İndirim talep'),
              const SizedBox(width: 8),
              _SubAction(icon: Icons.cancel_outlined, label: 'İptal'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SubAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border1Dark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.text2Dark),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.text1Dark)),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final name = candidate['name'] as String? ?? '';
    final amount = (candidate['amount'] as num?)?.toDouble() ?? 0;
    final confidence = (candidate['confidence'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentDim.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  'Olasılık: %${(confidence * 100).toStringAsFixed(0)}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text3Dark),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.currencyCompact(amount),
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
