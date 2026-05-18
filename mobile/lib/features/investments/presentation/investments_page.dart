import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _investmentsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res =
      await DioClient.instance.get(ApiEndpoints.investments);
  return res.data as Map<String, dynamic>;
});

final _liveRatesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance
      .get(ApiEndpoints.investmentsLiveRates);
  return res.data as Map<String, dynamic>;
});

final _fxAlertCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.fxAlerts);
  final data = res.data as Map<String, dynamic>;
  return (data['alerts'] as List? ?? []).length;
});

const _assetTypes = [
  ('gold_gram', 'Gram Altın'),
  ('gold_quarter', 'Çeyrek Altın'),
  ('gold_republic', 'Cumhuriyet Altını'),
  ('usd', 'Dolar (USD)'),
  ('eur', 'Euro (EUR)'),
  ('gbp', 'Sterlin (GBP)'),
  ('btc', 'Bitcoin (BTC)'),
  ('eth', 'Ethereum (ETH)'),
  ('bist', 'BIST Hissesi'),
  ('fund', 'Yatırım Fonu'),
  ('mevduat', 'Vadeli Mevduat'),
  ('other', 'Diğer'),
];

String? _liveRateKey(String assetType) {
  switch (assetType) {
    case 'gold_gram':
    case 'gold_quarter':
    case 'gold_republic':
      return 'XAU';
    case 'usd':
      return 'USD';
    case 'eur':
      return 'EUR';
    case 'gbp':
      return 'GBP';
    case 'btc':
      return 'BTC';
    case 'eth':
      return 'ETH';
    default:
      return null;
  }
}

String _category(String assetType) {
  if (assetType.startsWith('gold')) return 'altın';
  if (assetType == 'usd' ||
      assetType == 'eur' ||
      assetType == 'gbp') {
    return 'döviz';
  }
  if (assetType == 'btc' || assetType == 'eth') return 'kripto';
  if (assetType == 'bist') return 'hisse';
  if (assetType == 'fund') return 'fon';
  return 'diğer';
}

const _typeStyles = {
  'altın': (color: Color(0xFFC99B5B), label: 'Altın'),
  'döviz': (color: Color(0xFF6FB1FC), label: 'Döviz'),
  'kripto': (color: Color(0xFFF472B6), label: 'Kripto'),
  'hisse': (color: Color(0xFF00D4FF), label: 'Hisse'),
  'fon': (color: Color(0xFFA78BFA), label: 'Fon'),
  'diğer': (color: Color(0xFF8BA4BC), label: 'Diğer'),
};

const _filterOptions = [
  'all',
  'altın',
  'döviz',
  'hisse',
  'kripto',
  'fon'
];
const _filterLabels = [
  'Tümü',
  'Altın',
  'Döviz',
  'Hisse',
  'Kripto',
  'Fon'
];

class InvestmentsPage extends ConsumerStatefulWidget {
  const InvestmentsPage({super.key});

  @override
  ConsumerState<InvestmentsPage> createState() =>
      _InvestmentsPageState();
}

