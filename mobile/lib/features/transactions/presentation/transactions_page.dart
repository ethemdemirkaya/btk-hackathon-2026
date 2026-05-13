import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../shared/providers/dio_provider.dart';
import '../data/transactions_api.dart';
import '../domain/transaction_model.dart';

final _transactionsApiProvider = Provider<TransactionsApi>((ref) {
  return TransactionsApi(ref.watch(dioProvider));
});

final _filterTypeProvider = StateProvider<String?>((ref) => null);
final _searchQueryProvider = StateProvider<String>((ref) => '');
final _selectedFilterProvider = StateProvider<String?>((ref) => null);

final _transactionListProvider =
    FutureProvider.autoDispose<TransactionPage>((ref) async {
  final api = ref.watch(_transactionsApiProvider);
  final type = ref.watch(_filterTypeProvider);
  return api.getTransactions(type: type, perPage: 50);
});

const _categoryIcons = <String, IconData>{
  'market': Icons.local_grocery_store_outlined,
  'restoran': Icons.restaurant_outlined,
  'yemek': Icons.restaurant_outlined,
  'ulaşım': Icons.directions_car_outlined,
  'giyim': Icons.checkroom_outlined,
  'eğlence': Icons.movie_outlined,
  'sağlık': Icons.health_and_safety_outlined,
  'fatura': Icons.receipt_outlined,
  'eğitim': Icons.school_outlined,
  'teknoloji': Icons.computer_outlined,
  'spor': Icons.fitness_center_outlined,
  'diğer': Icons.category_outlined,
};

const _categoryColors = <String, Color>{
  'market': Color(0xFF2BE0A0),
  'restoran': Color(0xFFFFC857),
  'yemek': Color(0xFFFFC857),
  'ulaşım': Color(0xFF6FB1FC),
  'giyim': Color(0xFFA78BFA),
  'eğlence': Color(0xFFFF5C7C),
  'sağlık': Color(0xFF2BE0A0),
  'fatura': Color(0xFF6FB1FC),
  'eğitim': Color(0xFFC99B5B),
  'teknoloji': Color(0xFF00D4FF),
  'spor': Color(0xFF2BE0A0),
  'diğer': Color(0xFF8FA5C2),
};

IconData _iconForCategory(String name) {
  final lower = name.toLowerCase();
  for (final key in _categoryIcons.keys) {
    if (lower.contains(key)) return _categoryIcons[key]!;
  }
  return Icons.category_outlined;
}

