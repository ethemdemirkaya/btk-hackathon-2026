import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _inflationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.inflation);
  return res.data as Map<String, dynamic>;
});

const _categoryNames = {
  'gida': 'Gıda & İçecek',
  'ulasim': 'Ulaşım',
  'konut': 'Konut & Kira',
  'giyim': 'Giyim & Ayakkabı',
  'saglik': 'Sağlık',
  'egitim': 'Eğitim',
  'eglence': 'Eğlence',
  'haberlesme': 'Haberleşme',
  'restoranlar': 'Restoran & Otel',
  'mobilya': 'Mobilya & Ev',
  'alkolsuz-icecekler': 'İçecekler',
  'genel': 'Genel',
};

const _categoryIcons = {
  'gida': Icons.restaurant_outlined,
  'ulasim': Icons.directions_car_outlined,
  'konut': Icons.home_outlined,
  'giyim': Icons.checkroom_outlined,
  'saglik': Icons.local_hospital_outlined,
  'egitim': Icons.school_outlined,
  'eglence': Icons.sports_esports_outlined,
  'haberlesme': Icons.phone_android_outlined,
  'restoranlar': Icons.hotel_outlined,
  'mobilya': Icons.chair_outlined,
  'alkolsuz-icecekler': Icons.local_cafe_outlined,
  'genel': Icons.category_outlined,
};

IconData _iconForSlug(String slug) =>
    _categoryIcons[slug] ?? Icons.category_outlined;

String _nameForSlug(String slug) => _categoryNames[slug] ?? slug;

Color _rateColor(double rate) {
  if (rate > 50) return AppColors.negative;
  if (rate > 35) return AppColors.warning;
  return AppColors.positive;
}

