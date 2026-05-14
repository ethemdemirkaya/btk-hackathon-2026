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

  factory _Insight.fromJson(Map<String, dynamic> j) {
    final imp = j['importance'];
    final String importanceStr;
    if (imp is String) {
      importanceStr = imp;
    } else if (imp is int) {
      if (imp >= 8) { importanceStr = 'critical'; }
      else if (imp >= 6) { importanceStr = 'high'; }
      else if (imp >= 4) { importanceStr = 'medium'; }
      else { importanceStr = 'low'; }
    } else {
      importanceStr = 'low';
    }
    return _Insight(
      id: (j['id'] as num).toInt(),
      type: j['type']?.toString() ?? 'info',
      title: j['title']?.toString() ?? '',
      body: j['body']?.toString() ?? '',
      actionLink: j['action_link'] as String?,
      importance: importanceStr,
      createdAt: DateTime.tryParse(
              j['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

final _insightsProvider =
    FutureProvider.autoDispose<List<_Insight>>((ref) async {
  final res =
      await DioClient.instance.get(ApiEndpoints.agentInsights);
  final data = res.data;
  final Map<String, dynamic> body =
      data is Map<String, dynamic> ? data : <String, dynamic>{};
  final raw = body['insights'];
  final items = raw is List ? raw : <dynamic>[];
  return items
      .whereType<Map<String, dynamic>>()
      .map(_Insight.fromJson)
      .toList()
    ..sort((a, b) {
      const order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
      return (order[a.importance] ?? 4)
          .compareTo(order[b.importance] ?? 4);
    });
});

const _importanceLabels = {
  'critical': 'KRİTİK',
  'high': 'YÜKSEK',
  'medium': 'ORTA',
  'low': 'DÜŞÜK',
};

const _importanceColors = {
  'critical': Color(0xFFFF4D6D),
  'high': Color(0xFFF59E0B),
  'medium': Color(0xFF00D4FF),
  'low': Color(0xFF0DD9A0),
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
      backgroundColor: const Color(0xFF060D18),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1A2940)),
                      ),
                      child: const Icon(Icons.menu,
                          size: 18, color: Color(0xFF8BA4BC)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Öngörüleri',
                            style: AppTextStyles.headlineMedium
                                .copyWith(
                                    color: const Color(0xFFE8F4FF))),
                        async.when(
                          data: (items) {
                            final visible = items
                                .where((i) =>
                                    !_dismissed.contains(i.id))
                                .length;
                            return Text('$visible aktif öngörü',
                                style: AppTextStyles.bodySmall
                                    .copyWith(
                                        color: const Color(
                                            0xFF4A6478)));
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.invalidate(_insightsProvider),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1A2940)),
                      ),
                      child: const Icon(Icons.refresh,
                          size: 17, color: Color(0xFF8BA4BC)),
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
                  onRetry: () =>
                      ref.invalidate(_insightsProvider),
                ),
                data: (items) {
                  final visible = items
                      .where((i) => !_dismissed.contains(i.id))
                      .toList();
                  if (visible.isEmpty) {
                    return const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'Harika!',
                      subtitle: 'Şu an gösterilecek öngörü yok.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 24),
                    itemCount: visible.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InsightCard(
                        insight: visible[i],
                        onDismiss: () =>
                            _dismiss(visible[i].id),
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
  const _InsightCard(
      {required this.insight, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.fromHint(insight.type);
    final impColor =
        _importanceColors[insight.importance] ?? typeColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: impColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with importance badge and dismiss
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
            child: Row(
              children: [
                // Importance badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: impColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _importanceLabels[insight.importance] ??
                        insight.importance.toUpperCase(),
                    style: TextStyle(
                        color: impColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.dateShort(insight.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFF4A6478),
                      fontSize: 10),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF060D18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF1A2940)),
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Color(0xFF4A6478)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconForType(insight.type),
                      color: typeColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFFE8F4FF),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(insight.body,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF8BA4BC),
                              height: 1.5)),
                      if (insight.actionLink != null) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () =>
                              context.push(insight.actionLink!),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Detaylı İncele',
                                  style:
                                      AppTextStyles.labelSmall
                                          .copyWith(
                                              color: typeColor,
                                              fontWeight:
                                                  FontWeight.w600)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward,
                                  size: 12, color: typeColor),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
