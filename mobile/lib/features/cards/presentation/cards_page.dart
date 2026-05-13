import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _cardsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.cards);
  return res.data as Map<String, dynamic>;
});

class CardsPage extends ConsumerWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_cardsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.bg2,
          onRefresh: () async => ref.invalidate(_cardsProvider),
          child: async.when(
            loading: () => const SkeletonListView(),
            error: (e, __) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(_cardsProvider),
            ),
            data: (data) {
              final cards = data['cards'] as List? ?? [];
              if (cards.isEmpty) {
                return const EmptyState(
                  icon: Icons.credit_card,
                  title: 'Henüz kart yok',
                  subtitle:
                      'Banka hesabınızı bağlayınca kartlarınız burada görünür.',
                );
              }
              final totalDebt =
                  (data['total_debt'] as num?)?.toDouble() ?? 0;
              final totalLimit =
                  (data['total_limit'] as num?)?.toDouble() ?? 0;
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // Header
                  _PageHeader(debt: totalDebt, limit: totalLimit),
                  // Card carousel
                  _CardCarousel(
                      cards: cards.cast<Map<String, dynamic>>()),
                  // Recent transactions section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Son kart işlemleri',
                            style: AppTextStyles.headlineSmall),
                        Text('Tümü',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.text2Dark)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Page header: total debt hero ────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final double debt;
  final double limit;
  const _PageHeader({required this.debt, required this.limit});

  @override
  Widget build(BuildContext context) {
    final used = limit > 0 ? debt / limit * 100 : 0.0;
    final available = limit - debt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toplam kart borcu',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.text3Dark,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08 * 11)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.currencyCompact(debt),
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
            '${used.toStringAsFixed(0)}% limit kullanımı · ${AppFormatters.currencyCompact(available)} ₺ kullanılabilir',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.text3Dark),
          ),
        ],
      ),
    );
  }
}

// ── Card carousel ────────────────────────────────────────────────────
class _CardCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  const _CardCarousel({required this.cards});

  static const _cardColors = [
    Color(0xFF1B4FD8),
    Color(0xFF0F766E),
    Color(0xFF7C3AED),
    Color(0xFF9D174D),
    Color(0xFF1D4ED8),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cards.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == cards.length) {
            // Add card button
            return _AddCardButton();
          }
          return _CardVisual(
              card: cards[i],
              color: _cardColors[i % _cardColors.length]);
        },
      ),
    );
  }
}

class _CardVisual extends StatelessWidget {
  final Map<String, dynamic> card;
  final Color color;
  const _CardVisual({required this.card, required this.color});

  @override
  Widget build(BuildContext context) {
    final debt = (card['current_debt'] as num?)?.toDouble() ?? 0;
    final limit = (card['credit_limit'] as num?)?.toDouble() ?? 0;
    final pct = limit > 0 ? (debt / limit) : 0.0;
    final masked = card['masked_number'] as String? ?? '**** **** **** ****';
    final holder = card['holder_name'] as String? ?? '';
    final expiry =
        '${card['expiry_month']}/${card['expiry_year']}';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Background circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PARANETTE',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                    const Icon(Icons.credit_card,
                        color: Colors.white70, size: 20),
                  ],
                ),
                const Spacer(),
                Text(masked,
                    style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Borç',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white60,
                                fontSize: 10)),
                        Text(
                            AppFormatters.currencyCompact(debt),
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Kalan limit',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white60,
                                fontSize: 10)),
                        Text(
                            AppFormatters.currencyCompact(
                                limit - debt),
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(holder.isNotEmpty ? holder.toUpperCase() : '',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 0.5)),
                    Text(expiry,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white70, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0, 1),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                        pct > 0.7
                            ? AppColors.negative
                            : Colors.white),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.border2Dark,
            style: BorderStyle.solid,
            width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border2Dark, width: 1.5),
            ),
            child: const Icon(Icons.add,
                size: 22, color: AppColors.text3Dark),
          ),
          const SizedBox(height: 10),
          Text('Kart ekle',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.text3Dark)),
        ],
      ),
    );
  }
}
