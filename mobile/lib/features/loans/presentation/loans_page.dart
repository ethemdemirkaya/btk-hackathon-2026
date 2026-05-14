import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
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
const _warning    = Color(0xFFF59E0B);

final _loansProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.loans);
  return res.data as Map<String, dynamic>;
});

const _loanTypeMap = {
  'personal': 'İhtiyaç',
  'mortgage': 'Konut',
  'vehicle': 'Taşıt',
  'commercial': 'Ticari',
};

// Colored circle initial per bank
Color _bankColor(String bankName) {
  const palette = [
    Color(0xFF6FB1FC),
    Color(0xFF2BE0A0),
    Color(0xFFFFC857),
    Color(0xFFA78BFA),
    Color(0xFFFF7E5C),
    Color(0xFF00D4FF),
  ];
  final h =
      bankName.codeUnits.fold(0, (a, b) => a + b);
  return palette[h % palette.length];
}

class LoansPage extends ConsumerWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_loansProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
                title: 'Krediler', subtitle: 'Kredi takibi'),
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
                onRefresh: () async =>
                    ref.invalidate(_loansProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_loansProvider),
                  ),
                  data: (data) {
                    final loans =
                        (data['loans'] as List? ?? [])
                            .cast<Map<String, dynamic>>();
                    final totalBalance =
                        (data['total_balance'] as num?)
                                ?.toDouble() ??
                            0;
                    final monthlyTotal = loans.fold<double>(
                      0,
                      (s, l) =>
                          s +
                          ((l['next_payment_amount'] as num?)
                                  ?.toDouble() ??
                              0),
                    );

                    if (loans.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                            20, 24, 20, 100),
                        children: [
                          EmptyState(
                            icon: Icons.account_balance_outlined,
                            title: 'Kredi bulunamadı',
                            subtitle:
                                'Konut, taşıt veya ihtiyaç kredilerinizi buradan takip edin.',
                            ctaLabel: '+ Kredi Ekle',
                            onCta: () {},
                          ),
                        ],
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 100),
                      children: [
                        // Hero card
                        _HeroCard(
                          totalBalance: totalBalance,
                          loanCount: loans.length,
                          monthlyTotal: monthlyTotal,
                        ),
                        const SizedBox(height: 16),

                        // Loan cards
                        ...loans.map((l) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 12),
                              child: _LoanCard(loan: l),
                            )),

                        // Dashed add button
                        _DashedAddButton(),
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
        ],
      ),
    );
  }
}

// ── Hero Card ────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double totalBalance;
  final int loanCount;
  final double monthlyTotal;
  const _HeroCard({
    required this.totalBalance,
    required this.loanCount,
    required this.monthlyTotal,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text('Toplam kredi borcu',
              style:
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _text3)),
          const SizedBox(height: 6),
          Text(
            '${AppFormatters.currencyCompact(totalBalance)} ₺',
            style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 34,
                color: _text1),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Active loans badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _accent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$loanCount aktif kredi',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _accent),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Aylık ${AppFormatters.currencyCompact(monthlyTotal)} ₺ taksit',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loan Card ────────────────────────────────────────────────────────
class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final type = loan['type'] as String? ?? 'personal';
    final label = _loanTypeMap[type] ?? type;
    final balance =
        (loan['current_balance'] as num?)?.toDouble() ?? 0;
    final rate =
        (loan['interest_rate'] as num?)?.toDouble() ?? 0;
    final bankName = (loan['bank'] as Map?)?['name'] as String? ??
        loan['bank_name'] as String? ??
        '';
    final remaining =
        (loan['remaining_installments'] as num?)?.toInt() ?? 0;
    final total =
        (loan['total_installments'] as num?)?.toInt() ?? 142;
    final nextDate = loan['next_payment_date'] as String?;
    final nextAmount =
        (loan['next_payment_amount'] as num?)?.toDouble() ?? 0;

    final paidCount = (total - remaining).clamp(0, total);
    final progress =
        total > 0 ? paidCount / total : 0.0;

    final initials = bankName.isNotEmpty
        ? bankName.substring(0, bankName.length >= 2 ? 2 : 1).toUpperCase()
        : '??';
    final bankColor = _bankColor(bankName);

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
          // Top row: bank circle + name/type | balance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank logo placeholder (colored circle with initials)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bankColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: bankColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: bankColor),
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
                        Text(bankName.isNotEmpty ? bankName : label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _text1)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                _cardBorder.withValues(alpha: 0.5),
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: Text(label,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _text3)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('%${rate.toStringAsFixed(1)} faiz',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _text3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Outstanding amount (large, bold)
          Text(
            '${AppFormatters.currencyCompact(balance)} ₺',
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02 * 26,
                color: _text1),
          ),
          const SizedBox(height: 4),
          Text(
            '$remaining taksit kaldı · Aylık ${AppFormatters.currencyCompact(nextAmount)} ₺',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _text3),
          ),
          const SizedBox(height: 14),

          // Progress bar (% paid off, green)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor:
                  _positive.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation(_positive),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '%${(progress * 100).toStringAsFixed(0)} ödendi',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _positive),
              ),
              Text(
                '$total taksit',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _text3),
              ),
            ],
          ),

          // Next payment box
          if (nextDate != null || nextAmount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _scaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('SONRAKI TAKSİT',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _text3,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 3),
                      Text(
                        nextDate != null
                            ? AppFormatters.dateFromIso(nextDate)
                            : '—',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _text1),
                      ),
                    ],
                  ),
                  Text(
                    AppFormatters.currencyCompact(nextAmount),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _text1),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionBtn(
                label: 'Simüle et',
                icon: Icons.science_outlined,
                onTap: () => context.push('/simulator'),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Müzakere',
                icon: Icons.mail_outline,
                onTap: () => context.push('/negotiation'),
                ghost: true,
              ),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  size: 16, color: _text3),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Button ────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool ghost;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : _cardBorder,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color:
                  ghost ? _cardBorder : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: ghost ? _text3 : _text2),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ghost ? _text3 : _text2)),
          ],
        ),
      ),
    );
  }
}

// ── Dashed Add Button ────────────────────────────────────────────────
class _DashedAddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(
              color: _cardBorder,
              width: 1.5,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: _text3),
            const SizedBox(width: 8),
            const Text('Yeni kredi ekle',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _text3)),
          ],
        ),
      ),
    );
  }
}
