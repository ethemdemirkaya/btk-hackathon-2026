import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';

// ── JSON helpers ──────────────────────────────────────────────────────
double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

bool _b(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  return v.toString() == '1' || v.toString() == 'true';
}

// ── Local constants (not in AppColorTokens) ───────────────────────────
const _purple  = Color(0xFFA78BFA);

// ── Provider ──────────────────────────────────────────────────────────
final _debtsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.personalDebts);
  return res.data as Map<String, dynamic>;
});

// ── Filter enum ───────────────────────────────────────────────────────
enum _Filter { all, active, settled }

// ── Page ──────────────────────────────────────────────────────────────
class PersonalDebtsPage extends ConsumerStatefulWidget {
  const PersonalDebtsPage({super.key});

  @override
  ConsumerState<PersonalDebtsPage> createState() => _PersonalDebtsPageState();
}

class _PersonalDebtsPageState extends ConsumerState<PersonalDebtsPage> {
  _Filter _filter = _Filter.active;

  void _refresh() => ref.invalidate(_debtsProvider);

  void _showForm(Map<String, dynamic>? existing) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DebtFormSheet(
        existing: existing,
        onSaved: _refresh,
      ),
    );
  }

  Future<void> _settle(int id, String name) async {
    final c = context.appColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Borcu Kapat',
            style: TextStyle(color: c.text1, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text('$name ile olan borcu kapatmak istiyor musunuz?',
            style: TextStyle(color: c.text2, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('İptal', style: TextStyle(color: c.text2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: c.positive, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await DioClient.instance.post(ApiEndpoints.personalDebtSettle(id));
        _refresh();
      } catch (_) {}
    }
  }

  Future<void> _delete(int id) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.personalDebt(id));
      _refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF051929),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: c.card,
          onRefresh: () async => _refresh(),
          child: ref.watch(_debtsProvider).when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
            error: (e, __) => _ErrorView(message: e.toString(), onRetry: _refresh),
            data: (data) {
              final allDebts = (data['debts'] as List? ?? [])
                  .cast<Map<String, dynamic>>();
              final summary = data['summary'] as Map<String, dynamic>? ?? {};

              final filtered = allDebts.where((d) {
                final settled = _b(d['is_settled']);
                return switch (_filter) {
                  _Filter.all     => true,
                  _Filter.active  => !settled,
                  _Filter.settled => settled,
                };
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(summary, allDebts.length)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _AiDetectBanner(onDetected: _refresh),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildFilters(allDebts)),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                        child: _EmptyState(filter: _filter, onAdd: () => _showForm(null))),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _DebtTile(
                          debt: filtered[i],
                          onSettle: () => _settle(_i(filtered[i]['id']),
                              filtered[i]['counterparty_name'] as String? ?? ''),
                          onEdit: () => _showForm(filtered[i]),
                          onDelete: () => _delete(_i(filtered[i]['id'])),
                        ),
                        childCount: filtered.length,
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

  Widget _buildHeader(Map<String, dynamic> summary, int total) {
    final c = context.appColors;
    final iOwe    = _d(summary['i_owe']);
    final owedToMe = _d(summary['owed_to_me']);
    final net     = owedToMe - iOwe;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(children: [
            GestureDetector(
              onTap: () => shellScaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border)),
                child: Icon(Icons.menu, size: 18, color: c.text2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kişisel Borçlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text1)),
                Text('$total kayıt',
                    style: TextStyle(fontSize: 12, color: c.text3)),
              ],
            )),
          ]),
          const SizedBox(height: 20),

          // Net position hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: net >= 0
                    ? [const Color(0xFF0D2A20), const Color(0xFF0D1B2A)]
                    : [const Color(0xFF2A0D14), const Color(0xFF0D1B2A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: net >= 0
                      ? c.positive.withValues(alpha: 0.25)
                      : c.negative.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (net >= 0 ? c.positive : c.negative).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(net >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 12, color: net >= 0 ? c.positive : c.negative),
                      const SizedBox(width: 4),
                      Text(net >= 0 ? 'Net Alacak' : 'Net Borç',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: net >= 0 ? c.positive : c.negative)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(AppFormatters.currencyCompact(net.abs()),
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800,
                        color: net >= 0 ? c.positive : c.negative,
                        letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _MiniStat(
                      label: 'Verilecek', value: iOwe, color: c.negative,
                      icon: Icons.arrow_upward_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _MiniStat(
                      label: 'Alınacak', value: owedToMe, color: c.positive,
                      icon: Icons.arrow_downward_rounded)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<Map<String, dynamic>> all) {
    final activeCount  = all.where((d) => !_b(d['is_settled'])).length;
    final settledCount = all.where((d) =>  _b(d['is_settled'])).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(children: [
        _FilterChip(label: 'Tümü',      count: all.length,     selected: _filter == _Filter.all,
            onTap: () => setState(() => _filter = _Filter.all)),
        const SizedBox(width: 8),
        _FilterChip(label: 'Aktif',     count: activeCount,    selected: _filter == _Filter.active,
            onTap: () => setState(() => _filter = _Filter.active)),
        const SizedBox(width: 8),
        _FilterChip(label: 'Kapatıldı', count: settledCount,   selected: _filter == _Filter.settled,
            onTap: () => setState(() => _filter = _Filter.settled)),
      ]),
    );
  }

}

// ── Mini stat inside hero card ─────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppFormatters.currencyCompact(value),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: c.text3)),
          ],
        )),
      ]),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.count,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.12) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent.withValues(alpha: 0.5) : c.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? AppColors.accent : c.text2)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent.withValues(alpha: 0.2) : c.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: selected ? AppColors.accent : c.text3)),
          ),
        ]),
      ),
    );
  }
}

