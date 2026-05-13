import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

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

class FxAlertsPage extends ConsumerWidget {
  const FxAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(_fxAlertsProvider);
    final ratesAsync = ref.watch(_fxRatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kur & Altın Alarmları')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(_fxAlertsProvider);
          ref.refresh(_fxRatesProvider);
        },
        child: alertsAsync.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.refresh(_fxAlertsProvider),
          ),
          data: (data) {
            final alerts = data['alerts'] as List? ?? [];
            final rates = (ratesAsync.value?['rates'] as Map<String, dynamic>?) ?? {};

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live rates ticker
                if (rates.isNotEmpty) ...[
                  _RatesTicker(rates: rates),
                  const SizedBox(height: 16),
                ],
                if (alerts.isEmpty)
                  EmptyState(
                    icon: Icons.notifications_active_outlined,
                    title: 'Alarm bulunamadı',
                    subtitle: 'Döviz ve altın için fiyat alarmı oluşturun.',
                    ctaLabel: '+ Alarm Ekle',
                    onCta: () => _showAddAlarm(context, ref),
                  )
                else
                  ...alerts.map((a) => _AlertCard(
                        alert: a as Map<String, dynamic>,
                        currentRate: (rates[(a['currency'] as String?) ?? ''] as num?)
                            ?.toDouble(),
                        onDelete: () => _deleteAlert(
                            context, ref, (a['id'] as num).toInt()),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddAlarm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddAlertSheet(
        onAdded: () => ref.refresh(_fxAlertsProvider),
      ),
    );
  }

  Future<void> _deleteAlert(
      BuildContext context, WidgetRef ref, int id) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.fxAlert(id));
      ref.refresh(_fxAlertsProvider);
    } catch (_) {}
  }
}

class _RatesTicker extends StatelessWidget {
  final Map<String, dynamic> rates;
  const _RatesTicker({required this.rates});

  @override
  Widget build(BuildContext context) {
    final displayOrder = ['USD', 'EUR', 'GBP', 'XAU', 'BTC'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Anlık Kurlar',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: displayOrder.map((cur) {
              final rate = (rates[cur] as num?)?.toDouble();
              if (rate == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cur,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                  Text(
                    cur == 'XAU'
                        ? '₺${rate.toStringAsFixed(0)}'
                        : '₺${rate.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final double? currentRate;
  final VoidCallback onDelete;
  const _AlertCard(
      {required this.alert, this.currentRate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = alert['currency'] as String? ?? '';
    final direction = alert['direction'] as String? ?? 'above';
    final targetRate = (alert['target_rate'] as num?)?.toDouble() ?? 0;
    final isTriggered = alert['is_triggered'] as bool? ?? false;

    final directionIcon =
        direction == 'above' ? Icons.arrow_upward : Icons.arrow_downward;
    final directionColor =
        direction == 'above' ? AppColors.danger : AppColors.success;
    final directionLabel = direction == 'above' ? 'üzerine çıkarsa' : 'altına inerse';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: directionColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(directionIcon, color: directionColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currency — ₺${targetRate.toStringAsFixed(2)} $directionLabel',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    _currencyLabels[currency] ?? currency,
                    style: AppTextStyles.bodySmall,
                  ),
                  if (currentRate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mevcut: ₺${currentRate!.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ],
              ),
            ),
            if (isTriggered)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Tetiklendi',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.warning)),
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final rate = double.tryParse(_rateCtrl.text.replaceAll(',', '.'));
    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Geçerli kur girin')));
      return;
    }
    setState(() => _loading = true);
    try {
      await DioClient.instance.post(ApiEndpoints.fxAlerts, data: {
        'currency': _currency,
        'direction': _direction,
        'target_rate': rate,
      });
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Alarm eklenemedi.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kur Alarmı Ekle', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: const InputDecoration(labelText: 'Döviz / Varlık'),
            items: _currencies
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('$c — ${_currencyLabels[c] ?? c}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _currency = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Üzerine çıkarsa'),
                  value: 'above',
                  groupValue: _direction,
                  onChanged: (v) => setState(() => _direction = v!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Altına inerse'),
                  value: 'below',
                  groupValue: _direction,
                  onChanged: (v) => setState(() => _direction = v!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rateCtrl,
            decoration: const InputDecoration(
              labelText: 'Hedef Kur (₺)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
            ],
            autofocus: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.notifications_active_outlined),
              label: const Text('Alarm Oluştur'),
            ),
          ),
        ],
      ),
    );
  }
}
