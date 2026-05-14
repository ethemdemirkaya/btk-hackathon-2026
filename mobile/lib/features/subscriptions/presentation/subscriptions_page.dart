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

// ── Design tokens ────────────────────────────────────────────────────
const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _warning    = Color(0xFFF59E0B);

// ── Provider ─────────────────────────────────────────────────────────
final _subscriptionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.subscriptions);
  return res.data as Map<String, dynamic>;
});

// ── Helpers ───────────────────────────────────────────────────────────
const _cycleLabels = {
  'weekly': 'Haftalık',
  'monthly': 'Aylık',
  'quarterly': '3 Aylık',
  'yearly': 'Yıllık',
};

const _subColors = [
  Color(0xFFE50914),
  Color(0xFF1DB954),
  Color(0xFF0066CC),
  Color(0xFFFF6900),
  Color(0xFF5865F2),
  Color(0xFF00D4FF),
  Color(0xFFA78BFA),
  Color(0xFFFFC857),
];

Future<void> _showAddSubscriptionSheet(
    BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  String billingCycle = 'monthly';
  bool saving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cardBg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
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
                    color: _cardBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              const Expanded(
                  child: Text('Abonelik Ekle',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _text1))),
              IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon:
                      const Icon(Icons.close, color: _text2, size: 20)),
            ]),
            const SizedBox(height: 16),
            _darkField(nameCtrl, 'Abonelik Adı', Icons.subscriptions_outlined),
            const SizedBox(height: 12),
            _darkField(amountCtrl, 'Tutar (₺/ay)', Icons.attach_money,
                prefix: '₺ ',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: billingCycle,
              dropdownColor: _cardBg,
              style: const TextStyle(color: _text1, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Fatura Döngüsü',
                labelStyle: const TextStyle(color: _text3, fontSize: 13),
                filled: true,
                fillColor: _scaffoldBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cardBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cardBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _accent, width: 1.5)),
              ),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                DropdownMenuItem(
                    value: 'quarterly', child: Text('3 Aylık')),
                DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
              ],
              onChanged: (v) => setState(() => billingCycle = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final amount =
                            double.tryParse(amountCtrl.text.trim()) ??
                                0;
                        if (name.isEmpty || amount <= 0) return;
                        setState(() => saving = true);
                        try {
                          await DioClient.instance.post(
                            ApiEndpoints.subscriptions,
                            data: {
                              'name': name,
                              'amount': amount,
                              'billing_cycle': billingCycle,
                            },
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          ref.invalidate(_subscriptionsProvider);
                        } catch (_) {
                          setState(() => saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF051929),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kaydet',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _darkField(
    TextEditingController ctrl, String label, IconData icon,
    {String? prefix, TextInputType? keyboardType}) {
  return TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: const TextStyle(color: _text1, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _text3, fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: _text3),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: _text2),
      filled: true,
      fillColor: _scaffoldBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5)),
    ),
  );
}

