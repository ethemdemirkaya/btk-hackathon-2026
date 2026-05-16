import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
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
final _periodProvider = StateProvider<int?>((ref) => 1);

// Fetches all transactions without type filter — type filtering is done client-side
// so the summary bar always has access to both income and expense data.
final _transactionListProvider =
    FutureProvider.autoDispose<TransactionPage>((ref) async {
  final api = ref.watch(_transactionsApiProvider);
  return api.getTransactions(type: null, perPage: 50);
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
  const palette = [
    AppColors.accent,
    Color(0xFFA78BFA),
    Color(0xFF0DD9A0),
    Color(0xFFF59E0B),
    Color(0xFF6FB1FC),
    Color(0xFFFF4D6D),
    Color(0xFFC99B5B),
  ];
  return palette[name.codeUnitAt(0) % palette.length];
}

String _periodDisplayLabel(int? period) {
  if (period == null) return 'Tüm Zamanlar';
  switch (period) {
    case 1: return '1 Aylık';
    case 2: return '2 Aylık';
    case 3: return '3 Aylık';
    case 6: return '6 Aylık';
    case 12: return '1 Yıllık';
    case 24: return '2 Yıllık';
    default: return '$period Aylık';
  }
}

String _periodRangeLabel(int? period) {
  final now = DateTime.now();
  const months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  if (period == null) return 'Tüm Zamanlar';
  if (period == 1) return '${months[now.month - 1]} ${now.year}';
  if (period < 12) return 'Son $period Ay';
  final years = period ~/ 12;
  return 'Son $years Yıl';
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
    final c = context.appColors;
    final asyncData = ref.watch(_transactionListProvider);
    final selectedType = ref.watch(_filterTypeProvider);
    final selectedFilter = ref.watch(_selectedFilterProvider);
    final selectedPeriod = ref.watch(_periodProvider);
    final query = ref.watch(_searchQueryProvider);

    final filteredCount = asyncData.whenOrNull(
      data: (page) => _applyFilters(
              page.data, query, selectedType, selectedFilter, selectedPeriod)
          .length,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              filteredCount: filteredCount,
              selectedPeriod: selectedPeriod,
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
            ),
            const SizedBox(height: 10),
            asyncData.when(
              data: (page) => _SummaryBar(
                items: _applyPeriodFilter(page.data, selectedPeriod),
                period: selectedPeriod,
              ),
              loading: () => const _SummaryBarSkeleton(),
              error: (_, __) => _SummaryBar(
                items: const [],
                period: selectedPeriod,
              ),
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
            const SizedBox(height: 6),
            _PeriodSelector(
              selectedPeriod: selectedPeriod,
              onPeriodChanged: (v) =>
                  ref.read(_periodProvider.notifier).state = v,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: c.card,
                onRefresh: () async =>
                    ref.invalidate(_transactionListProvider),
                child: asyncData.when(
                  loading: () => const _TransactionSkeleton(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_transactionListProvider),
                  ),
                  data: (page) {
                    final filtered = _applyFilters(
                        page.data, query, selectedType, selectedFilter, selectedPeriod);
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        onClear: () {
                          _searchCtrl.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                          ref.read(_filterTypeProvider.notifier).state = null;
                          ref
                              .read(_selectedFilterProvider.notifier)
                              .state = null;
                          ref.read(_periodProvider.notifier).state = 1;
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
    );
  }

  List<TransactionModel> _applyPeriodFilter(
      List<TransactionModel> items, int? period) {
    if (period == null) return items;
    final now = DateTime.now();
    int month = now.month - period;
    int year = now.year;
    while (month <= 0) {
      month += 12;
      year--;
    }
    final cutoff = DateTime(year, month, now.day);
    return items.where((t) => t.postedAt.isAfter(cutoff)).toList();
  }

  List<TransactionModel> _applyFilters(
    List<TransactionModel> items,
    String query,
    String? selectedType,
    String? extFilter,
    int? period,
  ) {
    var result = _applyPeriodFilter(items, period);
    if (selectedType == 'expense') {
      result = result.where((t) => t.isExpense).toList();
    } else if (selectedType == 'income') {
      result = result.where((t) => t.isIncome).toList();
    }
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
      result = result.where((t) => (t.anomalyScore ?? 0) > 0.7).toList();
    }
    return result;
  }
}

class _Header extends StatelessWidget {
  final int? filteredCount;
  final int? selectedPeriod;
  final bool searchExpanded;
  final TextEditingController searchCtrl;
  final VoidCallback onHamburger;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  const _Header({
    required this.filteredCount,
    required this.selectedPeriod,
    required this.searchExpanded,
    required this.searchCtrl,
    required this.onHamburger,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  String _subtitle() {
    final periodStr = _periodRangeLabel(selectedPeriod);
    if (filteredCount == null) return periodStr;
    return '$filteredCount işlem · $periodStr';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: c.text1),
                    ),
                    Text(
                      _subtitle(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: c.text3),
                    ),
                  ],
                ),
              ),
              _IconBtn(
                icon: searchExpanded ? Icons.search_off : Icons.search,
                onTap: onSearchToggle,
              ),
              const SizedBox(width: 8),
              AiInsightsButton(page: 'transactions'),
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
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 18, color: c.text2),
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
    final c = context.appColors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, size: 18, color: c.text3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.text1),
              decoration: InputDecoration(
                hintText: 'Merchant, açıklama ara…',
                hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.text3),
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
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.close, size: 16, color: c.text3),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatefulWidget {
  final List<TransactionModel> items;
  final int? period;
  const _SummaryBar({required this.items, required this.period});

  @override
  State<_SummaryBar> createState() => _SummaryBarState();
}

