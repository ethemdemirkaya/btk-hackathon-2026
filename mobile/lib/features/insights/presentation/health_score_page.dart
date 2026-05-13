import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _healthProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.dashboard);
  return res.data as Map<String, dynamic>;
});

const _components = [
  (
    id: 'debt',
    label: 'Borç oranı',
    weight: 30,
    hint: 'Kart kullanımın %30 sınırını aşmıyor — iyi durumda.',
    color: AppColors.accent,
  ),
  (
    id: 'savings',
    label: 'Birikim oranı',
    weight: 30,
    hint: 'Aylık gelirinin %16\'sını biriktiriyorsun, hedef %20.',
    color: Color(0xFFA78BFA),
  ),
  (
    id: 'emergency',
    label: 'Acil fon',
    weight: 25,
    hint: '3.8 aylık gideri karşılıyor, hedef 6 ay.',
    color: AppColors.warning,
  ),
  (
    id: 'consistency',
    label: 'Tutarlılık',
    weight: 15,
    hint: 'Son 6 ay bütçe disiplinin çok iyi.',
    color: AppColors.positive,
  ),
];

class HealthScorePage extends ConsumerWidget {
  const HealthScorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_healthProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_healthProvider),
          ),
          data: (data) {
            final healthScore =
                (data['health_score'] as num?)?.toInt() ?? 72;
            final scoreChange =
                (data['score_change'] as num?)?.toInt() ?? 2;

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Header
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
                            border:
                                Border.all(color: AppColors.border1Dark),
                          ),
                          child: const Icon(Icons.menu,
                              size: 16, color: AppColors.text2Dark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Finansal Sağlık',
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: AppColors.text1Dark)),
                    ],
                  ),
                ),

                // Hero ring
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      _ScoreRing(value: healthScore.toDouble()),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.positive
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_upward,
                                    size: 11, color: AppColors.positive),
                                const SizedBox(width: 2),
                                Text('+$scoreChange',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.positive,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('son 30 gün',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.text3Dark)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trend sparkline
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bg1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border1Dark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Son 12 ay',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.text3Dark)),
                            Text('aralık 58 → mayıs 72',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.text3Dark)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _Sparkline(
                          data: const [
                            58, 62, 64, 66, 64, 67, 68, 70, 68, 71, 70, 72
                          ],
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),

                // Components
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('Bileşenler',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.text3Dark)),
                      ),
                      ..._components.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ComponentCard(
                              label: c.label,
                              weight: c.weight,
                              value: _componentValue(
                                  healthScore, c.id),
                              hint: c.hint,
                              color: c.color,
                            ),
                          )),
                    ],
                  ),
                ),

                // CTAs
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/chat'),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label:
                              const Text('Skorumu nasıl yükseltirim?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/simulator'),
                          icon: const Icon(Icons.science_outlined,
                              size: 16),
                          label: const Text('Simülatörde projeksiyon yap'),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh,
                          size: 12, color: AppColors.text3Dark),
                      const SizedBox(width: 4),
                      Text(
                        'Skor 24 saatte bir otomatik yeniden hesaplanır',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.text3Dark, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _componentValue(int healthScore, String id) {
    switch (id) {
      case 'debt':
        return (healthScore * 1.08).clamp(0, 100).toDouble();
      case 'savings':
        return (healthScore * 0.90).clamp(0, 100).toDouble();
      case 'emergency':
        return (healthScore * 0.80).clamp(0, 100).toDouble();
      case 'consistency':
        return (healthScore * 1.28).clamp(0, 100).toDouble();
      default:
        return healthScore.toDouble();
    }
  }
}

// ── Score Ring ───────────────────────────────────────────────────────
class _ScoreRing extends StatelessWidget {
  final double value;
  const _ScoreRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _RingPainter(value: value, stroke: 14),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.toStringAsFixed(0)}',
                style: AppTextStyles.amountHero.copyWith(
                    fontSize: 44,
                    color: AppColors.text1Dark,
                    letterSpacing: -0.03 * 44),
              ),
              Text('skor',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text3Dark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  const _RingPainter({required this.value, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    canvas.drawCircle(center, radius,
        Paint()
          ..color = AppColors.bg3
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);

    final fillColor = value < 50
        ? AppColors.negative
        : value < 70
            ? AppColors.warning
            : AppColors.accent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (value.clamp(0, 100) / 100) * 2 * math.pi,
      false,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ── Sparkline ────────────────────────────────────────────────────────
class _Sparkline extends StatelessWidget {
  final List<num> data;
  final double height;
  const _Sparkline({required this.data, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(data: data),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<num> data;
  const _SparklinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final minV = data.reduce(math.min).toDouble();
    final maxV = data.reduce(math.max).toDouble();
    final range = maxV - minV;

    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = range > 0
          ? size.height - (data[i].toDouble() - minV) / range * size.height
          : size.height / 2;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill
    canvas.drawPath(
        fillPath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill);

    // Line
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}

// ── Component Card ───────────────────────────────────────────────────
class _ComponentCard extends StatelessWidget {
  final String label;
  final int weight;
  final double value;
  final String hint;
  final Color color;
  const _ComponentCard({
    required this.label,
    required this.weight,
    required this.value,
    required this.hint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border1Dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Text('%$weight ağırlık',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.text3Dark)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(hint,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.text2Dark, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${value.toStringAsFixed(0)}',
                style: AppTextStyles.amountHero.copyWith(
                    fontSize: 22,
                    color: color,
                    letterSpacing: -0.02 * 22),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
