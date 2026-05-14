import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
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
const _positive   = Color(0xFF0DD9A0);
const _negative   = Color(0xFFFF4D6D);
const _warning    = Color(0xFFF59E0B);

// ── Providers ─────────────────────────────────────────────────────────
final _fxAlertsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.fxAlerts);
  return res.data as Map<String, dynamic>;
});

final _fxRatesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.fxAlertRates);
  return res.data as Map<String, dynamic>;
});

// ── Constants ─────────────────────────────────────────────────────────
const _currencies = ['USD', 'EUR', 'GBP', 'XAU', 'CHF', 'JPY', 'BTC'];
const _currencyLabels = {
  'USD': 'Amerikan Doları',
  'EUR': 'Euro',
  'GBP': 'İngiliz Sterlini',
  'XAU': 'Altın (gram)',
  'CHF': 'İsviçre Frangı',
  'JPY': 'Japon Yeni',
  'BTC': 'Bitcoin',
};

const _liveRateDisplay = ['USD', 'EUR', 'XAU'];
const _liveRateLabels = {
  'USD': 'USD/TRY',
  'EUR': 'EUR/TRY',
  'XAU': 'ALTIN/g',
};

// ── Page ──────────────────────────────────────────────────────────────
class FxAlertsPage extends ConsumerWidget {
  const FxAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(_fxAlertsProvider);
    final ratesAsync = ref.watch(_fxRatesProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarm(context, ref),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                      child: const Icon(Icons.menu,
                          size: 18, color: _text2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kur Alarmları',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _text1)),
                        Text('Güncel kurlar',
                            style: TextStyle(
                                fontSize: 12, color: _text3)),
                      ],
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: () {
                      ref.invalidate(_fxAlertsProvider);
                      ref.invalidate(_fxRatesProvider);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Icon(Icons.refresh,
                          size: 18, color: _text2),
                    ),
                  ),
                ],
              ),
            ),
            // ── Live rates strip ─────────────────────────────────
            ratesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (rateData) {
                final rates = (rateData['rates']
                        as Map<String, dynamic>?) ??
                    {};
                if (rates.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: _liveRateDisplay.map((sym) {
                      final rate =
                          (rates[sym] as num?)?.toDouble();
                      if (rate == null) {
                        return const Expanded(
                            child: SizedBox.shrink());
                      }
                      final change =
                          (rates['${sym}_change_24h'] as num?)
                              ?.toDouble() ??
                              0;
                      final isUp = change >= 0;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                              right:
                                  sym != _liveRateDisplay.last
                                      ? 8
                                      : 0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                                color: _cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _liveRateLabels[sym] ?? sym,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _text3),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sym == 'XAU'
                                    ? '₺${rate.toStringAsFixed(0)}'
                                    : '₺${rate.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: _text1),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    isUp
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    size: 14,
                                    color: isUp
                                        ? _negative
                                        : _positive,
                                  ),
                                  Text(
                                    '${change.abs().toStringAsFixed(2)}%',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: isUp
                                            ? _negative
                                            : _positive),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            // ── Alerts list ──────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
                onRefresh: () async {
                  ref.invalidate(_fxAlertsProvider);
                  ref.invalidate(_fxRatesProvider);
                },
                child: alertsAsync.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_fxAlertsProvider),
                  ),
                  data: (data) {
                    final alerts =
                        data['alerts'] as List? ?? [];
                    final rates = (ratesAsync.value?['rates']
                            as Map<String, dynamic>?) ??
                        {};

                    if (alerts.isEmpty) {
                      return EmptyState(
                        icon:
                            Icons.notifications_active_outlined,
                        title: 'Alarm bulunamadı',
                        subtitle:
                            'Döviz ve altın için fiyat alarmı oluşturun.',
                        ctaLabel: '+ Alarm Ekle',
                        onCta: () =>
                            _showAddAlarm(context, ref),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          20, 12, 20, 100),
                      itemCount: alerts.length,
                      itemBuilder: (_, i) {
                        final a =
                            alerts[i] as Map<String, dynamic>;
                        return _AlertCard(
                          alert: a,
                          currentRate: (rates[(a['currency']
                                      as String?) ??
                                  ''] as num?)
                              ?.toDouble(),
                          onDelete: () => _deleteAlert(
                              context,
                              ref,
                              (a['id'] as num).toInt()),
                        );
                      },
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

  void _showAddAlarm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddAlertSheet(
        onAdded: () => ref.invalidate(_fxAlertsProvider),
      ),
    );
  }

  Future<void> _deleteAlert(
      BuildContext context, WidgetRef ref, int id) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.fxAlert(id));
      ref.invalidate(_fxAlertsProvider);
    } catch (_) {}
  }
}

