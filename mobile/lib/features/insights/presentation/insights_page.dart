import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _positive   = Color(0xFF0DD9A0);
const _negative   = Color(0xFFFF4D6D);
const _warning    = Color(0xFFF59E0B);

Color _colorFromHint(String hint) {
  switch (hint) {
    case 'danger':
      return _negative;
    case 'warning':
      return _warning;
    case 'info':
      return const Color(0xFF6FB1FC);
    case 'success':
      return _positive;
    case 'primary':
      return _accent;
    default:
      return _text3;
  }
}

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
  Timer? _autoRefreshTimer;
  DateTime _lastFetched = DateTime.now();
  // Drives the "X minutes ago" display without rebuilding the whole tree
  Timer? _tickTimer;
  int _minutesSinceRefresh = 0;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 5 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        ref.invalidate(_insightsProvider);
        setState(() {
          _lastFetched = DateTime.now();
          _minutesSinceRefresh = 0;
        });
      }
    });
    // Update "X minutes ago" label every minute
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _minutesSinceRefresh =
              DateTime.now().difference(_lastFetched).inMinutes;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _manualRefresh() {
    ref.invalidate(_insightsProvider);
    setState(() {
      _lastFetched = DateTime.now();
      _minutesSinceRefresh = 0;
    });
  }

  Future<void> _dismiss(int id) async {
    setState(() => _dismissed.add(id));
    try {
      await DioClient.instance
          .patch(ApiEndpoints.agentInsightDismiss(id));
    } catch (_) {
      if (mounted) setState(() => _dismissed.remove(id));
    }
  }

  String get _lastUpdatedLabel {
    if (_minutesSinceRefresh == 0) return 'Az önce güncellendi';
    if (_minutesSinceRefresh == 1) return '1 dakika önce';
    return '$_minutesSinceRefresh dakika önce';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_insightsProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
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
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Icon(Icons.menu,
                          size: 18, color: _text2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Öngörüleri',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _text1)),
                        async.when(
                          data: (items) {
                            final visible = items
                                .where((i) =>
                                    !_dismissed.contains(i.id))
                                .length;
                            return Text(
                                '$visible aktif öngörü · $_lastUpdatedLabel',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: _text3));
                          },
                          loading: () => Text(
                              'Yükleniyor...',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _text3)),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _manualRefresh,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Icon(Icons.refresh,
                          size: 17, color: _text2),
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
                  onRetry: _manualRefresh,
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
    final typeColor = _colorFromHint(insight.type);
    final impColor =
        _importanceColors[insight.importance] ?? typeColor;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
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
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _text3),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: _text3),
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
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _text1)),
                      const SizedBox(height: 6),
                      Text(insight.body,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _text2,
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
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor)),
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