// ── AI Detect Banner ──────────────────────────────────────────────────
class _AiDetectBanner extends StatefulWidget {
  final VoidCallback onDetected;
  const _AiDetectBanner({required this.onDetected});

  @override
  State<_AiDetectBanner> createState() => _AiDetectBannerState();
}

class _AiDetectBannerState extends State<_AiDetectBanner> {
  bool _loading = false;

  Future<void> _scan() async {
    setState(() => _loading = true);
    try {
      final res  = await DioClient.instance.get(ApiEndpoints.personalDebtsAutoDetect);
      final data = res.data as Map<String, dynamic>;
      final debts      = (data['debt_suggestions']      as List?) ?? [];
      final repayments = (data['repayment_suggestions'] as List?) ?? [];

      if (!mounted) return;
      if (debts.isEmpty && repayments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Son 90 günde tespit edilecek borç hareketi bulunamadı.'),
          backgroundColor: context.appColors.card,
        ));
        return;
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.appColors.card,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _DetectionSheet(
          debtSuggestions: debts.cast<Map<String, dynamic>>(),
          repaymentSuggestions: repayments.cast<Map<String, dynamic>>(),
          onChanged: widget.onDetected,
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg ?? 'Tespit sırasında hata oluştu.'),
        backgroundColor: context.appColors.negative,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Tespit sırasında hata oluştu: $e'),
        backgroundColor: context.appColors.negative,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: _loading ? null : _scan,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_purple.withValues(alpha: 0.12), AppColors.accent.withValues(alpha: 0.06)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _purple.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: _loading
                ? const Padding(padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: _purple))
                : const Icon(Icons.auto_awesome, size: 20, color: _purple),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Borç Tespiti',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text1)),
              Text('Hareketlerde borç / geri ödeme ara',
                  style: TextStyle(fontSize: 11, color: c.text3)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_loading ? 'Tarıyor…' : 'Tara',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _purple)),
          ),
        ]),
      ),
    );
  }
}

