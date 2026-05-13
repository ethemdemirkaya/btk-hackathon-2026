import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
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
  final res =
      await DioClient.instance.get(ApiEndpoints.agentInsights);
  final items = (res.data as Map<String, dynamic>)['insights'] as List;
  return items.map((e) => _Insight.fromJson(e as Map<String, dynamic>)).toList()
    ..sort((a, b) {
      const order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
      return (order[a.importance] ?? 4).compareTo(order[b.importance] ?? 4);
    });
});

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
      await DioClient.instance
          .patch(ApiEndpoints.agentInsightDismiss(id));
    } catch (_) {
      if (mounted) setState(() => _dismissed.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_insightsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Öngörüleri')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(_insightsProvider),
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.refresh(_insightsProvider),
          ),
          data: (items) {
            final visible = items.where((i) => !_dismissed.contains(i.id)).toList();
            if (visible.isEmpty) {
              return const EmptyState(
                icon: Icons.check_circle_outline,
                title: 'Harika!',
                subtitle: 'Şu an gösterilecek öngörü yok.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              itemBuilder: (_, i) => _InsightCard(
                insight: visible[i],
                onDismiss: () => _dismiss(visible[i].id),
              ),
            );
          },
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
    final bgColor = AppColors.fromHintLight(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(insight.title,
                    style: AppTextStyles.titleMedium.copyWith(color: color)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
                color: color,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(insight.body, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            AppFormatters.dateShort(insight.createdAt),
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (insight.actionLink != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push(insight.actionLink!),
              style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Detaylı İncele →'),
            ),
          ],
        ],
      ),
    );
  }
}