// ── Alert card ────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final double? currentRate;
  final VoidCallback onDelete;
  const _AlertCard(
      {required this.alert,
      this.currentRate,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = alert['currency'] as String? ?? '';
    final direction =
        alert['direction'] as String? ?? 'above';
    final targetRate =
        (alert['target_rate'] as num?)?.toDouble() ?? 0;
    final isTriggered =
        alert['is_triggered'] as bool? ?? false;

    final isAbove = direction == 'above';
    final dirColor = isAbove ? _negative : _positive;
    final dirIcon = isAbove
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final dirLabel =
        isAbove ? 'üzerine çıkarsa' : 'altına inerse';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isTriggered
                ? _warning.withValues(alpha: 0.3)
                : _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dirColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(dirIcon, color: dirColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(currency,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _text1)),
                    const SizedBox(width: 6),
                    Text(
                      '₺${targetRate.toStringAsFixed(2)} $dirLabel',
                      style: const TextStyle(
                          fontSize: 12, color: _text2),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _currencyLabels[currency] ?? currency,
                      style: const TextStyle(
                          fontSize: 11, color: _text3),
                    ),
                    if (currentRate != null) ...[
                      const Text(' · ',
                          style: TextStyle(
                              fontSize: 11, color: _text3)),
                      Text(
                        'Şu an: ₺${currentRate!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 11, color: _text3),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isTriggered)
                Container(
                  margin:
                      const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _warning.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Tetiklendi',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _warning)),
                )
              else
                Container(
                  margin:
                      const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Bekliyor',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _accent)),
                ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: _negative),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add alert sheet ───────────────────────────────────────────────────
class _AddAlertSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddAlertSheet({required this.onAdded});

  @override
  State<_AddAlertSheet> createState() => _AddAlertSheetState();
}

class _AddAlertSheetState extends State<_AddAlertSheet> {
  String _currency = 'USD';
  String _direction = 'above';
  final _rateCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rate =
        double.tryParse(_rateCtrl.text.replaceAll(',', '.'));
    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli kur girin')));
      return;
    }
    setState(() => _loading = true);
    try {
      await DioClient.instance.post(ApiEndpoints.fxAlerts,
          data: {
            'currency': _currency,
            'direction': _direction,
            'target_rate': rate,
          });
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Alarm eklenemedi.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _deco(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: _text3, fontSize: 13),
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: _text3) : null,
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
      );

  @override
  Widget build(BuildContext context) {
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
                  color: _cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text('Kur Alarmı Ekle',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _text1)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close,
                    color: _text2, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _currency,
            dropdownColor: _cardBg,
            style: const TextStyle(
                color: _text1, fontSize: 14),
            decoration: _deco('Döviz / Varlık'),
            items: _currencies
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                          '$c — ${_currencyLabels[c] ?? c}'),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _currency = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DirBtn(
                label: 'Üzerine çıkarsa',
                selected: _direction == 'above',
                color: _negative,
                icon: Icons.arrow_upward,
                onTap: () =>
                    setState(() => _direction = 'above'),
              ),
              const SizedBox(width: 8),
              _DirBtn(
                label: 'Altına inerse',
                selected: _direction == 'below',
                color: _positive,
                icon: Icons.arrow_downward,
                onTap: () =>
                    setState(() => _direction = 'below'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rateCtrl,
            style: const TextStyle(
                color: _text1, fontSize: 14),
            decoration: _deco('Hedef Kur (₺)',
                icon: Icons.attach_money),
            keyboardType:
                const TextInputType.numberWithOptions(
                    decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9,.]'))
            ],
            autofocus: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                  : const Icon(
                      Icons.notifications_active_outlined,
                      size: 18),
              label: const Text('Alarm Oluştur',
                  style: TextStyle(
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _DirBtn(
      {required this.label,
      required this.selected,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : _scaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.4)
                    : _cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? color : _text3),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : _text3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