// ── Debt Tile ──────────────────────────────────────────────────────────
class _DebtTile extends StatelessWidget {
  final Map<String, dynamic> debt;
  final VoidCallback onSettle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DebtTile({required this.debt, required this.onSettle,
      required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isBorrowed = debt['type'] == 'borrowed';
    final amount     = _d(debt['amount']);
    final name       = debt['counterparty_name'] as String? ?? 'Bilinmiyor';
    final desc       = debt['description'] as String?;
    final isSettled  = _b(debt['is_settled']);
    final autoDetect = _b(debt['is_auto_detected']);
    final color      = isBorrowed ? c.negative : c.positive;
    final label      = isBorrowed ? 'Borcum var' : 'Alacağım var';
    final initial    = name.isNotEmpty
        ? String.fromCharCode(name.runes.first).toUpperCase()
        : '?';

    return Dismissible(
      key: ValueKey(_i(debt['id'])),
      direction: isSettled ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: c.negative.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: c.negative),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSettled ? c.border : color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: isSettled
                            ? c.text3.withValues(alpha: 0.1)
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(initial,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                              color: isSettled ? c.text3 : color))),
                    ),
                    if (autoDetect)
                      Positioned(right: 0, top: 0,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                              color: _purple, shape: BoxShape.circle,
                              border: Border.all(color: c.card, width: 1.5)),
                          child: const Icon(Icons.auto_awesome, size: 9, color: Colors.white),
                        ),
                      ),
                  ]),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: isSettled ? c.text2 : c.text1))),
                        Text(AppFormatters.currencyCompact(amount),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                color: isSettled ? c.text3 : color)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSettled
                                ? c.text3.withValues(alpha: 0.08)
                                : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSettled ? 'Kapatıldı' : label,
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: isSettled ? c.text3 : color),
                          ),
                        ),
                        if (autoDetect) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('AI Tespit',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                    color: _purple)),
                          ),
                        ],
                      ]),
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.text3)),
                      ],
                    ],
                  )),
                ],
              ),
            ),

            // Action buttons (only for active debts)
            if (!isSettled) ...[
              Container(height: 1, color: c.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Row(children: [
                  Expanded(child: _ActionBtn(
                    label: 'Düzenle',
                    icon: Icons.edit_outlined,
                    color: c.text2,
                    onTap: onEdit,
                  )),
                  Container(width: 1, height: 40, color: c.border),
                  Expanded(child: _ActionBtn(
                    label: 'Kapat',
                    icon: Icons.check_circle_outline,
                    color: c.positive,
                    onTap: onSettle,
                  )),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

// ── Empty state ────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final _Filter filter;
  final VoidCallback onAdd;
  const _EmptyState({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (icon, title, sub) = switch (filter) {
      _Filter.active  => (Icons.handshake_outlined, 'Aktif borç yok', 'Harika! Şu an takip edilecek borç bulunmuyor.'),
      _Filter.settled => (Icons.check_circle_outline, 'Kapatılan borç yok', 'Henüz kapatılmış bir borç kaydı yok.'),
      _Filter.all     => (Icons.handshake_outlined, 'Borç kaydı yok', 'Arkadaş ve aile borçlarını takip edin.'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 36, color: AppColors.accent.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text1)),
          const SizedBox(height: 8),
          Text(sub, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.text3, height: 1.5)),
          if (filter != _Filter.settled) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Borç Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: const Color(0xFF051929),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: c.negative, size: 48),
        const SizedBox(height: 12),
        Text('Hata oluştu', style: TextStyle(color: c.text1, fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF051929)),
          child: const Text('Yeniden dene')),
      ]),
    );
  }
}

// ── Debt Form Sheet ────────────────────────────────────────────────────
class _DebtFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _DebtFormSheet({this.existing, required this.onSaved});

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  String _type = 'borrowed';
  bool   _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text   = e['counterparty_name'] as String? ?? '';
      _amountCtrl.text = _d(e['amount']).toStringAsFixed(2);
      _descCtrl.text   = e['description'] as String? ?? '';
      _type = e['type'] as String? ?? 'borrowed';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _amountCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name   = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty) { _snack('Kişi adı gerekli.'); return; }
    if (amount == null || amount <= 0) { _snack('Geçerli tutar girin.'); return; }

    setState(() => _loading = true);
    try {
      final payload = {
        'type': _type, 'counterparty_name': name,
        'amount': amount, 'description': _descCtrl.text.trim(),
      };
      if (_isEdit) {
        final id = _i(widget.existing!['id']);
        await DioClient.instance.patch(ApiEndpoints.personalDebt(id), data: payload);
      } else {
        await DioClient.instance.post(ApiEndpoints.personalDebts, data: payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      _snack(e.response?.data?['message'] ?? 'Kaydedilemedi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: context.appColors.negative));

  InputDecoration _deco(String label, {IconData? icon}) {
    final c = context.appColors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.text3, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: c.text3) : null,
      filled: true, fillColor: c.bg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(_isEdit ? 'Borç Düzenle' : 'Yeni Borç Ekle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text1)),
            const SizedBox(height: 6),
            Text(_isEdit ? 'Borç bilgilerini güncelleyin' : 'Borç veya alacak kaydı oluşturun',
                style: TextStyle(fontSize: 12, color: c.text3)),
            const SizedBox(height: 20),

            // Type selector
            Row(children: [
              _TypePill(label: 'Borçluyum', selected: _type == 'borrowed', color: c.negative,
                  onTap: () => setState(() => _type = 'borrowed')),
              const SizedBox(width: 8),
              _TypePill(label: 'Alacaklıyım', selected: _type == 'lent', color: c.positive,
                  onTap: () => setState(() => _type = 'lent')),
            ]),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameCtrl,
              style: TextStyle(color: c.text1, fontSize: 14),
              decoration: _deco('Kişi Adı', icon: Icons.person_outline),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              style: TextStyle(color: c.text1, fontSize: 14),
              decoration: _deco('Tutar (₺)', icon: Icons.attach_money),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              style: TextStyle(color: c.text1, fontSize: 14),
              decoration: _deco('Açıklama (opsiyonel)', icon: Icons.notes_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, foregroundColor: const Color(0xFF051929),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Güncelle' : 'Kaydet',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypePill({required this.label, required this.selected,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : c.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color.withValues(alpha: 0.45) : c.border),
          ),
          child: Center(child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? color : c.text3))),
        ),
      ),
    );
  }
}

