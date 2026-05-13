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

final _transactionListProvider =
    FutureProvider.autoDispose<TransactionPage>((ref) async {
  final api = ref.watch(_transactionsApiProvider);
  final type = ref.watch(_filterTypeProvider);
  return api.getTransactions(type: type, perPage: 50);
});

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(_transactionListProvider);
    final selectedType = ref.watch(_filterTypeProvider);
    final query = ref.watch(_searchQueryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('İşlemler',
                            style: AppTextStyles.headlineLarge
                                .copyWith(color: AppColors.text1Dark)),
                        Text(
                          asyncData.when(
                            data: (p) =>
                                '${p.data.length} işlem · ${_currentMonth()}',
                            loading: () => _currentMonth(),
                            error: (_, __) => _currentMonth(),
                          ),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.text3Dark),
                        ),
                      ],
                    ),
                  ),
                  _HeaderBtn(
                    icon: Icons.sync,
                    onTap: () => ref.invalidate(_transactionListProvider),
                  ),
                  const SizedBox(width: 8),
                  _HeaderBtn(
                    icon: Icons.menu,
                    onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border1Dark),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search,
                        size: 18, color: AppColors.text3Dark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            ref.read(_searchQueryProvider.notifier).state = v,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.text1Dark),
                        decoration: InputDecoration(
                          hintText: 'Merchant, açıklama veya tutar ara',
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
                    if (query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.close,
                              size: 16, color: AppColors.text3Dark),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tümü',
                    selected: selectedType == null,
                    onTap: () =>
                        ref.read(_filterTypeProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Gider',
                    icon: Icons.arrow_upward,
                    selected: selectedType == 'expense',
                    onTap: () => ref.read(_filterTypeProvider.notifier).state =
                        'expense',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Gelir',
                    icon: Icons.arrow_downward,
                    selected: selectedType == 'income',
                    onTap: () => ref.read(_filterTypeProvider.notifier).state =
                        'income',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Month summary card
            asyncData.when(
              data: (page) => _MonthlySummary(items: page.data),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            // List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.bg2,
                onRefresh: () async =>
                    ref.invalidate(_transactionListProvider),
                child: asyncData.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_transactionListProvider),
                  ),
                  data: (page) {
                    final filtered = _applySearch(page.data, query);
                    if (filtered.isEmpty) {
                      return _EmptySearch(
                        onClear: () {
                          _searchCtrl.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                          ref.read(_filterTypeProvider.notifier).state = null;
                        },
                      );
                    }
                    return _GroupedTransactionList(items: filtered);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentText,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }

  String _currentMonth() {
    final now = DateTime.now();
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  List<TransactionModel> _applySearch(
      List<TransactionModel> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((t) {
      final merchant = (t.merchantName ?? t.description).toLowerCase();
      return merchant.contains(q) || t.category.name.toLowerCase().contains(q);
    }).toList();
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});

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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? AppColors.accent : AppColors.text2Dark),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.accent : AppColors.text1Dark,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  final List<TransactionModel> items;
  const _MonthlySummary({required this.items});

  @override
  Widget build(BuildContext context) {
    final income =
        items.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.tryAmount);
    final expense = items
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.tryAmount.abs());
    final net = income - expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Row(
          children: [
            _SummaryCell(
                label: 'Gelir',
                value: '+${AppFormatters.currencyCompact(income)}',
                valueColor: AppColors.positive),
            _Divider(),
            _SummaryCell(
                label: 'Gider',
                value: '−${AppFormatters.currencyCompact(expense)}',
                valueColor: AppColors.text1Dark),
            _Divider(),
            _SummaryCell(
                label: 'Net',
                value: '+${AppFormatters.currencyCompact(net)}',
                valueColor: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _SummaryCell(
      {required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.text3Dark)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 32, color: AppColors.border1Dark,
        margin: const EdgeInsets.symmetric(horizontal: 12));
  }
}

class _EmptySearch extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptySearch({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sonuç bulunamadı',
              style: AppTextStyles.headlineSmall
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Filtreleri temizleyip yeniden dene',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.text3Dark)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border2Dark),
              ),
              child: Text('Filtreleri temizle',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text1Dark)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedTransactionList extends StatelessWidget {
  final List<TransactionModel> items;
  const _GroupedTransactionList({required this.items});

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
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final txns = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Text(
                key.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.text3Dark,
                    letterSpacing: 0.08 * 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border1Dark),
                ),
                child: Column(
                  children: txns
                      .asMap()
                      .entries
                      .map((e) => _TransactionRow(
                            transaction: e.value,
                            showBorder: e.key > 0,
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final bool showBorder;
  const _TransactionRow(
      {required this.transaction, required this.showBorder});

  Color _categoryColor(String categoryName) {
    // Simple color hash based on first char
    final colors = [
      AppColors.accent,
      const Color(0xFFA78BFA),
      AppColors.positive,
      AppColors.warning,
      const Color(0xFF6FB1FC),
      AppColors.negative,
      AppColors.gold,
    ];
    return colors[categoryName.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isExpense = t.isExpense;
    final color = _categoryColor(t.category.name);

    return GestureDetector(
      onTap: () => context.push('/transactions/${t.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(top: BorderSide(color: AppColors.border1Dark))
              : null,
        ),
        child: Row(
          children: [
            // Category bubble
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  t.category.name.isEmpty
                      ? '?'
                      : t.category.name[0].toUpperCase(),
                  style: AppTextStyles.titleMedium
                      .copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (t.anomalyScore != null && t.anomalyScore! > 0.7)
                        const Icon(Icons.warning_amber_rounded,
                            size: 12, color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        AppFormatters.time(t.postedAt),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.text3Dark),
                      ),
                      Container(
                          width: 2,
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                              color: AppColors.text3Dark,
                              shape: BoxShape.circle)),
                      Text(
                        t.category.name,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.text3Dark),
                      ),
                      if (t.isInstallment) ...[
                        Container(
                            width: 2,
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: const BoxDecoration(
                                color: AppColors.text3Dark,
                                shape: BoxShape.circle)),
                        Text(
                          '${t.installmentNo}/${t.installmentTotal}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.info),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '−' : '+'}${AppFormatters.currencyCompact(t.tryAmount.abs())}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isExpense ? AppColors.text1Dark : AppColors.positive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₺',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.text2Dark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
