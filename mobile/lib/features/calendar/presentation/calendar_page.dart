import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _calendarProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, month) async {
  final res = await DioClient.instance
      .get(ApiEndpoints.calendar, queryParameters: {'month': month});
  return res.data as Map<String, dynamic>;
});

const _eventColors = {
  'fatura': Color(0xFFC084FC),
  'kredi': AppColors.negative,
  'kart': AppColors.info,
  'abonelik': Color(0xFFA78BFA),
  'danger': AppColors.negative,
  'warning': AppColors.warning,
  'info': AppColors.info,
  'success': AppColors.positive,
  'primary': AppColors.accent,
};

Color _eventColor(Map<String, dynamic> ev) {
  final type = ev['type'] as String?;
  final color = ev['color'] as String?;
  return _eventColors[type] ??
      _eventColors[color] ??
      AppColors.text2Dark;
}

const _filterOptions = ['all', 'fatura', 'kredi', 'kart', 'abonelik'];
const _filterLabels = ['Tümü', 'Fatura', 'Kredi', 'Kart', 'Abonelik'];
const _weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month;
  String _view = 'month'; // 'month' | 'agenda'
  String _filter = 'all';
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _monthKey =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_calendarProvider(_monthKey));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: const Icon(Icons.menu,
                          size: 16, color: AppColors.text2Dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Takvim',
                            style: AppTextStyles.headlineLarge
                                .copyWith(color: AppColors.text1Dark)),
                        Text('Tüm ödeme ve vadeler',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.text3Dark)),
                      ],
                    ),
                  ),
                  _ViewToggle(
                    value: _view,
                    onChange: (v) => setState(() => _view = v),
                  ),
                ],
              ),
            ),
            // Filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 6),
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                        color: active ? AppColors.accent : AppColors.bg2,
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
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.bg2,
                onRefresh: () async =>
                    ref.invalidate(_calendarProvider(_monthKey)),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_calendarProvider(_monthKey)),
                  ),
                  data: (data) {
                    // API returns events keyed by day number
                    final rawEvents =
                        data['events'] as Map<String, dynamic>? ?? {};
                    final totalMonthly =
                        (data['total_monthly_payments'] as num?)
                                ?.toDouble() ??
                            0;

                    // Convert day-keyed map → date-keyed map
                    final Map<String, List<Map<String, dynamic>>>
                        eventsByDate = {};
                    rawEvents.forEach((dayKey, dayEvents) {
                      final day = int.tryParse(dayKey);
                      if (day == null) return;
                      final dateStr =
                          '${_month.year}-${_month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                      final list = (dayEvents as List)
                          .cast<Map<String, dynamic>>();
                      final filtered = _filter == 'all'
                          ? list
                          : list.where((e) {
                              return (e['type'] as String?) == _filter ||
                                  (e['color'] as String?) == _filter;
                            }).toList();
                      if (filtered.isNotEmpty) {
                        eventsByDate[dateStr] = filtered;
                      }
                    });

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (_view == 'month') ...[
                          _MonthNav(
                            month: _month,
                            onPrev: _prevMonth,
                            onNext: _nextMonth,
                          ),
                          _CalendarGrid(
                            month: _month,
                            eventsByDate: eventsByDate,
                            selectedDate: _selectedDate,
                            onSelect: (d) =>
                                setState(() => _selectedDate = d),
                          ),
                          _SelectedDayEvents(
                            date: _selectedDate,
                            events: _selectedDate != null
                                ? (eventsByDate[_selectedDate!] ?? [])
                                : [],
                          ),
                        ] else ...[
                          _AgendaList(eventsByDate: eventsByDate),
                        ],
                        _WeekSummaryCard(
                            eventsByDate: eventsByDate,
                            totalMonthly: totalMonthly),
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

// ── View Toggle ──────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;
  const _ViewToggle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: AppColors.bg2, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(label: 'Ay', active: value == 'month',
              onTap: () => onChange('month')),
          _ToggleBtn(label: 'Liste', active: value == 'agenda',
              onTap: () => onChange('agenda')),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.bg3 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: active ? AppColors.text1Dark : AppColors.text3Dark,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

// ── Month Nav ────────────────────────────────────────────────────────
class _MonthNav extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthNav(
      {required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavCircleBtn(icon: Icons.chevron_left, onTap: onPrev),
          Text(
            AppFormatters.dateMonth(month),
            style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600),
          ),
          _NavCircleBtn(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavCircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bg2,
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Icon(icon, size: 16, color: AppColors.text2Dark),
      ),
    );
  }
}