// ── Page ──────────────────────────────────────────────────────────────
class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_subscriptionsProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionSheet(context, ref),
        backgroundColor: _accent,
        foregroundColor: const Color(0xFF051929),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            async.when(
              loading: () => _buildHeader('Yükleniyor…'),
              error: (_, __) => _buildHeader(''),
              data: (data) {
                final total =
                    (data['total_monthly'] as num?)?.toDouble() ?? 0;
                return _buildHeader(
                    'Aylık ${AppFormatters.currencyCompact(total)}');
              },
            ),
            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
                onRefresh: () async =>
                    ref.invalidate(_subscriptionsProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_subscriptionsProvider),
                  ),
                  data: (data) {
                    final subs = (data['subscriptions'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    final candidates =
                        (data['candidates'] as List? ?? [])
                            .cast<Map<String, dynamic>>();
                    final totalMonthly =
                        (data['total_monthly'] as num?)?.toDouble() ??
                            0;

                    if (subs.isEmpty && candidates.isEmpty) {
                      return const EmptyState(
                        icon: Icons.subscriptions,
                        title: 'Abonelik bulunamadı',
                        subtitle:
                            'AI, işlemlerinizden abonelikleri otomatik tespit eder.',
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        // ── Hero card ────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _cardBorder),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'AYLIK TOPLAM',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _text3,
                                            letterSpacing: 0.8),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${AppFormatters.currencyCompact(totalMonthly)}',
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: _text1,
                                            letterSpacing: -0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Yıllık ${AppFormatters.currencyCompact(totalMonthly * 12)} · ${subs.length} aktif',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _text3),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: _accent.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(
                                      Icons.subscriptions_outlined,
                                      size: 22,
                                      color: _accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ── Active subs ──────────────────────────
                        if (subs.isNotEmpty) ...[
                          const Padding(
                            padding:
                                EdgeInsets.fromLTRB(20, 24, 20, 10),
                            child: Text('Aktif Abonelikler',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _text3,
                                    letterSpacing: 0.6)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            child: Column(
                              children: subs
                                  .asMap()
                                  .entries
                                  .map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(
                                                bottom: 8),
                                        child: _SubCard(
                                            sub: e.value,
                                            colorIndex: e.key),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                        // ── Candidates ───────────────────────────
                        if (candidates.isNotEmpty) ...[
                          const Padding(
                            padding:
                                EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: Text('Tespit Edilenler',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _text3,
                                    letterSpacing: 0.6)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            child: Column(
                              children: candidates
                                  .map((c) => Padding(
                                        padding:
                                            const EdgeInsets.only(
                                                bottom: 8),
                                        child:
                                            _CandidateCard(candidate: c),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
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

  Widget _buildHeader(String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => shellScaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: const Icon(Icons.menu, size: 18, color: _text2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Abonelikler',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _text1)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: _text3)),
              ],
            ),
          ),
          AiInsightsButton(page: 'subscriptions'),
        ],
      ),
    );
  }
}

// ── Sub card ──────────────────────────────────────────────────────────
class _SubCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final int colorIndex;
  const _SubCard({required this.sub, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final name = sub['name'] as String? ?? 'S';
    final amount =
        (sub['monthly_equivalent'] as num?)?.toDouble() ?? 0;
    final cycle = sub['billing_cycle'] as String? ?? 'monthly';
    final aiDetected = sub['auto_detected'] as bool? ?? false;
    final nextBilling = sub['next_billing_date'] as String?;
    final isCancel = sub['cancel_candidate'] as bool? ?? false;

    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final color = _subColors[colorIndex % _subColors.length];

    return Container(
      padding: const EdgeInsets.all(14),
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _text1)),
                    ),
                    if (aiDetected)
                      const Icon(Icons.auto_awesome,
                          size: 12, color: _accent),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${_cycleLabels[cycle] ?? cycle}${nextBilling != null ? ' · ${AppFormatters.dateShort(DateTime.parse(nextBilling))}' : ''}',
                      style:
                          const TextStyle(fontSize: 11, color: _text3),
                    ),
                    if (isCancel) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _warning.withValues(alpha: 0.3)),
                        ),
                        child: const Text('İptal Adayı',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _warning)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppFormatters.currencyCompact(amount)}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _text1),
              ),
              const Text('/ay',
                  style: TextStyle(fontSize: 11, color: _text3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Candidate card ────────────────────────────────────────────────────
class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final name = candidate['name'] as String? ?? '';
    final amount = (candidate['amount'] as num?)?.toDouble() ?? 0;
    final confidence =
        (candidate['confidence'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 20, color: _accent),
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
                Text(
                  'Olasılık: %${(confidence * 100).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: _text3),
                ),
              ],
            ),
          ),
          Text(
            '${AppFormatters.currencyCompact(amount)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _text1),
          ),
        ],
      ),
    );
  }
}