class _InvestmentsPageState
    extends ConsumerState<InvestmentsPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final async = ref.watch(_investmentsProvider);
    final liveRatesAsync = ref.watch(_liveRatesProvider);
    final liveRatesMap = liveRatesAsync.valueOrNull?['rates']
        as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF051929),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Yatırım',
              subtitle: 'Portföy takibi',
            ),
            // ── Live rates strip ─────────────────────────────────
            if (liveRatesMap != null && liveRatesMap.isNotEmpty)
              _LiveRatesStrip(rates: liveRatesMap),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: c.card,
                onRefresh: () async =>
                    ref.invalidate(_investmentsProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_investmentsProvider),
                  ),
                  data: (data) {
                    final assets = (data['assets'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    final totals =
                        data['totals'] as Map<String, dynamic>?;

                    if (assets.isEmpty) {
                      return EmptyState(
                        icon: Icons.trending_up,
                        title: 'Yatırım bulunamadı',
                        subtitle:
                            'Altın, döviz, kripto ve daha fazlasını takip edin.',
                        ctaLabel: '+ Varlık Ekle',
                        onCta: () => _showAddSheet(context),
                      );
                    }

                    final totalVal =
                        (totals?['current_value'] as num?)
                                ?.toDouble() ??
                            0;
                    final totalGain =
                        (totals?['gain_loss'] as num?)
                                ?.toDouble() ??
                            0;
                    final totalCost = totalVal - totalGain;
                    final totalGainPct = totalCost > 0
                        ? (totalGain / totalCost * 100)
                        : 0.0;

                    // Allocation by category
                    final Map<String, double> allocation = {};
                    for (final a in assets) {
                      final type = _category(
                          a['asset_type'] as String? ?? 'other');
                      final val =
                          (a['current_value_try'] as num?)
                                  ?.toDouble() ??
                              0;
                      allocation[type] =
                          (allocation[type] ?? 0) + val;
                    }

                    // Filter
                    final filtered = _filter == 'all'
                        ? assets
                        : assets.where((a) {
                            return _category(a['asset_type']
                                    as String? ??
                                'other') ==
                                _filter;
                          }).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 100),
                      children: [
                        // Hero card
                        _HeroCard(
                          totalVal: totalVal,
                          totalGain: totalGain,
                          totalGainPct: totalGainPct,
                        ),
                        const SizedBox(height: 12),

                        // Allocation card
                        if (allocation.isNotEmpty) ...[
                          _AllocationCard(
                            allocation: allocation,
                            totalVal: totalVal,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Type filter chips
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filterOptions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final opt = _filterOptions[i];
                              final active = _filter == opt;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _filter = opt),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.accent
                                        : c.card,
                                    borderRadius:
                                        BorderRadius.circular(
                                            999),
                                    border: Border.all(
                                        color: active
                                            ? AppColors.accent
                                            : c.border),
                                  ),
                                  child: Text(
                                    _filterLabels[i],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400).copyWith(
                                            color: active
                                                ? const Color(0xFF051929)
                                                : c.text2,
                                            fontWeight: active
                                                ? FontWeight.w600
                                                : FontWeight.w400),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Holdings list
                        ...filtered.map((a) {
                          final rateKey = _liveRateKey(
                              a['asset_type'] as String? ?? 'other');
                          final liveRateObj = rateKey != null
                              ? (liveRatesMap?[rateKey]
                                  as Map<String, dynamic>?)
                              : null;
                          final liveRate = (liveRateObj?['rate']
                                  as num?)?.toDouble();
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8),
                            child: _AssetCard(
                              asset: a,
                              liveRate: liveRate,
                              onDelete: () =>
                                  _deleteAsset(context, a),
                              onEdit: () =>
                                  _showEditSheet(context, a),
                            ),
                          );
                        }),

                        // Dashed add button
                        _DashedAddButton(
                          label: 'Varlık ekle',
                          onTap: () => _showAddSheet(context),
                        ),
                        const SizedBox(height: 16),

                        // Alarms shortcut
                        _AlarmsShortcut(),
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

  void _showAddSheet(BuildContext context) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AssetFormSheet(
          onSaved: () => ref.invalidate(_investmentsProvider)),
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> asset) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AssetEditSheet(
        asset: asset,
        onSaved: () => ref.invalidate(_investmentsProvider),
        onDelete: () => _deleteAsset(context, asset),
      ),
    );
  }

  Future<void> _deleteAsset(
      BuildContext context, Map<String, dynamic> asset) async {
    final c = context.appColors;
    final id = (asset['id'] as num?)?.toInt();
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Varlığı sil',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600).copyWith(color: c.text1)),
        content: Text(
            'Bu yatırım kaydı silinecek. Devam edilsin mi?',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400).copyWith(color: c.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400).copyWith(color: c.text2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: c.negative),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await DioClient.instance
          .delete(ApiEndpoints.investment(id));
      ref.invalidate(_investmentsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silinemedi: $e')),
        );
      }
    }
  }
}

// ── Live Rates Strip ─────────────────────────────────────────────────
class _LiveRatesStrip extends StatelessWidget {
  final Map<String, dynamic> rates;
  const _LiveRatesStrip({required this.rates});

  static const _shown = ['USD', 'EUR', 'XAU'];
  static const _labels = {'USD': 'USD/TRY', 'EUR': 'EUR/TRY', 'XAU': 'ALTIN/g'};

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final items = _shown.where((s) => rates.containsKey(s)).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: items.map((sym) {
          final obj = rates[sym] as Map<String, dynamic>?;
          final rate = (obj?['rate'] as num?)?.toDouble();
          if (rate == null) return const Expanded(child: SizedBox.shrink());
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                  right: sym != items.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c.positive,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _labels[sym] ?? sym,
                        style: TextStyle(
                            fontSize: 9, color: c.text3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sym == 'XAU'
                        ? '₺${rate.toStringAsFixed(0)}'
                        : '₺${rate.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.text1),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
    final c = context.appColors;
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
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child:
                  Icon(Icons.menu, size: 20, color: c.text2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600).copyWith(
                      color: c.text1,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400).copyWith(color: c.text3)),
            ],
          ),
          const Spacer(),
          AiInsightsButton(page: 'investments'),
        ],
      ),
    );
  }
}

