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

final _investmentsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.investments);
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

// Maps asset_type keys → category label used for filtering
String _category(String assetType) {
  if (assetType.startsWith('gold')) return 'altın';
  if (assetType == 'usd' || assetType == 'eur' || assetType == 'gbp') {
    return 'döviz';
  }
  if (assetType == 'btc' || assetType == 'eth') return 'kripto';
  if (assetType == 'bist') return 'hisse';
  if (assetType == 'fund') return 'fon';
  return 'diğer';
}

const _typeStyles = {
  'altın': (color: AppColors.gold, label: 'Altın'),
  'döviz': (color: AppColors.info, label: 'Döviz'),
  'kripto': (color: Color(0xFFF472B6), label: 'Kripto'),
  'hisse': (color: AppColors.accent, label: 'Hisse'),
  'fon': (color: Color(0xFFA78BFA), label: 'Fon'),
  'diğer': (color: AppColors.text2Dark, label: 'Diğer'),
};

const _filterOptions = ['all', 'altın', 'döviz', 'hisse', 'kripto', 'fon'];
const _filterLabels = ['Tümü', 'Altın', 'Döviz', 'Hisse', 'Kripto', 'Fon'];

class InvestmentsPage extends ConsumerStatefulWidget {
  const InvestmentsPage({super.key});

  @override
  ConsumerState<InvestmentsPage> createState() => _InvestmentsPageState();
}

class _InvestmentsPageState extends ConsumerState<InvestmentsPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_investmentsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentText,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.bg2,
          onRefresh: () async => ref.invalidate(_investmentsProvider),
          child: async.when(
            loading: () => const SkeletonListView(),
            error: (e, __) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(_investmentsProvider),
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
                  (totals?['current_value'] as num?)?.toDouble() ?? 0;
              final totalGain =
                  (totals?['gain_loss'] as num?)?.toDouble() ?? 0;
              final totalCost = totalVal - totalGain;
              final totalGainPct =
                  totalCost > 0 ? (totalGain / totalCost * 100) : 0.0;

              // Group by category for allocation bar
              final Map<String, double> allocation = {};
              for (final a in assets) {
                final type =
                    _category(a['asset_type'] as String? ?? 'other');
                final val =
                    (a['current_value_try'] as num?)?.toDouble() ?? 0;
                allocation[type] = (allocation[type] ?? 0) + val;
              }

              // Filter
              final filtered = _filter == 'all'
                  ? assets
                  : assets.where((a) {
                      return _category(
                              a['asset_type'] as String? ?? 'other') ==
                          _filter;
                    }).toList();

              return ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text('Yatırım Portföyü',
                        style: AppTextStyles.headlineLarge
                            .copyWith(color: AppColors.text1Dark)),
                  ),

                  // Hero
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Toplam değer',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.text3Dark)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              AppFormatters.currencyCompact(totalVal),
                              style: AppTextStyles.amountHero.copyWith(
                                  fontSize: 40,
                                  color: AppColors.text1Dark,
                                  letterSpacing: -0.03 * 40),
                            ),
                            const SizedBox(width: 4),
                            Text('₺',
                                style: AppTextStyles.headlineMedium
                                    .copyWith(color: AppColors.text2Dark)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _PnLTag(
                                value:
                                    '${totalGain >= 0 ? '+' : ''}${AppFormatters.currencyCompact(totalGain)} ₺',
                                positive: totalGain >= 0),
                            const SizedBox(width: 8),
                            _PnLTag(
                                value:
                                    '${totalGain >= 0 ? '+' : ''}%${totalGainPct.toStringAsFixed(1)}',
                                positive: totalGain >= 0),
                            const SizedBox(width: 8),
                            Text('toplam K/Z',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.text3Dark)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Allocation card
                  if (allocation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _AllocationCard(
                          allocation: allocation, totalVal: totalVal),
                    ),

                  // Type filter chips
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      itemCount: _filterOptions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final opt = _filterOptions[i];
                        final active = _filter == opt;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = opt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.accent
                                  : AppColors.bg2,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: active
                                      ? AppColors.accent
                                      : AppColors.border2Dark),
                            ),
                            child: Text(
                              _filterLabels[i],
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: active
                                      ? AppColors.accentText
                                      : AppColors.text2Dark,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Holdings list
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      children: [
                        ...filtered.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AssetCard(
                                asset: a,
                                onDelete: () => _deleteAsset(context, a),
                              ),
                            )),

                        // Dashed add button
                        GestureDetector(
                          onTap: () => _showAddSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border2Dark,
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add,
                                    size: 18, color: AppColors.text3Dark),
                                const SizedBox(width: 8),
                                Text('Varlık ekle',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(
                                            color: AppColors.text3Dark,
                                            fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Alarms shortcut
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bg1,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                size: 20, color: AppColors.gold),
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
                                        color: AppColors.text1Dark)),
                                SizedBox(height: 2),
                                Text('3 aktif alarm',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.text3Dark)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 16, color: AppColors.text3Dark),
                        ],
                      ),
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

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
        backgroundColor: AppColors.bg2,
        title: Text('Varlığı sil',
            style: AppTextStyles.headlineMedium),
        content: Text(
            'Bu yatırım kaydı silinecek. Devam edilsin mi?',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.text2Dark)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.text2Dark))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await DioClient.instance.delete(ApiEndpoints.investment(id));
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