Color _colorForCategory(String name) {
  final lower = name.toLowerCase();
  for (final key in _categoryColors.keys) {
    if (lower.contains(key)) return _categoryColors[key]!;
  }
  final palette = [
    AppColors.accent,
    const Color(0xFFA78BFA),
    AppColors.positive,
    AppColors.warning,
    const Color(0xFF6FB1FC),
    AppColors.negative,
    AppColors.gold,
  ];
  return palette[name.codeUnitAt(0) % palette.length];
}

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchCtrl = TextEditingController();
  bool _searchExpanded = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(_transactionListProvider);
    final selectedType = ref.watch(_filterTypeProvider);
    final selectedFilter = ref.watch(_selectedFilterProvider);
    final query = ref.watch(_searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              asyncData: asyncData,
              searchExpanded: _searchExpanded,
              searchCtrl: _searchCtrl,
              onHamburger: () => shellScaffoldKey.currentState?.openDrawer(),
              onSearchToggle: () => setState(() {
                _searchExpanded = !_searchExpanded;
                if (!_searchExpanded) {
                  _searchCtrl.clear();
                  ref.read(_searchQueryProvider.notifier).state = '';
                }
              }),
              onSearchChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
              onSearchClear: () {
                _searchCtrl.clear();
                ref.read(_searchQueryProvider.notifier).state = '';
              },
              onFilter: () => _showFilterSheet(context),
            ),
            const SizedBox(height: 10),
            asyncData.when(
              data: (page) => _SummaryBar(items: page.data),
              loading: () => const _SummaryBarSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            _FilterChipsRow(
              selectedType: selectedType,
              selectedFilter: selectedFilter,
              onTypeChanged: (v) {
                ref.read(_filterTypeProvider.notifier).state = v;
                ref.read(_selectedFilterProvider.notifier).state = null;
              },
              onFilterChanged: (v) {
                ref.read(_selectedFilterProvider.notifier).state = v;
                ref.read(_filterTypeProvider.notifier).state = null;
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.bg2,
                onRefresh: () async =>
                    ref.invalidate(_transactionListProvider),
                child: asyncData.when(
                  loading: () => const _TransactionSkeleton(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_transactionListProvider),
                  ),
                  data: (page) {
                    final filtered =
                        _applyFilters(page.data, query, selectedFilter);
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        onClear: () {
                          _searchCtrl.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                          ref.read(_filterTypeProvider.notifier).state = null;
                          ref
                              .read(_selectedFilterProvider.notifier)
                              .state = null;
                        },
                      );
                    }
                    return _GroupedList(items: filtered);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yakında eklenecek'),
            duration: Duration(seconds: 2),
          ),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentText,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }

  List<TransactionModel> _applyFilters(
    List<TransactionModel> items,
    String query,
    String? extFilter,
  ) {
    var result = items;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((t) {
        final merchant = (t.merchantName ?? t.description).toLowerCase();
        return merchant.contains(q) ||
            t.category.name.toLowerCase().contains(q);
      }).toList();
    }
    if (extFilter == 'installment') {
      result = result.where((t) => t.isInstallment).toList();
    } else if (extFilter == 'anomaly') {
      result =
          result.where((t) => (t.anomalyScore ?? 0) > 0.7).toList();
    }
    return result;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        onApply: (type, extFilter) {
          ref.read(_filterTypeProvider.notifier).state = type;
          ref.read(_selectedFilterProvider.notifier).state = extFilter;
          Navigator.pop(context);
        },
        currentType: ref.read(_filterTypeProvider),
        currentFilter: ref.read(_selectedFilterProvider),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AsyncValue<TransactionPage> asyncData;
  final bool searchExpanded;
  final TextEditingController searchCtrl;
  final VoidCallback onHamburger;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilter;

  const _Header({
    required this.asyncData,
    required this.searchExpanded,
    required this.searchCtrl,
    required this.onHamburger,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilter,
  });

  String _subtitle(AsyncValue<TransactionPage> data) {
    final now = DateTime.now();
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final monthStr = '${months[now.month - 1]} ${now.year}';
    return data.when(
      data: (p) => '${p.data.length} işlem · $monthStr',
      loading: () => monthStr,
      error: (_, __) => monthStr,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBtn(icon: Icons.menu, onTap: onHamburger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İşlemler',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: AppColors.text1Dark),
                    ),
                    Text(
                      _subtitle(asyncData),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.text3Dark),
                    ),
                  ],
                ),
              ),
              _IconBtn(
                icon: searchExpanded ? Icons.search_off : Icons.search,
                onTap: onSearchToggle,
              ),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.tune, onTap: onFilter),
            ],
          ),
          if (searchExpanded) ...[
            const SizedBox(height: 10),
            _SearchBar(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              onClear: onSearchClear,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Icon(icon, size: 18, color: AppColors.text2Dark),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border2Dark),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 18, color: AppColors.text3Dark),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.text1Dark),
              decoration: InputDecoration(
                hintText: 'Merchant, açıklama ara…',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.text3Dark),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.close, size: 16, color: AppColors.text3Dark),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatefulWidget {
  final List<TransactionModel> items;
  const _SummaryBar({required this.items});

  @override
  State<_SummaryBar> createState() => _SummaryBarState();
}

