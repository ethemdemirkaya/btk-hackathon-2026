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

class _Insight {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? actionLink;
  final String importance;
  final DateTime createdAt;

  const _Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.actionLink,
    required this.importance,
    required this.createdAt,
  });

  factory _Insight.fromJson(Map<String, dynamic> j) => _Insight(
        id: j['id'] as int,
        type: j['type'] as String? ?? 'info',
        title: j['title'] as String,
        body: j['body'] as String,
        actionLink: j['action_link'] as String?,
        importance: j['importance'] as String? ?? 'low',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

final _insightsProvider =
    FutureProvider.autoDispose<List<_Insight>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.agentInsights);
  final items = (res.data as Map<String, dynamic>)['insights'] as List;
  return items.map((e) => _Insight.fromJson(e as Map<String, dynamic>)).toList()
    ..sort((a, b) {
      const order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
      return (order[a.importance] ?? 4).compareTo(order[b.importance] ?? 4);
    });
});

const _importanceLabels = {
  'critical': 'Kritik',
  'high': 'Yüksek',
  'medium': 'Orta',
  'low': 'Düşük',
};

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  final _dismissed = <int>{};

  Future<void> _dismiss(int id) async {
    setState(() => _dismissed.add(id));
    try {
      await DioClient.instance.patch(ApiEndpoints.agentInsightDismiss(id));
    } catch (_) {
      if (mounted) setState(() => _dismissed.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_insightsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                  Expanded(
                    child: Text('AI Öngörüleri',
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: AppColors.text1Dark)),
                  ),
                  GestureDetector(
                    onTap: () => ref.invalidate(_insightsProvider),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: const Icon(Icons.refresh,
                          size: 16, color: AppColors.text2Dark),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                ],
              ),
            ),

            // Body
            Expanded(
              child: async.when(
                loading: () => const SkeletonListView(),
                error: (e, __) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(_insightsProvider),
                ),
                data: (items) {
                  final visible =
                      items.where((i) => !_dismissed.contains(i.id)).toList();
                  if (visible.isEmpty) {
                    return const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'Harika!',
                      subtitle: 'Şu an gösterilecek öngörü yok.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: visible.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InsightCard(
                        insight: visible[i],
                        onDismiss: () => _dismiss(visible[i].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final _Insight insight;
  final VoidCallback onDismiss;
  const _InsightCard({required this.insight, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHint(insight.type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconForType(insight.type), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(insight.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _importanceLabels[insight.importance] ??
                                insight.importance,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Icon(Icons.close,
                              size: 16, color: AppColors.text3Dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.dateShort(insight.createdAt),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text3Dark, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight.body,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.text2Dark, height: 1.5)),
          if (insight.actionLink != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.push(insight.actionLink!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Detaylı İncele',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: color, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 12, color: color),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'success':
        return Icons.check_circle_outline;
      case 'tip':
        return Icons.lightbulb_outline;
      case 'alert':
        return Icons.notification_important_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
