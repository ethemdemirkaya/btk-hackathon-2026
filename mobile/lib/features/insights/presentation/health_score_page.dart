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
    FutureProvider.autoDispose<_HealthData>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.healthScore);
  return _HealthData.fromJson(res.data as Map<String, dynamic>);
});

class _HealthData {
  final int score;
  final int debtRatio;
  final int savingsRate;
  final int emergencyFund;
  final int consistency;
  final List<int> trend;
  final DateTime? calculatedAt;

  const _HealthData({
    required this.score,
    required this.debtRatio,
    required this.savingsRate,
    required this.emergencyFund,
    required this.consistency,
    required this.trend,
    required this.calculatedAt,
  });

  factory _HealthData.fromJson(Map<String, dynamic> j) {
    final comps = (j['components'] as Map<String, dynamic>?) ?? const {};
    final trendRaw = (j['trend'] as List?) ?? const [];
    final trend = trendRaw
        .whereType<Map>()
        .map((m) => (m['score'] as num?)?.toInt() ?? 0)
        .toList();
    return _HealthData(
      score: (j['score'] as num?)?.toInt() ?? 0,
      debtRatio: (comps['debt_ratio'] as num?)?.toInt() ?? 0,
      savingsRate: (comps['savings_rate'] as num?)?.toInt() ?? 0,
      emergencyFund: (comps['emergency_fund'] as num?)?.toInt() ?? 0,
      consistency: (comps['expense_consistency'] as num?)?.toInt() ?? 0,
      trend: trend.isEmpty ? [] : trend,
      calculatedAt: DateTime.tryParse(j['calculated_at']?.toString() ?? ''),
    );
  }
}

class HealthScorePage extends ConsumerWidget {
  const HealthScorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_healthProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          backgroundColor: _cardBg,
          onRefresh: () async => ref.invalidate(_healthProvider),
          child: async.when(
            loading: () => const SkeletonListView(),
            error: (e, __) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(_healthProvider),
            ),
            data: (data) => _body(context, ref, data),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, _HealthData data) {
    // Compute trend delta (last vs first)
    final delta = data.trend.length >= 2
        ? data.trend.last - data.trend.first
        : 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ── Header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child:
                      const Icon(Icons.menu, size: 18, color: _text2),
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
                    Text(_calcLabel(data.calculatedAt),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: _text3)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref.invalidate(_healthProvider),
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

        // ── Gauge card ────────────────────────────────────────────────
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
                _ScoreGauge(value: data.score.toDouble()),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (delta != 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (delta > 0 ? _positive : _negative)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                delta > 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 12,
                                color: delta > 0 ? _positive : _negative),
                            const SizedBox(width: 3),
                            Text(
                              '${delta > 0 ? '+' : ''}$delta',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: delta > 0 ? _positive : _negative),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(_periodLabel(data.trend.length),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _text3)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Trend ─────────────────────────────────────────────────────
        if (data.trend.length >= 2)
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Skor geçmişi',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _text3)),
                      Text(
                        '${data.trend.first} → ${data.trend.last}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _text3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Sparkline(data: data.trend, height: 50),
                ],
              ),
            ),
          ),

        // ── Components ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text('Bileşenler',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _text3,
                        letterSpacing: 0.5)),
              ),
              _ComponentCard(
                label: 'Borç oranı',
                weight: 30,
                value: data.debtRatio.toDouble(),
                hint: _debtRatioHint(data.debtRatio),
                color: _accent,
              ),
              const SizedBox(height: 10),
              _ComponentCard(
                label: 'Birikim oranı',
                weight: 30,
                value: data.savingsRate.toDouble(),
                hint: _savingsHint(data.savingsRate),
                color: const Color(0xFFA78BFA),
              ),
              const SizedBox(height: 10),
              _ComponentCard(
                label: 'Acil fon',
                weight: 25,
                value: data.emergencyFund.toDouble(),
                hint: _emergencyHint(data.emergencyFund),
                color: _warning,
              ),
              const SizedBox(height: 10),
              _ComponentCard(
                label: 'Tutarlılık',
                weight: 15,
                value: data.consistency.toDouble(),
                hint: _consistencyHint(data.consistency),
                color: _positive,
              ),
            ],
          ),
        ),

        // ── CTAs ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Sohbet Et',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/simulator'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.science_outlined, size: 16),
                  label: const Text('Simülatör',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
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
              const Icon(Icons.bolt_outlined, size: 11, color: _text3),
              const SizedBox(width: 4),
              const Text(
                'Skor her sayfa açılışında yeniden hesaplanır',
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
  }

  String _calcLabel(DateTime? at) {
    if (at == null) return 'Az önce güncellendi';
    final mins = DateTime.now().difference(at).inMinutes;
    if (mins < 1) return 'Az önce güncellendi';
    if (mins < 60) return '$mins dakika önce';
    final hrs = mins ~/ 60;
    return '$hrs saat önce';
  }

  String _periodLabel(int n) {
    if (n <= 1) return 'Bu ay';
    if (n < 6) return 'Son $n ay';
    if (n < 12) return 'Son $n ay';
    return 'Son 12 ay';
  }

  String _debtRatioHint(int v) {
    if (v >= 85) return 'Borç oranınız çok düşük — finansal sağlığınız sağlam.';
    if (v >= 70) return 'Borç oranınız makul, kontrol altında.';
    if (v >= 50) return 'Borçlarınız gelirinize göre yüksek; ödemeyi hızlandırın.';
    return 'Borç oranı kritik seviyede — yeni borç almayın, ödeyin.';
  }

  String _savingsHint(int v) {
    if (v >= 90) return 'Gelirinizin %20+ kadarını biriktiriyorsunuz, harika.';
    if (v >= 60) return 'Birikim alışkanlığınız iyi; hedef gelirinizin %20\'si.';
    if (v >= 25) return 'Birikim oranınız düşük; sabit gider tasarrufu deneyin.';
    return 'Gelir-giderden negatif — harcamaları acilen gözden geçirin.';
  }

  String _emergencyHint(int v) {
    if (v >= 85) return 'Acil fonunuz 4+ aylık giderinizi karşılıyor.';
    if (v >= 55) return 'Acil fon 2-3 ay; hedef 6 ay.';
    if (v >= 35) return 'Acil fon yetersiz — 3 aylık gider tutarına çıkarın.';
    return 'Acil fon yok; ilk hedef 1 aylık gideri biriktirmek.';
  }

  String _consistencyHint(int v) {
    if (v >= 85) return 'Aylık harcamalarınız tutarlı, bütçe disiplini iyi.';
    if (v >= 55) return 'Harcamalarınızda hafif dalgalanma var.';
    return 'Aylar arası harcamada büyük fark var — düzenli bütçe yapın.';
  }
}

// ── Score Gauge ──────────────────────────────────────────────────────
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
                    height: 1.0),
              ),
              const SizedBox(height: 4),
              Text(_label(value),
                  style: const TextStyle(
                      fontSize: 12,
                      color: _text2,
                      fontWeight: FontWeight.w500)),
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

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _cardBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);

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