class _SummaryBarState extends State<_SummaryBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final income = widget.items
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.tryAmount);
    final expense = widget.items
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.tryAmount.abs());
    final net = income - expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(_expanded ? 16 : 14),
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border2Dark),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _SummaryCell(
                    label: 'Gelir',
                    value: '+${AppFormatters.currencyCompact(income)}',
                    valueColor: AppColors.positive,
                  ),
                  _VertDivider(),
                  _SummaryCell(
                    label: 'Gider',
                    value: '−${AppFormatters.currencyCompact(expense)}',
                    valueColor: AppColors.negative,
                  ),
                  _VertDivider(),
                  _SummaryCell(
                    label: 'Net',
                    value:
                        '${net >= 0 ? '+' : ''}${AppFormatters.currencyCompact(net)}',
                    valueColor: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.text3Dark,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 14),
                _MiniBarChart(items: widget.items),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBarSkeleton extends StatelessWidget {
  const _SummaryBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.text3Dark),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.border1Dark,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<TransactionModel> items;
  const _MiniBarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final dayTotals = days.map((day) {
      return items
          .where((t) {
            final td = DateTime(t.postedAt.year, t.postedAt.month, t.postedAt.day);
            return td == day && t.isExpense;
          })
          .fold(0.0, (s, t) => s + t.tryAmount.abs());
    }).toList();

    final maxVal = dayTotals.reduce((a, b) => a > b ? a : b);

    const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final ratio = maxVal > 0 ? dayTotals[i] / maxVal : 0.0;
        final barHeight = 2 + ratio * 48;
        final dayOfWeek = days[i].weekday - 1;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300 + i * 40),
                curve: Curves.easeOut,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: ratio > 0.7
                      ? AppColors.negative.withValues(alpha: 0.7)
                      : AppColors.accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayLabels[dayOfWeek],
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.text3Dark,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final String? selectedType;
  final String? selectedFilter;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onFilterChanged;

  const _FilterChipsRow({
    required this.selectedType,
    required this.selectedFilter,
    required this.onTypeChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _PillChip(
            label: 'Tümü',
            icon: Icons.apps_rounded,
            selected: selectedType == null && selectedFilter == null,
            onTap: () {
              onTypeChanged(null);
              onFilterChanged(null);
            },
          ),
          const SizedBox(width: 8),
          _PillChip(
            label: 'Gider',
            icon: Icons.arrow_upward_rounded,
            selected: selectedType == 'expense',
            onTap: () => onTypeChanged('expense'),
          ),
          const SizedBox(width: 8),
          _PillChip(
            label: 'Gelir',
            icon: Icons.arrow_downward_rounded,
            selected: selectedType == 'income',
            onTap: () => onTypeChanged('income'),
          ),
          const SizedBox(width: 8),
          _PillChip(
            label: 'Taksit',
            icon: Icons.credit_card_outlined,
            selected: selectedFilter == 'installment',
            onTap: () => onFilterChanged('installment'),
          ),
          const SizedBox(width: 8),
          _PillChip(
            label: 'Anomali',
            icon: Icons.bolt_rounded,
            selected: selectedFilter == 'anomaly',
            onTap: () => onFilterChanged('anomaly'),
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDim : AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border1Dark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected ? AppColors.accent : AppColors.text3Dark,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.accent : AppColors.text1Dark,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionSkeleton extends StatelessWidget {
  const _TransactionSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: 3,
      itemBuilder: (_, groupIndex) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: SkeletonBox(width: 90, height: 11, borderRadius: 6),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border1Dark),
            ),
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      const SkeletonBox(
                          width: 42, height: 42, borderRadius: 13),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(
                              width: MediaQuery.of(context).size.width * 0.45,
                              height: 13,
                            ),
                            const SizedBox(height: 7),
                            const SkeletonBox(width: 80, height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const SkeletonBox(width: 60, height: 15),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border2Dark),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color: AppColors.text3Dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'İşlem bulunamadı',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.text1Dark),
          ),
          const SizedBox(height: 6),
          Text(
            'Filtreni değiştirip tekrar dene',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.text3Dark),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border2Dark),
              ),
              child: Text(
                'Filtreleri temizle',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.text1Dark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<TransactionModel> items;
  const _GroupedList({required this.items});

  Map<String, List<TransactionModel>> _group() {
    final map = <String, List<TransactionModel>>{};
    for (final t in items) {
      final key = AppFormatters.relativeDate(t.postedAt);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _group();
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final txns = grouped[key]!;
        final dailyNet =
            txns.fold(0.0, (s, t) => s + (t.isExpense ? -t.tryAmount.abs() : t.tryAmount));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.text3Dark,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${dailyNet >= 0 ? '+' : ''}${AppFormatters.currencyCompact(dailyNet)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: dailyNet >= 0
                          ? AppColors.positive
                          : AppColors.text3Dark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg1,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border1Dark),
              ),
              child: Column(
                children: txns.asMap().entries.map((e) {
                  return _TransactionRow(
                    transaction: e.value,
                    showTopBorder: e.key > 0,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final bool showTopBorder;
  const _TransactionRow({
    required this.transaction,
    required this.showTopBorder,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isAnomaly = (t.anomalyScore ?? 0) > 0.7;
    final catColor = _colorForCategory(t.category.name);
    final catIcon = _iconForCategory(t.category.name);

    return Dismissible(
      key: ValueKey(t.id),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: AppColors.negative,
        icon: Icons.delete_outline_rounded,
        label: 'Sil?',
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: AppColors.info,
        icon: Icons.open_in_new_rounded,
        label: 'Detay',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İşlem silinemiyor'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        context.push('/transactions/${t.id}');
        return false;
      },
      child: GestureDetector(
        onTap: () => context.push('/transactions/${t.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: isAnomaly
                ? AppColors.warning.withValues(alpha: 0.05)
                : Colors.transparent,
            border: showTopBorder
                ? Border(top: BorderSide(color: AppColors.border1Dark))
                : null,
            borderRadius: !showTopBorder
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 64,
                margin: const EdgeInsets.only(left: 0),
                decoration: BoxDecoration(
                  color: isAnomaly
                      ? AppColors.warning
                      : catColor.withValues(alpha: 0.7),
                  borderRadius: showTopBorder
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      _CategoryIcon(
                        icon: catIcon,
                        color: catColor,
                        isAnomaly: isAnomaly,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RowInfo(transaction: t, isAnomaly: isAnomaly),
                      ),
                      const SizedBox(width: 8),
                      _AmountDisplay(transaction: t),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      color: color.withValues(alpha: 0.12),
      padding: EdgeInsets.only(
        left: isLeft ? 20 : 0,
        right: isLeft ? 0 : 20,
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ]
            : [
                Text(label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Icon(icon, color: color, size: 20),
              ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isAnomaly;
  const _CategoryIcon({
    required this.icon,
    required this.color,
    required this.isAnomaly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: (isAnomaly ? AppColors.warning : color).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: (isAnomaly ? AppColors.warning : color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        isAnomaly ? Icons.warning_amber_rounded : icon,
        size: 19,
        color: isAnomaly ? AppColors.warning : color,
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final TransactionModel transaction;
  final bool isAnomaly;
  const _RowInfo({required this.transaction, required this.isAnomaly});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.merchantName ?? t.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text1Dark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isAnomaly) ...[
              const SizedBox(width: 4),
              const Icon(Icons.bolt_rounded, size: 13, color: AppColors.warning),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              AppFormatters.time(t.postedAt),
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.text3Dark),
            ),
            if (t.channel != 'other') ...[
              _Dot(),
              _ChannelChip(channel: t.channel),
            ],
            if (t.isInstallment) ...[
              _Dot(),
              _InstallmentBadge(
                no: t.installmentNo!,
                total: t.installmentTotal!,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: AppColors.text3Dark,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final String channel;
  const _ChannelChip({required this.channel});

  static const _channelData = {
    'credit_card': (Icons.credit_card_outlined, 'Kart'),
    'bank_transfer': (Icons.swap_horiz_rounded, 'Havale'),
    'cash': (Icons.payments_outlined, 'Nakit'),
    'online': (Icons.wifi_rounded, 'Online'),
  };

  @override
  Widget build(BuildContext context) {
    final data = _channelData[channel];
    if (data == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.$1, size: 10, color: AppColors.text3Dark),
        const SizedBox(width: 3),
        Text(
          data.$2,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.text3Dark, fontSize: 10),
        ),
      ],
    );
  }
}

class _InstallmentBadge extends StatelessWidget {
  final int no;
  final int total;
  const _InstallmentBadge({required this.no, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '$no/$total',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.info,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final TransactionModel transaction;
  const _AmountDisplay({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isExpense = t.isExpense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${isExpense ? '−' : '+'}${AppFormatters.currencyCompact(t.tryAmount.abs())}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isExpense ? AppColors.negative : AppColors.positive,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (t.channel == 'credit_card' || t.isInstallment)
          Text(
            '₺',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.text3Dark, fontSize: 10),
          ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? currentType;
  final String? currentFilter;
  final void Function(String? type, String? extFilter) onApply;

  const _FilterSheet({
    required this.currentType,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _type;
  String? _extFilter;

  @override
  void initState() {
    super.initState();
    _type = widget.currentType;
    _extFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtrele',
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: AppColors.text1Dark),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.text3Dark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'İşlem Türü',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.text3Dark, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SheetChip(
                label: 'Tümü',
                selected: _type == null,
                onTap: () => setState(() => _type = null),
              ),
              const SizedBox(width: 8),
              _SheetChip(
                label: 'Gider',
                selected: _type == 'expense',
                onTap: () => setState(() => _type = 'expense'),
              ),
              const SizedBox(width: 8),
              _SheetChip(
                label: 'Gelir',
                selected: _type == 'income',
                onTap: () => setState(() => _type = 'income'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Özel Filtre',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.text3Dark, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SheetChip(
                label: 'Taksit',
                selected: _extFilter == 'installment',
                onTap: () => setState(
                  () => _extFilter =
                      _extFilter == 'installment' ? null : 'installment',
                ),
              ),
              const SizedBox(width: 8),
              _SheetChip(
                label: 'Anomali',
                selected: _extFilter == 'anomaly',
                onTap: () => setState(
                  () => _extFilter =
                      _extFilter == 'anomaly' ? null : 'anomaly',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => widget.onApply(_type, _extFilter),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Uygula',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accentText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDim : AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border1Dark,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.accent : AppColors.text1Dark,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