class _SummaryBarState extends State<_SummaryBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    // Always calculate from all period-filtered items regardless of type filter
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
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _periodRangeLabel(widget.period),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: c.text3,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SummaryCell(
                    label: 'Gelir',
                    value: '+${AppFormatters.currencyCompact(income)}',
                    valueColor: c.positive,
                  ),
                  _VertDivider(),
                  _SummaryCell(
                    label: 'Gider',
                    value: '−${AppFormatters.currencyCompact(expense)}',
                    valueColor: c.negative,
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
                    color: c.text3,
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
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
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
    final c = context.appColors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
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
    final c = context.appColors;
    return Container(
      width: 1,
      height: 30,
      color: c.border,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<TransactionModel> items;
  const _MiniBarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
                      ? c.negative.withValues(alpha: 0.7)
                      : AppColors.accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayLabels[dayOfWeek],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: c.text3,
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
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.18) : c.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : c.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: selected ? AppColors.accent : c.text3),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.accent : c.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int? selectedPeriod;
  final ValueChanged<int?> onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  void _showPicker(BuildContext context) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PeriodPickerSheet(
        selectedPeriod: selectedPeriod,
        onChanged: onPeriodChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 13, color: c.text3),
            const SizedBox(width: 6),
            Text(
              'Aralık Seç',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: c.text3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _periodDisplayLabel(selectedPeriod),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: AppColors.accent,
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

class _PeriodPickerSheet extends StatelessWidget {
  final int? selectedPeriod;
  final ValueChanged<int?> onChanged;

  const _PeriodPickerSheet({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    const options = [
      (1, '1 Aylık'),
      (2, '2 Aylık'),
      (3, '3 Aylık'),
      (6, '6 Aylık'),
      (12, '1 Yıllık'),
      (24, '2 Yıllık'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 16, color: c.text3),
              const SizedBox(width: 8),
              Text(
                'Aralık Seç',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.text1,
                ),
              ),
            ],
          ),
        ),
        ...options.map((opt) {
          final isSelected = selectedPeriod == opt.$1;
          return GestureDetector(
            onTap: () {
              onChanged(opt.$1);
              Navigator.of(context).pop();
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.accent : c.text1,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }
}

class _TransactionSkeleton extends StatelessWidget {
  const _TransactionSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
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
    final c = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.card,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color: c.text3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'İşlem bulunamadı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text1),
          ),
          const SizedBox(height: 6),
          Text(
            'Filtreni değiştirip tekrar dene',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: c.text3),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.border),
              ),
              child: Text(
                'Filtreleri temizle',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text1),
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
    final c = context.appColors;
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
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.text3,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  Text(
                    '${dailyNet >= 0 ? '+' : ''}${AppFormatters.currencyCompact(dailyNet)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dailyNet >= 0 ? c.positive : c.text3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
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
    final c = context.appColors;
    final t = transaction;
    final isAnomaly = (t.anomalyScore ?? 0) > 0.7;
    final catColor = _colorForCategory(t.category.name);
    final catIcon = _iconForCategory(t.category.name);

    return Dismissible(
      key: ValueKey(t.id),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: c.negative,
        icon: Icons.delete_outline_rounded,
        label: 'Sil?',
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: const Color(0xFF6FB1FC),
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
                ? c.warning.withValues(alpha: 0.05)
                : Colors.transparent,
            border: showTopBorder
                ? Border(top: BorderSide(color: c.border))
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
                      ? c.warning
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
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ]
            : [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
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
    final c = context.appColors;
    final effectiveColor = isAnomaly ? c.warning : color;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        isAnomaly ? Icons.warning_amber_rounded : icon,
        size: 19,
        color: effectiveColor,
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
    final c = context.appColors;
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.text1,
                ),
              ),
            ),
            if (isAnomaly) ...[
              const SizedBox(width: 4),
              Icon(Icons.bolt_rounded, size: 13, color: c.warning),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              AppFormatters.time(t.postedAt),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.text3),
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
    final c = context.appColors;
    return Container(
      width: 2,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: c.text3,
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
    final c = context.appColors;
    final data = _channelData[channel];
    if (data == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.$1, size: 10, color: c.text3),
        const SizedBox(width: 3),
        Text(
          data.$2,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c.text3),
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
    const infoColor = Color(0xFF6FB1FC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: infoColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: infoColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '$no/$total',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: infoColor,
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
    final c = context.appColors;
    final t = transaction;
    final isExpense = t.isExpense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${isExpense ? '−' : '+'}${AppFormatters.currencyCompact(t.tryAmount.abs())}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isExpense ? c.negative : c.positive,
          ),
        ),
        if (t.channel == 'credit_card' || t.isInstallment)
          Text(
            '₺',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c.text3),
          ),
      ],
    );
  }
}
