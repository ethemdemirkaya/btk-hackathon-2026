import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
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
    color: _accent,
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
    color: _warning,
  ),
  (
    id: 'consistency',
    label: 'Tutarlılık',
    weight: 15,
    hint: 'Son 6 ay bütçe disiplinin çok iyi.',
    color: _positive,
  ),
];

class HealthScorePage extends ConsumerWidget {
  const HealthScorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_healthProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
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
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                            const Text('Finansal Sağlık Skoru',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _text1)),
                            const Text('Durumunuzu görün',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: _text3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero gauge card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      children: [
                        _ScoreGauge(value: healthScore.toDouble()),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _positive
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_upward,
                                      size: 12,
                                      color: _positive),
                                  const SizedBox(width: 3),
                                  Text('+$scoreChange',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _positive)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('son 30 gün',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _text3)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Trend sparkline
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Son 12 ay',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _text3)),
                            const Text('aralık 58 → mayıs 72',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _text3)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Sparkline(
                          data: const [
                            58, 62, 64, 66, 64, 67, 68, 70, 68,
                            71, 70, 72
                          ],
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),

                // Components
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding:
                            EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('Bileşenler',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _text3,
                                letterSpacing: 0.5)),
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

                // CTA buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: const Color(0xFF051929),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.auto_awesome,
                              size: 16),
                          label: const Text('Sohbet Et',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/simulator'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: const BorderSide(
                                color: _cardBorder),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                          icon: const Icon(
                              Icons.science_outlined,
                              size: 16),
                          label: const Text('Simülatör',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
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
                          size: 11, color: _text3),
                      const SizedBox(width: 4),
                      const Text(
                        'Skor 24 saatte bir otomatik yeniden hesaplanır',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _text3),
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

// ── Score Gauge (180px custom paint arc) ─────────────────────────────
class _ScoreGauge extends StatelessWidget {
  final double value;
  const _ScoreGauge({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _GaugePainter(value: value),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: _text1,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _label(value),
                style: const TextStyle(
                    fontSize: 12,
                    color: _text2,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(double v) {
    if (v >= 80) return 'Mükemmel';
    if (v >= 60) return 'İyi';
    if (v >= 40) return 'Orta';
    return 'Zayıf';
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  const _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 14.0;
    final radius = (size.width - stroke) / 2;

    // Track
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _cardBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);

    // Gradient arc: red → yellow → green based on value
    final fillColor = value < 40
        ? _negative
        : value < 70
            ? _warning
            : _positive;

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
  bool shouldRepaint(_GaugePainter old) => old.value != value;
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
          ? size.height -
              (data[i].toDouble() - minV) / range * size.height
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

    canvas.drawPath(
        fillPath,
        Paint()
          ..color = _accent.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill);

    canvas.drawPath(
        path,
        Paint()
          ..color = _accent
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
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
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _text1)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _cardBorder,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('%$weight',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _text3)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(hint,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _text2,
                            height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              backgroundColor: color.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
