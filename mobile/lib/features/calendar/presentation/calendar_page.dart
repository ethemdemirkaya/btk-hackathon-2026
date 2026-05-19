import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
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

// ── Notes (local, SharedPreferences) ─────────────────────────────────
class _NotesNotifier extends StateNotifier<Map<String, String>> {
  static const _prefKey = 'calendar_notes_v1';

  _NotesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      try {
        state = Map<String, String>.from(json.decode(raw) as Map);
      } catch (_) {}
    }
  }

  Future<void> setNote(String date, String text) async {
    final next = Map<String, String>.from(state);
    if (text.trim().isEmpty) {
      next.remove(date);
    } else {
      next[date] = text.trim();
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, json.encode(next));
  }
}

final _notesProvider =
    StateNotifierProvider<_NotesNotifier, Map<String, String>>(
        (_) => _NotesNotifier());

// API returns: 'bill', 'subscription', 'loan' — map them to display types
String _normalizeType(String? raw) {
  switch (raw) {
    case 'bill':
      return 'fatura';
    case 'subscription':
      return 'abonelik';
    case 'loan':
      return 'kredi';
    case 'card':
      return 'kart';
    default:
      return raw ?? '';
  }
}

const _eventColors = {
  'fatura':    Color(0xFFC084FC),
  'kredi':     Color(0xFFFF4D6D),
  'kart':      Color(0xFF6FB1FC),
  'abonelik':  Color(0xFFA78BFA),
  'danger':    Color(0xFFFF4D6D),
  'warning':   Color(0xFFF59E0B),
  'info':      Color(0xFF6FB1FC),
  'success':   Color(0xFF0DD9A0),
  'primary':   Color(0xFF00D4FF),
};

Color _eventColor(Map<String, dynamic> ev) {
  final type = _normalizeType(ev['type'] as String?);
  final color = ev['color'] as String?;
  return _eventColors[type] ??
      _eventColors[color] ??
      const Color(0xFF8BA4BC);
}