// ── Hero Card ────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double totalVal;
  final double totalGain;
  final double totalGainPct;
  const _HeroCard({
    required this.totalVal,
    required this.totalGain,
    required this.totalGainPct,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isPositive = totalGain >= 0;
    final gainColor = isPositive ? c.positive : c.negative;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toplam portföy değeri',
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500).copyWith(color: c.text3)),
          const SizedBox(height: 6),
          Text(
            AppFormatters.currencyCompact(totalVal),
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 34,
                color: c.text1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 24h change badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isPositive
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: gainColor),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${AppFormatters.currencyCompact(totalGain)}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: gainColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}%${totalGainPct.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: gainColor),
                ),
              ),
              const SizedBox(width: 8),
              Text('toplam K/Z',
                  style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Allocation Card ──────────────────────────────────────────────────
class _AllocationCard extends StatelessWidget {
  final Map<String, double> allocation;
  final double totalVal;
  const _AllocationCard(
      {required this.allocation, required this.totalVal});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final entries = allocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Varlık dağılımı',
              style:
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3)),
          const SizedBox(height: 12),
          // Horizontal stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: entries.map((e) {
                  final pct =
                      totalVal > 0 ? e.value / totalVal : 0.0;
                  final style = _typeStyles[e.key] ??
                      _typeStyles['diğer']!;
                  return Flexible(
                    flex: (pct * 1000).round(),
                    child: Container(color: style.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries.map((e) {
              final pct = totalVal > 0
                  ? (e.value / totalVal * 100)
                  : 0.0;
              final style =
                  _typeStyles[e.key] ?? _typeStyles['diğer']!;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(style.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text2)),
                  const SizedBox(width: 4),
                  Text('%${pct.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Dashed Add Button ────────────────────────────────────────────────
class _DashedAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DashedAddButton(
      {required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: c.border,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: c.text3),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.text3)),
          ],
        ),
      ),
    );
  }
}

// ── Alarms shortcut ──────────────────────────────────────────────────
class _AlarmsShortcut extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final countAsync = ref.watch(_fxAlertCountProvider);
    final count = countAsync.valueOrNull;

    return GestureDetector(
      onTap: () => context.go('/fx-alerts'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFC99B5B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.notifications_outlined,
                  size: 20, color: Color(0xFFC99B5B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kur ve altın alarmları',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.text1)),
                  const SizedBox(height: 2),
                  Text(
                    count == null
                        ? 'Alarmları görüntüle'
                        : count == 0
                            ? 'Henüz alarm yok'
                            : '$count aktif alarm',
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.text3),
          ],
        ),
      ),
    );
  }
}

// ── Asset Card ───────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final double? liveRate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _AssetCard({
    required this.asset,
    this.liveRate,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final assetType =
        asset['asset_type'] as String? ?? 'other';
    final cat = _category(assetType);
    final style =
        _typeStyles[cat] ?? _typeStyles['diğer']!;
    final name = asset['type_label'] as String? ??
        asset['name'] as String? ??
        '';
    final quantity =
        (asset['quantity'] as num?)?.toDouble() ?? 0;
    final currentPrice =
        (asset['current_price_try'] as num?)?.toDouble() ??
            0;
    final currentVal =
        (asset['current_value_try'] as num?)?.toDouble() ??
            0;
    final gainPct =
        (asset['gain_loss_pct'] as num?)?.toDouble() ?? 0;
    final isPositive = gainPct >= 0;
    final changeColor = isPositive ? c.positive : c.negative;

    final symbol = assetType.length <= 3
        ? assetType.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Dismissible(
      key: Key('asset-${asset['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: c.negative,
          borderRadius: BorderRadius.circular(20),
        ),
        child:
            const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(symbol,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: style.color)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text1)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 4)} × ${AppFormatters.currencyCompact(currentPrice)}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: c.text3),
                      ),
                      if (liveRate != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.positive.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: c.positive,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppFormatters.currencyCompact(
                                    liveRate!),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: c.positive),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currencyCompact(currentVal),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text1),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        changeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}%${gainPct.toStringAsFixed(1)}',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: changeColor),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Asset Edit Sheet ─────────────────────────────────────────────────
