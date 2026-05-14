import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
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
const _warning    = Color(0xFFF59E0B); // ignore: unused_element

final _investmentsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res =
      await DioClient.instance.get(ApiEndpoints.investments);
  return res.data as Map<String, dynamic>;
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
    final async = ref.watch(_investmentsProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: _accent,
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
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
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
                                        ? _accent
                                        : _cardBg,
                                    borderRadius:
                                        BorderRadius.circular(
                                            999),
                                    border: Border.all(
                                        color: active
                                            ? _accent
                                            : _cardBorder),
                                  ),
                                  child: Text(
                                    _filterLabels[i],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400).copyWith(
                                            color: active
                                                ? const Color(0xFF051929)
                                                : _text2,
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
                        ...filtered.map((a) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8),
                              child: _AssetCard(
                                asset: a,
                                onDelete: () =>
                                    _deleteAsset(context, a),
                              ),
                            )),

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AssetFormSheet(
          onSaved: () => ref.invalidate(_investmentsProvider)),
    );
  }

  Future<void> _deleteAsset(
      BuildContext context, Map<String, dynamic> asset) async {
    final id = (asset['id'] as num?)?.toInt();
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('Varlığı sil',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600).copyWith(color: _text1)),
        content: Text(
            'Bu yatırım kaydı silinecek. Devam edilsin mi?',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400).copyWith(color: _text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400).copyWith(color: _text2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _negative),
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
    final isPositive = totalGain >= 0;
    final gainColor = isPositive ? _positive : _negative;

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
          Text('Toplam portföy değeri',
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500).copyWith(color: _text3)),
          const SizedBox(height: 6),
          Text(
            '${AppFormatters.currencyCompact(totalVal)} ₺',
            style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 34,
                color: _text1),
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
                      '${isPositive ? '+' : ''}${AppFormatters.currencyCompact(totalGain)} ₺',
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
              const Text('toplam K/Z',
                  style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
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
    final entries = allocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Varlık dağılımı',
              style:
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
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
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text2)),
                  const SizedBox(width: 4),
                  Text('%${pct.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _cardBorder,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: _text3),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text3)),
          ],
        ),
      ),
    );
  }
}

// ── Alarms shortcut ──────────────────────────────────────────────────
class _AlarmsShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFC99B5B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 20, color: Color(0xFFC99B5B)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kur ve altın alarmları',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text1)),
                SizedBox(height: 2),
                Text('3 aktif alarm',
                    style: TextStyle(
                        fontSize: 11, color: _text3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 16, color: _text3),
        ],
      ),
    );
  }
}

// ── Asset Card ───────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final VoidCallback onDelete;
  const _AssetCard(
      {required this.asset, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
    final changeColor = isPositive ? _positive : _negative;

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
          color: _negative,
          borderRadius: BorderRadius.circular(20),
        ),
        child:
            const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
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
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _text1)),
                  const SizedBox(height: 3),
                  Text(
                    '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 4)} × ${AppFormatters.currencyCompact(currentPrice)} ₺',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _text3),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${AppFormatters.currencyCompact(currentVal)} ₺',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _text1),
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
              const Text('Yeni Varlık Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text1)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _assetType,
                dropdownColor: _cardBg,
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _text1)),
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
                  backgroundColor: _accent,
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