const _filterOptions = ['all', 'fatura', 'kredi', 'kart', 'abonelik'];
const _filterLabels  = ['Tümü', 'Fatura', 'Kredi', 'Kart', 'Abonelik'];
const _weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month;
  String _view = 'month';
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

  void _showNoteSheet(BuildContext context, String date, String? current) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NoteSheet(
        date: date,
        initialNote: current,
        onSave: (text) async =>
            ref.read(_notesProvider.notifier).setNote(date, text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final async = ref.watch(_calendarProvider(_monthKey));
    final notes = ref.watch(_notesProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
                      child: Icon(Icons.menu,
                          size: 18, color: c.text2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finansal Takvim',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: c.text1)),
                        Text('Tüm ödeme ve vadeler',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: c.text3)),
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
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final opt = _filterOptions[i];
                  final active = _filter == opt;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filter = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accent
                            : c.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: active
                                ? AppColors.accent
                                : c.border),
                      ),
                      child: Text(
                        _filterLabels[i],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active
                                ? const Color(0xFF051929)
                                : c.text2),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: c.card,
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
                    final rawEvents =
                        data['events'] as Map<String, dynamic>? ??
                            {};
                    // API returns 'total_payments', not 'total_monthly_payments'
                    final totalMonthly =
                        (data['total_payments'] as num?)
                                ?.toDouble() ??
                            0;

                    final Map<String,
                        List<Map<String, dynamic>>> eventsByDate = {};
                    rawEvents.forEach((dayKey, dayEvents) {
                      final day = int.tryParse(dayKey);
                      if (day == null) return;
                      final dateStr =
                          '${_month.year}-${_month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                      if (dayEvents is! List) return;
                      final rawList = dayEvents
                          .whereType<Map<String, dynamic>>().toList();
                      // Normalize API types ('bill','subscription','loan') to display types
                      final list = rawList.map((e) {
                        final normalized = Map<String, dynamic>.from(e);
                        normalized['type'] = _normalizeType(e['type'] as String?);
                        return normalized;
                      }).toList();
                      final filtered = _filter == 'all'
                          ? list
                          : list.where((e) {
                              return (e['type'] as String?) == _filter;
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
                            notedDates: notes.keys.toSet(),
                            onSelect: (d) =>
                                setState(() => _selectedDate = d),
                          ),
                          _SelectedDayEvents(
                            date: _selectedDate,
                            events: _selectedDate != null
                                ? (eventsByDate[_selectedDate!] ??
                                    [])
                                : [],
                            note: _selectedDate != null
                                ? notes[_selectedDate!]
                                : null,
                            onAddNote: _selectedDate == null
                                ? null
                                : () => _showNoteSheet(
                                    context,
                                    _selectedDate!,
                                    notes[_selectedDate!]),
                          ),
                          _UpcomingEventsList(
                            eventsByDate: eventsByDate,
                            currentMonth: _month,
                          ),
                        ] else ...[
                          _AgendaList(
                              eventsByDate: eventsByDate),
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
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
              label: 'Ay',
              active: value == 'month',
              onTap: () => onChange('month')),
          _ToggleBtn(
              label: 'Liste',
              active: value == 'agenda',
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
      {required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: active ? AppColors.accent : c.text3)),
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
      {required this.month,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavCircleBtn(
              icon: Icons.chevron_left, onTap: onPrev),
          Text(
            AppFormatters.dateMonth(month),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.text1),
          ),
          _NavCircleBtn(
              icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavCircleBtn(
      {required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 18, color: c.text2),
      ),
    );
  }
}

// ── Calendar Grid ────────────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, List<Map<String, dynamic>>> eventsByDate;
  final String? selectedDate;
  final Set<String> notedDates;
  final ValueChanged<String> onSelect;
  const _CalendarGrid(
      {required this.month,
      required this.eventsByDate,
      required this.selectedDate,
      required this.notedDates,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final firstWeekday =
        DateTime(month.year, month.month, 1).weekday;
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    final cells = <int?>[
      ...List.filled(firstWeekday - 1, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            // Day names
            Row(
              children: _weekDays
                  .map((d) => Expanded(
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: c.text3)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Grid
            for (int row = 0; row < cells.length ~/ 7; row++)
              Row(
                children: List.generate(7, (col) {
                  final d = cells[row * 7 + col];
                  if (d == null) {
                    return const Expanded(child: SizedBox());
                  }
                  final dateStr =
                      '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
                  final dayEvents =
                      eventsByDate[dateStr] ?? [];
                  final isToday = dateStr == todayStr;
                  final isSelected = dateStr == selectedDate;
                  final hasNote = notedDates.contains(dateStr);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelect(dateStr),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          children: [
                          Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : isToday
                                    ? AppColors.accent.withValues(alpha: 0.10)
                                    : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: AppColors.accent)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                '$d',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        isToday || isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF051929)
                                        : isToday
                                            ? AppColors.accent
                                            : c.text1),
                              ),
                              if (dayEvents.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2),
                                  child: dayEvents.length > 1
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF051929).withValues(alpha: 0.5)
                                                : _eventColor(dayEvents.first).withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${dayEvents.length}',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? const Color(0xFF051929)
                                                  : _eventColor(dayEvents.first),
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: dayEvents
                                              .take(3)
                                              .map((e) => Container(
                                                    width: 4,
                                                    height: 4,
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 1),
                                                    decoration:
                                                        BoxDecoration(
                                                      shape:
                                                          BoxShape.circle,
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFF051929)
                                                          : _eventColor(
                                                              e),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                ),
                            ],
                          ),
                        ),
                        if (hasNote)
                          Positioned(
                            top: 3,
                            right: 3,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
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
  final String? note;
  final VoidCallback? onAddNote;
  const _SelectedDayEvents(
      {required this.date,
      required this.events,
      this.note,
      this.onAddNote});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(dayLabel,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text1)),
                ),
                GestureDetector(
                  onTap: onAddNote,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          note != null
                              ? Icons.edit_note
                              : Icons.note_add_outlined,
                          size: 13,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note != null ? 'Notu Düzenle' : 'Not Ekle',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (note != null && note!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note!,
                      style: TextStyle(
                          fontSize: 13, color: c.text2, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          events.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Center(
                    child: Text('Bu gün için olay yok',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: c.text3)),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
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
  const _EventRow(
      {required this.event, required this.showBorder});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = _eventColor(event);
    final title = event['title'] as String? ?? '';
    final amount = (event['amount'] as num?)?.toDouble() ?? 0;
    final type = event['type'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(top: BorderSide(color: c.border))
            : null,
      ),
      child: Row(
        children: [
          // Colored left accent bar
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconForType(type), size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text1)),
                if (type.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(type,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: color)),
                  ),
              ],
            ),
          ),
          Text(
            '-${AppFormatters.currencyCompact(amount)}',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.negative),
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
      // Legacy API type names (in case normalization is bypassed)
      case 'bill':
        return Icons.power_outlined;
      case 'loan':
        return Icons.account_balance_outlined;
      case 'subscription':
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
    final c = context.appColors;
    final sorted = eventsByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sorted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Bu ay için etkinlik yok.',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: c.text3)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      width: 44,
                      child: Column(
                        children: [
                          Text(
                            dt != null ? '${dt.day}' : entry.key,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: c.text1),
                          ),
                          if (dt != null)
                            Text(
                              _weekdayShort(dt.weekday),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: c.text3),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _eventColor(e),
                                borderRadius:
                                    BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      e['title'] as String? ?? '',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: c.text1)),
                                  if ((e['type'] as String?)
                                          ?.isNotEmpty ==
                                      true)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(
                                              top: 3),
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
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w500,
                                              color: _eventColor(e))),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '-${AppFormatters.currencyCompact((e['amount'] as num?)?.toDouble() ?? 0)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.negative),
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
    const days = [
      '',
      'Pzt',
      'Sal',
      'Çar',
      'Per',
      'Cum',
      'Cmt',
      'Paz'
    ];
    return days[weekday];
  }
}