// ── P&L Tag ──────────────────────────────────────────────────────────
class _PnLTag extends StatelessWidget {
  final String value;
  final bool positive;
  const _PnLTag({required this.value, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.positive : AppColors.negative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 11, color: color),
          const SizedBox(width: 2),
          Text(value,
              style: AppTextStyles.labelSmall.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border1Dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Varlık dağılımı',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.text3Dark)),
          const SizedBox(height: 10),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
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
          const SizedBox(height: 12),
          // Legend grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries.map((e) {
              final pct =
                  totalVal > 0 ? (e.value / totalVal * 100) : 0.0;
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
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text2Dark)),
                  const SizedBox(width: 4),
                  Text('%${pct.toStringAsFixed(0)}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text3Dark)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Asset Card ───────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final VoidCallback onDelete;
  const _AssetCard({required this.asset, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final assetType = asset['asset_type'] as String? ?? 'other';
    final cat = _category(assetType);
    final style = _typeStyles[cat] ?? _typeStyles['diğer']!;
    final name = asset['type_label'] as String? ??
        asset['name'] as String? ?? '';
    final quantity = (asset['quantity'] as num?)?.toDouble() ?? 0;
    final currentPrice =
        (asset['current_price_try'] as num?)?.toDouble() ?? 0;
    final currentVal =
        (asset['current_value_try'] as num?)?.toDouble() ?? 0;
    final gainPct =
        (asset['gain_loss_pct'] as num?)?.toDouble() ?? 0;
    final isPositive = gainPct >= 0;

    // Symbol: first 3 chars of asset_type or name
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
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: AppColors.negative,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(symbol,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: style.color,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 4)} × ${AppFormatters.currencyCompact(currentPrice)} ₺',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.text3Dark),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${AppFormatters.currencyCompact(currentVal)} ₺',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${isPositive ? '+' : ''}%${gainPct.toStringAsFixed(1)}',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: isPositive
                          ? AppColors.positive
                          : AppColors.negative,
                      fontWeight: FontWeight.w600),
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
  State<_AssetFormSheet> createState() => _AssetFormSheetState();
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
      await DioClient.instance.post(ApiEndpoints.investments, data: {
        'asset_type': _assetType,
        'name': _nameCtrl.text.trim(),
        'quantity': double.parse(_qtyCtrl.text.trim()),
        'buy_price_try': double.parse(_priceCtrl.text.trim()),
        'buy_date': _buyDate.toIso8601String().substring(0, 10),
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
              Text('Yeni Varlık Ekle',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _assetType,
                dropdownColor: AppColors.bg2,
                decoration:
                    const InputDecoration(labelText: 'Varlık Türü'),
                items: _assetTypes
                    .map((t) => DropdownMenuItem(
                        value: t.$1, child: Text(t.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _assetType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'İsim / Not'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Miktar'),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Zorunlu';
                        if (double.tryParse(v.trim()) == null)
                          return 'Geçersiz';
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
                        if (v == null || v.trim().isEmpty)
                          return 'Zorunlu';
                        if (double.tryParse(v.trim()) == null)
                          return 'Geçersiz';
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
                  decoration:
                      const InputDecoration(labelText: 'Alış Tarihi'),
                  child: Text(AppFormatters.dateShort(_buyDate),
                      style: AppTextStyles.bodyMedium),
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
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
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