// ── Detection Sheet ────────────────────────────────────────────────────
class _DetectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> debtSuggestions;
  final List<Map<String, dynamic>> repaymentSuggestions;
  final VoidCallback onChanged;
  const _DetectionSheet({required this.debtSuggestions,
      required this.repaymentSuggestions, required this.onChanged});

  @override
  State<_DetectionSheet> createState() => _DetectionSheetState();
}

class _DetectionSheetState extends State<_DetectionSheet> {
  final Set<int> _dDismissed = {};
  final Set<int> _rDismissed = {};

  String _fmt(double v) =>
      '₺${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Future<void> _confirmDebt(int idx) async {
    final s = widget.debtSuggestions[idx];
    try {
      await DioClient.instance.post(ApiEndpoints.personalDebtsConfirm, data: {
        'contact_name':   s['suggested_contact'] ?? 'Bilinmiyor',
        'amount':         s['amount'],
        'direction':      s['direction'],
        'note':           s['description'],
        'transaction_id': s['transaction_id'],
      });
      setState(() => _dDismissed.add(idx));
      widget.onChanged();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Borç kaydedildi.'), backgroundColor: context.appColors.positive));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg ?? 'Borç kaydedilemedi.'), backgroundColor: context.appColors.negative));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Borç kaydedilemedi.'), backgroundColor: context.appColors.negative));
    }
  }

  Future<void> _confirmRepayment(int idx) async {
    final s      = widget.repaymentSuggestions[idx];
    final debtId = _i(s['debt_id']);
    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.personalDebtMarkRepayment(debtId),
        data: {
          'transaction_id':   s['transaction_id'],
          'repayment_amount': s['repayment_amount'],
        },
      );
      setState(() => _rDismissed.add(idx));
      widget.onChanged();
      final profit = _d(res.data['profit']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(profit > 0
            ? '${_fmt(profit)} kar ile borç kapatıldı!'
            : 'Borç kapatıldı.'),
        backgroundColor: profit > 0 ? context.appColors.positive : context.appColors.card,
      ));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg ?? 'Geri ödeme kaydedilemedi.'), backgroundColor: context.appColors.negative));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Geri ödeme kaydedilemedi.'), backgroundColor: context.appColors.negative));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final debts = widget.debtSuggestions.asMap().entries
        .where((e) => !_dDismissed.contains(e.key)).toList();
    final repayments = widget.repaymentSuggestions.asMap().entries
        .where((e) => !_rDismissed.contains(e.key)).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(child: Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),

          Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: _purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome, size: 18, color: _purple)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Borç Tespiti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text1)),
              Text('${debts.length + repayments.length} öneri bulundu',
                  style: TextStyle(fontSize: 11, color: c.text3)),
            ])),
          ]),
          const SizedBox(height: 20),

          if (debts.isNotEmpty) ...[
            Text('Yeni Borç Önerileri',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text3, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            ...debts.map((e) => _SuggestionCard(
              suggestion: e.value,
              isDebt: true,
              onConfirm: () => _confirmDebt(e.key),
              onDismiss: () => setState(() => _dDismissed.add(e.key)),
            )),
            const SizedBox(height: 16),
          ],
          if (repayments.isNotEmpty) ...[
            Text('Geri Ödeme Önerileri',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text3, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            ...repayments.map((e) => _SuggestionCard(
              suggestion: e.value,
              isDebt: false,
              onConfirm: () => _confirmRepayment(e.key),
              onDismiss: () => setState(() => _rDismissed.add(e.key)),
            )),
          ],
          if (debts.isEmpty && repayments.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('Tüm öneriler işlendi.', style: TextStyle(color: c.text3)),
            )),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final bool isDebt;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  const _SuggestionCard({required this.suggestion, required this.isDebt,
      required this.onConfirm, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (isDebt) {
      final amount  = _d(suggestion['amount']);
      final dir     = suggestion['direction'] as String? ?? 'given';
      final color   = dir == 'given' ? c.positive : c.negative;
      final label   = dir == 'given' ? 'Verdiğim borç' : 'Aldığım borç';
      final desc    = suggestion['description'] as String? ?? '';
      final contact = suggestion['suggested_contact'] as String?;

      final source     = suggestion['source'] as String? ?? 'keyword';
      final confidence = suggestion['confidence'] as String? ?? 'high';
      final aiReason   = suggestion['ai_reason'] as String?;

      return _cardWrap(context, color, [
        Row(children: [
          _badge(label, color),
          if (source == 'ai') ...[
            const SizedBox(width: 6),
            _aiBadge(context, confidence),
          ],
          const Spacer(),
          Text('₺${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ]),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: c.text2)),
        ],
        if (contact != null) ...[
          const SizedBox(height: 4),
          Text('Kişi: $contact', style: TextStyle(fontSize: 11, color: c.text3)),
        ],
        if (source == 'ai' && aiReason != null && aiReason.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.auto_awesome, size: 11, color: _purple),
            const SizedBox(width: 4),
            Expanded(child: Text(aiReason, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: _purple))),
          ]),
        ],
        const SizedBox(height: 12),
        _actionRow(context, color, 'Atla', 'Borç Ekle', onDismiss, onConfirm),
      ]);
    } else {
      final debtAmt  = _d(suggestion['debt_amount']);
      final repayAmt = _d(suggestion['repayment_amount']);
      final profit   = _d(suggestion['profit']);
      final contact  = suggestion['debt_contact'] as String? ?? '';
      final desc     = suggestion['description'] as String? ?? '';

      return _cardWrap(context, AppColors.accent, [
        Text('$contact geri ödüyor mu?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text1)),
        const SizedBox(height: 10),
        Row(children: [
          _amountChip(context, 'Borç', debtAmt, c.negative),
          const SizedBox(width: 8),
          _amountChip(context, 'Gelen', repayAmt, c.positive),
          if (profit > 0) ...[
            const SizedBox(width: 8),
            _amountChip(context, 'Kar', profit, c.warning),
          ],
        ]),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c.text3)),
        ],
        const SizedBox(height: 12),
        _actionRow(context, AppColors.accent, 'Hayır', 'Evet, Kapat', onDismiss, onConfirm),
      ]);
    }
  }

  Widget _cardWrap(BuildContext context, Color color, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.appColors.bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _aiBadge(BuildContext context, String confidence) {
    final c = context.appColors;
    final color = confidence == 'high' ? c.positive : c.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: _purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome, size: 9, color: _purple),
        const SizedBox(width: 3),
        Text('AI · ${confidence == 'high' ? 'Yüksek' : 'Orta'}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _purple)),
        const SizedBox(width: 3),
        Container(width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ]),
    );
  }

  Widget _amountChip(BuildContext context, String label, double val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text('₺${val.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(fontSize: 9, color: context.appColors.text3)),
    ]),
  );

  Widget _actionRow(BuildContext context, Color confirmColor, String skipLabel, String confirmLabel,
      VoidCallback onSkip, VoidCallback onConfirm) {
    final c = context.appColors;
    return Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: onSkip,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text3, side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(skipLabel, style: const TextStyle(fontSize: 12)),
      )),
      const SizedBox(width: 8),
      Expanded(child: ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor, foregroundColor: const Color(0xFF051929),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(confirmLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      )),
    ]);
  }
}