// ── Upcoming Events List ─────────────────────────────────────────────
class _UpcomingEventsList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> eventsByDate;
  final DateTime currentMonth;
  const _UpcomingEventsList(
      {required this.eventsByDate, required this.currentMonth});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final now = DateTime.now();
    // Show events from today forward (within this month or future months)
    final upcoming = eventsByDate.entries
        .where((e) {
          try {
            final dt = DateTime.parse(e.key);
            return !dt.isBefore(DateTime(now.year, now.month, now.day));
          } catch (_) {
            return false;
          }
        })
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              'Yaklaşan Ödemeler',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.text3,
                  letterSpacing: 0.5),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: upcoming.take(5).expand((entry) {
                DateTime? dt;
                try { dt = DateTime.parse(entry.key); } catch (_) {}
                return entry.value.map((e) {
                  final isFirst = entry == upcoming.first &&
                      e == entry.value.first;
                  final color = _eventColor(e);
                  final type = e['type'] as String? ?? '';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: !isFirst
                          ? Border(
                              top: BorderSide(color: c.border))
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (dt != null) ...[
                                Text(
                                  '${dt.day}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: color),
                                ),
                                Text(
                                  _monthShort(dt.month),
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: color.withValues(alpha: 0.7)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['title'] as String? ?? '',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: c.text1),
                              ),
                              if (type.isNotEmpty)
                                Text(
                                  _typeLabel(type),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: color.withValues(alpha: 0.8)),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '-${AppFormatters.currencyCompact((e['amount'] as num?)?.toDouble() ?? 0)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.negative),
                        ),
                      ],
                    ),
                  );
                });
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return months[month];
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fatura':    return 'Fatura';
      case 'kredi':     return 'Kredi Ödemesi';
      case 'kart':      return 'Kart Ödemesi';
      case 'abonelik':  return 'Abonelik';
      default:          return type;
    }
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
    final c = context.appColors;
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
            weekTotal +=
                (e['amount'] as num?)?.toDouble() ?? 0;
            weekCount++;
            firstLabel ??= e['title'] as String?;
          }
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Önümüzdeki 7 gün',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: c.text3)),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.currencyCompact(weekTotal),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.text1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$weekCount ödeme${firstLabel != null ? ' · İlk: $firstLabel' : ''}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: c.text3),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
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

// ── Note Sheet ───────────────────────────────────────────────────────
class _NoteSheet extends StatefulWidget {
  final String date;
  final String? initialNote;
  final Future<void> Function(String) onSave;
  const _NoteSheet(
      {required this.date, this.initialNote, required this.onSave});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_ctrl.text);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    await widget.onSave('');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.initialNote != null ? 'Notu Düzenle' : 'Not Ekle',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.text1),
                ),
              ),
              if (widget.initialNote != null)
                IconButton(
                  onPressed: _saving ? null : _delete,
                  icon: Icon(Icons.delete_outline,
                      color: c.negative, size: 20),
                  tooltip: 'Notu Sil',
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: c.text2, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            autofocus: true,
            style: TextStyle(color: c.text1, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Bu tarihe not ekle...',
              hintStyle: TextStyle(color: c.text3, fontSize: 13),
              filled: true,
              fillColor: c.bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF051929),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _saving ? 'Kaydediliyor...' : 'Kaydet',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
