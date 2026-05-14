import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
const _positive   = Color(0xFF0DD9A0); // ignore: unused_element
const _negative   = Color(0xFFFF4D6D);
const _warning    = Color(0xFFF59E0B); // ignore: unused_element

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

// ── Bank brand helpers ────────────────────────────────────────────────
const _bankAssets = <String, String>{
  'garanti':   'assets/banks/garanti.svg',
  'bbva':      'assets/banks/garanti.svg',
  'isbank':    'assets/banks/isbank.svg',
  'iş':        'assets/banks/isbank.svg',
  'ziraat':    'assets/banks/ziraat.svg',
  'akbank':    'assets/banks/akbank.svg',
  'vakif':     'assets/banks/vakifbank.svg',
  'vakıf':     'assets/banks/vakifbank.svg',
  'yapikredi': 'assets/banks/yapikredi.svg',
  'yapı':      'assets/banks/yapikredi.svg',
  'deniz':     'assets/banks/denizbank.svg',
  'halk':      'assets/banks/halkbank.svg',
};

const _bankGradients = <String, List<Color>>{
  'garanti':   [Color(0xFF009900), Color(0xFF006600)],
  'bbva':      [Color(0xFF009900), Color(0xFF006600)],
  'isbank':    [Color(0xFF003087), Color(0xFF001a4d)],
  'iş':        [Color(0xFF003087), Color(0xFF001a4d)],
  'ziraat':    [Color(0xFFCC0000), Color(0xFF8B0000)],
  'akbank':    [Color(0xFFE8000D), Color(0xFFA0000A)],
  'vakif':     [Color(0xFFD4890A), Color(0xFF8B5E00)],
  'vakıf':     [Color(0xFFD4890A), Color(0xFF8B5E00)],
  'yapikredi': [Color(0xFF003366), Color(0xFF001A33)],
  'yapı':      [Color(0xFF003366), Color(0xFF001A33)],
  'deniz':     [Color(0xFF005BAA), Color(0xFF003875)],
  'halk':      [Color(0xFF00703C), Color(0xFF004D28)],
};

String? _svgForSlug(String? slug) {
  if (slug == null) return null;
  final lower = slug.toLowerCase();
  for (final key in _bankAssets.keys) {
    if (lower.contains(key)) return _bankAssets[key];
  }
  return null;
}

List<Color> _gradientForSlug(String? slug, int fallbackIndex) {
  const fallbacks = [
    [Color(0xFF1B4FD8), Color(0xFF0F2F8A)],
    [Color(0xFF0F766E), Color(0xFF064E3B)],
    [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    [Color(0xFF9D174D), Color(0xFF6B0F36)],
  ];
  if (slug == null) return fallbacks[fallbackIndex % fallbacks.length];
  final lower = slug.toLowerCase();
  for (final key in _bankGradients.keys) {
    if (lower.contains(key)) return _bankGradients[key]!;
  }
  return fallbacks[fallbackIndex % fallbacks.length];
}

// ── Bank Logo Widget ──────────────────────────────────────────────────
class _BankLogo extends StatelessWidget {
  final String? slug;
  final String? bankName;
  final double height;
  const _BankLogo({this.slug, this.bankName, this.height = 22});

  @override
  Widget build(BuildContext context) {
    final asset = _svgForSlug(slug);
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        height: height,
        colorFilter: const ColorFilter.matrix([
          // Invert to white (for dark card backgrounds)
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0,  0, 1, 0,
        ]),
      );
    }
    // Fallback: styled text
    return Text(
      (bankName ?? 'BANKA').toUpperCase(),
      style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: Colors.white70, letterSpacing: 1.5,
      ),
    );
  }
}

// ── Physical Card Visual ──────────────────────────────────────────────
class _PhysicalCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final int colorIndex;
  const _PhysicalCard({required this.card, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final debt     = (card['current_debt']  as num?)?.toDouble() ?? 0;
    final limit    = (card['credit_limit']  as num?)?.toDouble() ?? 0;
    final pct      = limit > 0 ? (debt / limit) : 0.0;
    final masked   = card['masked_number']  as String? ?? '**** **** **** ****';
    final holder   = card['holder_name']    as String? ?? '';
    final bankName = card['bank_name']      as String? ?? card['name'] as String? ?? 'PARANETTE';
    final bankSlug = card['bank_slug']      as String? ?? bankName;
    final isCredit = (card['type'] as String?) == 'credit';
    final month    = card['expiry_month']?.toString().padLeft(2, '0') ?? '??';
    final year     = card['expiry_year']?.toString() ?? '??';

    final colors     = _gradientForSlug(bankSlug, colorIndex);
    final usageColor = pct > 0.8 ? _negative : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.40),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle top-right
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Decorative circle bottom-left
          Positioned(
            bottom: -60, left: '20%'.isEmpty ? 60 : 60,
            child: Container(
              width: 200, height: 200,
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
                // ── Row 1: Bank logo + hologram ───────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BankLogo(slug: bankSlug, bankName: bankName, height: 22),
                    // Holographic circle (conic gradient-ish via multiple colors)
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(colors: [
                          Colors.pinkAccent.withValues(alpha: 0.55),
                          Colors.yellowAccent.withValues(alpha: 0.55),
                          Colors.cyanAccent.withValues(alpha: 0.55),
                          Colors.purpleAccent.withValues(alpha: 0.55),
                          Colors.blueAccent.withValues(alpha: 0.55),
                          Colors.pinkAccent.withValues(alpha: 0.55),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Row 2: Chip + card type badge ────────────────
                Row(
                  children: [
                    // EMV chip
                    Container(
                      width: 38, height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC9A227), Color(0xFFF5D066)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CustomPaint(painter: _ChipPainter()),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCredit ? 'KREDİ' : 'DEBİT',
                        style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Card number ───────────────────────────────────
                Text(
                  masked,
                  style: const TextStyle(
                    fontSize: 15, color: Colors.white,
                    letterSpacing: 3, fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 14),

                // ── Debt/limit + progress ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CardStat(label: 'Borç',  value: AppFormatters.currencyCompact(debt)),
                    _CardStat(label: 'Limit', value: AppFormatters.currencyCompact(limit), alignEnd: true),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0, 1),
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation(usageColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Holder + expiry ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      holder.isNotEmpty ? holder.toUpperCase() : '',
                      style: const TextStyle(fontSize: 9, color: Colors.white60, letterSpacing: 0.8),
                    ),
                    Text(
                      '$month/$year',
                      style: const TextStyle(fontSize: 9, color: Colors.white60),
                    ),
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

// ── EMV Chip Painter ──────────────────────────────────────────────────
class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    // Vertical lines
    canvas.drawLine(Offset(size.width * 0.33, 2), Offset(size.width * 0.33, size.height - 2), paint);
    canvas.drawLine(Offset(size.width * 0.67, 2), Offset(size.width * 0.67, size.height - 2), paint);
    // Horizontal lines
    canvas.drawLine(Offset(2, size.height * 0.35), Offset(size.width - 2, size.height * 0.35), paint);
    canvas.drawLine(Offset(2, size.height * 0.65), Offset(size.width - 2, size.height * 0.65), paint);
  }
  @override
  bool shouldRepaint(_ChipPainter _) => false;
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