class _AssetEditSheet extends StatefulWidget {
  final Map<String, dynamic> asset;
  final VoidCallback onSaved;
  final VoidCallback onDelete;
  const _AssetEditSheet({
    required this.asset,
    required this.onSaved,
    required this.onDelete,
  });

  @override
  State<_AssetEditSheet> createState() => _AssetEditSheetState();
}

class _AssetEditSheetState extends State<_AssetEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final qty = (widget.asset['quantity'] as num?)?.toDouble() ?? 0;
    final price = (widget.asset['buy_price_try'] as num?)?.toDouble() ?? 0;
    _qtyCtrl   = TextEditingController(text: qty.toStringAsFixed(qty % 1 == 0 ? 0 : 4));
    _priceCtrl = TextEditingController(text: price.toStringAsFixed(2));
    _notesCtrl = TextEditingController(text: widget.asset['notes'] as String? ?? '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final id = (widget.asset['id'] as num).toInt();
      await DioClient.instance.put(ApiEndpoints.investment(id), data: {
        'quantity':      double.parse(_qtyCtrl.text.trim()),
        'buy_price_try': double.parse(_priceCtrl.text.trim()),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydedilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final assetType = widget.asset['asset_type'] as String? ?? 'other';
    final cat = _category(assetType);
    final style = _typeStyles[cat] ?? _typeStyles['diğer']!;
    final name = widget.asset['type_label'] as String? ??
        widget.asset['name'] as String? ?? '';
    final currentVal =
        (widget.asset['current_value_try'] as num?)?.toDouble() ?? 0;
    final gainPct =
        (widget.asset['gain_loss_pct'] as num?)?.toDouble() ?? 0;
    final isPositive = gainPct >= 0;
    final gainColor = isPositive ? c.positive : c.negative;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: varlık bilgisi + silme butonu
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: style.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.text1)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              AppFormatters.currencyCompact(currentVal),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.text2),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: gainColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${isPositive ? '+' : ''}%${gainPct.toStringAsFixed(1)}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: gainColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.negative.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: c.negative.withValues(alpha: 0.25)),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: c.negative),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Miktar
              Text('MİKTAR',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.text3,
                      letterSpacing: 0.6)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text1),
                decoration: InputDecoration(
                  hintText: '0',
                  filled: true,
                  fillColor: c.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Zorunlu';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Geçersiz miktar';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Alış fiyatı
              Text('ALIŞ FİYATI (₺)',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.text3,
                      letterSpacing: 0.6)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text1),
                decoration: InputDecoration(
                  hintText: '0,00',
                  filled: true,
                  fillColor: c.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Zorunlu';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Geçersiz fiyat';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notlar
              Text('NOT (opsiyonel)',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.text3,
                      letterSpacing: 0.6)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: TextStyle(fontSize: 14, color: c.text1),
                decoration: InputDecoration(
                  hintText: 'Notlar…',
                  hintStyle: TextStyle(color: c.text3),
                  filled: true,
                  fillColor: c.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Kaydet butonu
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF051929),
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF051929)))
                      : const Text('Güncelle',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Asset Form Sheet ─────────────────────────────────────────────────
class _AssetFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AssetFormSheet({required this.onSaved});

  @override
  State<_AssetFormSheet> createState() =>
      _AssetFormSheetState();
}

class _AssetFormSheetState extends State<_AssetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String _assetType = 'gold_gram';
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _buyDate = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await DioClient.instance
          .post(ApiEndpoints.investments, data: {
        'asset_type': _assetType,
        'name': _nameCtrl.text.trim(),
        'quantity': double.parse(_qtyCtrl.text.trim()),
        'buy_price_try': double.parse(_priceCtrl.text.trim()),
        'buy_date':
            _buyDate.toIso8601String().substring(0, 10),
        'notes': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydedilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _buyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _buyDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Yeni Varlık Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text1)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _assetType,
                dropdownColor: c.card,
                decoration: const InputDecoration(
                    labelText: 'Varlık Türü'),
                items: _assetTypes
                    .map((t) => DropdownMenuItem(
                        value: t.$1, child: Text(t.$2)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _assetType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'İsim / Not'),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Zorunlu'
                        : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Miktar'),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Zorunlu';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Geçersiz';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Alış Fiyatı (TL)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Zorunlu';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Geçersiz';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Alış Tarihi'),
                  child: Text(AppFormatters.dateShort(_buyDate),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.text1)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Notlar (opsiyonel)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF051929),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF051929)))
                    : const Text('Kaydet'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