class InflationPage extends ConsumerWidget {
  const InflationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_inflationProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: async.when(
          loading: () => const _LoadingSkeleton(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_inflationProvider),
          ),
          data: (data) {
            final personal = (data['personal_rate'] as num?)?.toDouble();
            final tufe = (data['tufe_rate'] as num?)?.toDouble() ?? 0;
            final diff = (data['diff'] as num?)?.toDouble() ?? 0;
            final totalSpending =
                (data['total_spending'] as num?)?.toDouble() ?? 0;
            final period = data['period'] as String? ?? '';
            final breakdown =
                (data['breakdown'] as List?)?.cast<Map<String, dynamic>>() ??
                    [];

            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.bg2,
              onRefresh: () async => ref.invalidate(_inflationProvider),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _Header(period: period),
                  if (personal == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: EmptyState(
                        icon: Icons.show_chart,
                        title: 'Verileriniz henüz analiz edilmedi',
                        subtitle:
                            'Kişisel enflasyon hesabı için yeterli işlem geçmişi bulunamadı.',
                      ),
                    )
                  else ...[
                    _HeroCard(personal: personal, tufe: tufe, diff: diff),
                    if (period.isNotEmpty) _PeriodChip(period: period),
                    _ComparisonRow(personal: personal, tufe: tufe, diff: diff),
                    if (breakdown.isNotEmpty) ...[
                      _SectionLabel(label: 'Harcama Kategorileri'),
                      _BreakdownList(
                          items: breakdown, totalSpending: totalSpending),
                      _TopImpactCard(items: breakdown),
                    ],
                    _AiInsightCard(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: const [
        SkeletonCard(height: 56),
        SkeletonCard(height: 160),
        SkeletonCard(height: 40),
        SkeletonCard(height: 100),
        SkeletonCard(height: 280),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String period;
  const _Header({required this.period});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => shellScaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bg2,
                border: Border.all(color: AppColors.border2Dark),
              ),
              child: const Icon(Icons.menu, size: 18, color: AppColors.text2Dark),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Kişisel Enflasyon',
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.text1Dark),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double personal;
  final double tufe;
  final double diff;
  const _HeroCard(
      {required this.personal, required this.tufe, required this.diff});

  @override
  Widget build(BuildContext context) {
    final isAbove = diff > 0;
    final badgeColor = isAbove ? AppColors.negative : AppColors.positive;
    final badgeBg = badgeColor.withValues(alpha: 0.12);
    final absStr = diff.abs().toStringAsFixed(1);
    final badgeText =
        isAbove ? 'TÜFEden $absStr puan üstte' : 'TÜFEden $absStr puan altta';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bg1, AppColors.bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border2Dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kişisel Enflasyon Oranınız',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.text3Dark, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              '%${personal.toStringAsFixed(1)}',
              style: AppTextStyles.amountHero.copyWith(
                color: _rateColor(personal),
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAbove ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    badgeText,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: badgeColor, letterSpacing: 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String period;
  const _PeriodChip({required this.period});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  period,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.accent, letterSpacing: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final double personal;
  final double tufe;
  final double diff;
  const _ComparisonRow(
      {required this.personal, required this.tufe, required this.diff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _RateCard(
              label: 'Kişisel Oranım',
              rate: personal,
              color: _rateColor(personal),
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RateCard(
              label: 'TÜFE',
              rate: tufe,
              color: AppColors.info,
              icon: Icons.bar_chart_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final String label;
  final double rate;
  final Color color;
  final IconData icon;
  const _RateCard(
      {required this.label,
      required this.rate,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text3Dark, letterSpacing: 0)),
            ],
          ),
          const SizedBox(height: 8),
          Text('%${rate.toStringAsFixed(1)}',
              style: AppTextStyles.amountLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.text3Dark, letterSpacing: 1.2),
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double totalSpending;
  const _BreakdownList(
      {required this.items, required this.totalSpending});

  @override
  Widget build(BuildContext context) {
    final maxContrib = items
        .map((e) => (e['contribution'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final slug = cat['tuik_slug'] as String? ?? 'genel';
            final weight = (cat['weight_pct'] as num?)?.toDouble() ?? 0;
            final rate = (cat['tuik_rate'] as num?)?.toDouble() ?? 0;
            final contribution =
                (cat['contribution'] as num?)?.toDouble() ?? 0;
            final fillRatio =
                maxContrib > 0 ? (contribution / maxContrib) : 0.0;

            return Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                border: i > 0
                    ? const Border(
                        top: BorderSide(color: AppColors.border1Dark))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _rateColor(rate).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_iconForSlug(slug),
                            size: 16, color: _rateColor(rate)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _nameForSlug(slug),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.text1Dark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bg3,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '%${weight.toStringAsFixed(1)}',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.text3Dark, letterSpacing: 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '%${rate.toStringAsFixed(1)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _rateColor(rate),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fillRatio.toDouble(),
                      minHeight: 4,
                      backgroundColor:
                          AppColors.border1Dark.withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _rateColor(rate).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Katkı: ${contribution.toStringAsFixed(2)} puan',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.text3Dark, letterSpacing: 0),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopImpactCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _TopImpactCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) {
        final ca = (a['contribution'] as num?)?.toDouble() ?? 0;
        final cb = (b['contribution'] as num?)?.toDouble() ?? 0;
        return cb.compareTo(ca);
      });

    if (sorted.isEmpty) return const SizedBox.shrink();

    final top = sorted.first;
    final slug = top['tuik_slug'] as String? ?? 'genel';
    final contribution =
        (top['contribution'] as num?)?.toDouble() ?? 0;
    final rate = (top['tuik_rate'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForSlug(slug),
                  size: 20, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bütçende en çok etkilenen',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.text3Dark, letterSpacing: 0),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _nameForSlug(slug),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text1Dark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '%${rate.toStringAsFixed(1)} · ${contribution.toStringAsFixed(2)} puan katkı',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.warning, letterSpacing: 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => context.go('/chat'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.1),
                AppColors.bg2,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI analizi için Paranette AI\'ya sor',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.text1Dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Enflasyonunuzu nasıl düşürebilirsiniz?',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text3Dark, letterSpacing: 0),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