// ── Calendar Grid ────────────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, List<Map<String, dynamic>>> eventsByDate;
  final String? selectedDate;
  final ValueChanged<String> onSelect;
  const _CalendarGrid(
      {required this.month,
      required this.eventsByDate,
      required this.selectedDate,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final firstWeekday =
        DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    // Build cells: (firstWeekday-1) nulls + days 1..daysInMonth
    final cells = <int?>[
      ...List.filled(firstWeekday - 1, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
    // Pad to multiple of 7
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Column(
          children: [
            // Day names
            Row(
              children: _weekDays
                  .map((d) => Expanded(
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.text3Dark,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.06 * 10)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Grid
            for (int row = 0; row < cells.length ~/ 7; row++)
              Row(
                children: List.generate(7, (col) {
                  final d = cells[row * 7 + col];
                  if (d == null) return const Expanded(child: SizedBox());
                  final dateStr =
                      '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
                  final dayEvents = eventsByDate[dateStr] ?? [];
                  final isToday = dateStr == todayStr;
                  final isSelected = dateStr == selectedDate;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelect(dateStr),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : isToday
                                    ? AppColors.bg3
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                '$d',
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: isSelected
                                        ? AppColors.accentText
                                        : isToday
                                            ? AppColors.accent
                                            : AppColors.text1Dark,
                                    fontWeight:
                                        isToday || isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    fontSize: 13),
                              ),
                              if (dayEvents.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: dayEvents
                                        .take(3)
                                        .map((e) => Container(
                                              width: 4,
                                              height: 4,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 1),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? AppColors.accentText
                                                    : _eventColor(e),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Selected Day Events ──────────────────────────────────────────────
class _SelectedDayEvents extends StatelessWidget {
  final String? date;
  final List<Map<String, dynamic>> events;
  const _SelectedDayEvents({required this.date, required this.events});

  @override
  Widget build(BuildContext context) {
    String dayLabel = '';
    if (date != null) {
      try {
        final dt = DateTime.parse(date!);
        dayLabel = AppFormatters.dateLong(dt);
      } catch (_) {
        dayLabel = date!;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(dayLabel,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      const Icon(Icons.add,
                          size: 14, color: AppColors.text3Dark),
                      const SizedBox(width: 4),
                      Text('Hatırlatıcı',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.text3Dark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          events.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bg1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border1Dark),
                  ),
                  child: Center(
                    child: Text('Bu gün için olay yok',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.text3Dark)),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border1Dark),
                  ),
                  child: Column(
                    children: events.asMap().entries.map((entry) {
                      return _EventRow(
                          event: entry.value,
                          showBorder: entry.key > 0);
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool showBorder;
  const _EventRow({required this.event, required this.showBorder});

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event);
    final title = event['title'] as String? ?? '';
    final amount =
        (event['amount'] as num?)?.toDouble() ?? 0;
    final type = event['type'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(top: BorderSide(color: AppColors.border1Dark))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForType(type),
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (type.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(type,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: color, fontSize: 10)),
                  ),
              ],
            ),
          ),
          Text(
            '-${AppFormatters.currencyCompact(amount)} ₺',
            style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.negative),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'fatura':
        return Icons.power_outlined;
      case 'kredi':
        return Icons.account_balance_outlined;
      case 'kart':
        return Icons.credit_card_outlined;
      case 'abonelik':
        return Icons.subscriptions_outlined;
      default:
        return Icons.event_outlined;
    }
  }
}

// ── Agenda List ──────────────────────────────────────────────────────
class _AgendaList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> eventsByDate;
  const _AgendaList({required this.eventsByDate});

  @override
  Widget build(BuildContext context) {
    final sorted = eventsByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sorted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Bu ay için etkinlik yok.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.text3Dark)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sorted.map((entry) {
          DateTime? dt;
          try {
            dt = DateTime.parse(entry.key);
          } catch (_) {}
          return Column(
            children: entry.value.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Column(
                        children: [
                          Text(
                            dt != null ? '${dt.day}' : entry.key,
                            style: AppTextStyles.amountHero.copyWith(
                                fontSize: 18,
                                color: AppColors.text1Dark),
                          ),
                          if (dt != null)
                            Text(
                              _weekdayShort(dt.weekday),
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.text3Dark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bg1,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.border1Dark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _eventColor(e),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(e['title'] as String? ?? '',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              fontWeight:
                                                  FontWeight.w600)),
                                  if ((e['type'] as String?)
                                          ?.isNotEmpty ==
                                      true)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 2),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _eventColor(e)
                                            .withValues(alpha: 0.13),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                          e['type'] as String? ?? '',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color: _eventColor(e),
                                                  fontSize: 10)),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '-${AppFormatters.currencyCompact((e['amount'] as num?)?.toDouble() ?? 0)} ₺',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.negative),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  String _weekdayShort(int weekday) {
    const days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday];
  }
}

// ── Week Summary Card ────────────────────────────────────────────────
class _WeekSummaryCard extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> eventsByDate;
  final double totalMonthly;
  const _WeekSummaryCard(
      {required this.eventsByDate, required this.totalMonthly});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));

    double weekTotal = 0;
    int weekCount = 0;
    String? firstLabel;
    for (final entry in eventsByDate.entries) {
      try {
        final dt = DateTime.parse(entry.key);
        if (!dt.isBefore(now) && !dt.isAfter(weekEnd)) {
          for (final e in entry.value) {
            weekTotal += (e['amount'] as num?)?.toDouble() ?? 0;
            weekCount++;
            firstLabel ??= e['title'] as String?;
          }
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.bg1, AppColors.bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Önümüzdeki 7 gün',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.text3Dark)),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currencyCompact(weekTotal),
                    style: AppTextStyles.amountHero.copyWith(
                        fontSize: 22,
                        color: AppColors.text1Dark,
                        letterSpacing: -0.02 * 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$weekCount ödeme${firstLabel != null ? ' · İlk: $firstLabel' : ''}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.text3Dark),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  size: 22, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
