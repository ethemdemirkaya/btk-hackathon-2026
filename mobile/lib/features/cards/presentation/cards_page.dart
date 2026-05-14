import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: 'Kartlarım', subtitle: 'Kredi kartı özeti'),
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
                onRefresh: () async =>
                    ref.invalidate(_cardsProvider),
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
                        (data['total_debt'] as num?)
                                ?.toDouble() ??
                            0;
                    final totalLimit =
                        (data['total_limit'] as num?)
                                ?.toDouble() ??
                            0;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 100),
                      children: [
                        // Hero summary
                        _SummaryCard(
                          debt: totalDebt,
                          limit: totalLimit,
                        ),
                        const SizedBox(height: 16),

                        // Physical card visuals
                        ...cards
                            .cast<Map<String, dynamic>>()
                            .asMap()
                            .entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 16),
                                  child: _PhysicalCard(
                                    card: entry.value,
                                    colorIndex: entry.key,
                                  ),
                                )),

                        // Add card button
                        _AddCardButton(),
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

// ── Standard Header ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              child:
                  const Icon(Icons.menu, size: 20, color: _text2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600).copyWith(
                      color: _text1,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400).copyWith(color: _text3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Summary Hero Card ─────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double debt;
  final double limit;
  const _SummaryCard({required this.debt, required this.limit});

  @override
  Widget build(BuildContext context) {
    final used = limit > 0 ? debt / limit * 100 : 0.0;
    final available = limit - debt;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Toplam borç',
              style:
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
          const SizedBox(height: 6),
          Text(
            '${AppFormatters.currencyCompact(debt)} ₺',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 32,
                color: _text1),
          ),
          const SizedBox(height: 4),
          Text(
            '${used.toStringAsFixed(0)}% limit kullanımı · ${AppFormatters.currencyCompact(available)} ₺ kullanılabilir',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text3),
          ),
        ],
      ),
    );
  }
}

// ── Physical Card Visual ──────────────────────────────────────────────
class _PhysicalCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final int colorIndex;

  static const _gradientPairs = [
    [Color(0xFF1B4FD8), Color(0xFF0F2F8A)],
    [Color(0xFF0F766E), Color(0xFF064E3B)],
    [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    [Color(0xFF9D174D), Color(0xFF6B0F36)],
    [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
  ];

  const _PhysicalCard(
      {required this.card, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final debt =
        (card['current_debt'] as num?)?.toDouble() ?? 0;
    final limit =
        (card['credit_limit'] as num?)?.toDouble() ?? 0;
    final pct = limit > 0 ? (debt / limit) : 0.0;
    final masked = card['masked_number'] as String? ??
        '**** **** **** ****';
    final holder = card['holder_name'] as String? ?? '';
    final bankName = card['bank_name'] as String? ??
        card['name'] as String? ??
        'PARANETTE';
    final expiry =
        '${card['expiry_month']}/${card['expiry_year']}';

    final colors = _gradientPairs[colorIndex % _gradientPairs.length];
    final usageColor = pct > 0.8 ? _negative : Colors.white;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: bank + chip icon
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bankName.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 2),
                    ),
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.credit_card,
                          size: 14, color: Colors.white70),
                    ),
                  ],
                ),
                const Spacer(),
                // Card number
                Text(
                  masked,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                // Debt/limit row
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    _CardStat(
                        label: 'Borç',
                        value: AppFormatters.currencyCompact(
                            debt)),
                    _CardStat(
                        label: 'Limit',
                        value: AppFormatters.currencyCompact(
                            limit),
                        alignEnd: true),
                  ],
                ),
                const SizedBox(height: 10),
                // Usage progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0, 1),
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.18),
                    valueColor:
                        AlwaysStoppedAnimation(usageColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),
                // Holder + expiry
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    if (holder.isNotEmpty)
                      Text(holder.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              letterSpacing: 0.5))
                    else
                      const SizedBox.shrink(),
                    Text(expiry,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;
  const _CardStat(
      {required this.label,
      required this.value,
      this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Add Card Button ──────────────────────────────────────────────────
class _AddCardButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _cardBorder,
            style: BorderStyle.solid,
            width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder, width: 1.5),
            ),
            child: const Icon(Icons.add,
                size: 20, color: _text3),
          ),
          const SizedBox(width: 12),
          const Text('Kart ekle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text3)),
        ],
      ),
    );
  }
}
