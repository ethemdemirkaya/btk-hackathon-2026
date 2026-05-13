import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

final _bankConnectionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.bankConnections);
  final data = res.data;
  return data is Map<String, dynamic> ? data : <String, dynamic>{};
});

const _banks = [
  {'id': 'ziraat', 'name': 'Ziraat Bankası', 'type': 'credentials', 'logo': '🏦'},
  {'id': 'isbank', 'name': 'İş Bankası', 'type': 'credentials', 'logo': '🏛️'},
  {'id': 'garanti', 'name': 'Garanti BBVA', 'type': 'oauth', 'logo': '🟢'},
  {'id': 'akbank', 'name': 'Akbank', 'type': 'api_key', 'logo': '🔴'},
  {'id': 'vakifbank', 'name': 'Vakıfbank', 'type': 'credentials', 'logo': '🟡'},
  {'id': 'halkbank', 'name': 'Halkbank', 'type': 'credentials', 'logo': '🔵'},
  {'id': 'denizbank', 'name': 'Denizbank', 'type': 'credentials', 'logo': '💙'},
  {'id': 'ykb', 'name': 'Yapı Kredi', 'type': 'credentials', 'logo': '⭕'},
  {'id': 'qnb', 'name': 'QNB Finansbank', 'type': 'credentials', 'logo': '🟣'},
];

class BankConnectionsPage extends ConsumerWidget {
  const BankConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bankConnectionsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBankSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Banka Ekle'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border1Dark),
                      ),
                      child: const Icon(Icons.menu,
                          size: 18, color: AppColors.text2Dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Banka Bağlantıları',
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: AppColors.text1Dark)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_bankConnectionsProvider),
        child: async.when(
          loading: () => const SkeletonListView(),
          error: (e, __) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_bankConnectionsProvider),
          ),
          data: (data) {
            final connections = data['connections'] as List? ?? [];
            if (connections.isEmpty) {
              return EmptyState(
                icon: Icons.account_balance,
                title: 'Henüz banka bağlantısı yok',
                subtitle:
                    'Bankalarınızı bağlayarak işlemlerinizi otomatik takip edin.',
                ctaLabel: '+ Banka Ekle',
                onCta: () => _showAddBankSheet(context, ref),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: connections.length,
              itemBuilder: (_, i) => _ConnectionCard(
                conn: connections[i] as Map<String, dynamic>,
                onSync: () async {
                  final id = connections[i]['id'] as int;
                  try {
                    await DioClient.instance
                        .post(ApiEndpoints.bankConnectionSync(id));
                    ref.invalidate(_bankConnectionsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Senkronizasyon başlatıldı')),
                      );
                    }
                  } catch (_) {}
                },
                onDelete: () => _confirmDelete(
                    context, ref, connections[i]['id'] as int),
              ),
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

  void _showAddBankSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddBankSheet(
        onAdded: () => ref.refresh(_bankConnectionsProvider),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bağlantıyı Sil'),
        content: const Text(
            'Bu banka bağlantısını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Sil', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await DioClient.instance.delete(ApiEndpoints.bankConnection(id));
        ref.invalidate(_bankConnectionsProvider);
      } catch (_) {}
    }
  }
}

class _ConnectionCard extends StatelessWidget {
  final Map<String, dynamic> conn;
  final VoidCallback onSync;
  final VoidCallback onDelete;
  const _ConnectionCard(
      {required this.conn, required this.onSync, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bank = _banks.firstWhere(
        (b) => b['id'] == conn['bank_slug'],
        orElse: () => {'name': conn['bank_name'] ?? 'Banka', 'logo': '🏦'});
    final isActive = conn['status'] == 'active';
    final lastSynced = conn['last_synced_at'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(bank['logo'] as String,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bank['name'] as String,
                          style: AppTextStyles.titleMedium),
                      Text(
                        lastSynced != null
                            ? 'Son sync: ${AppFormatters.dateFromIso(lastSynced)}'
                            : 'Henüz senkronize edilmedi',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successLight
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Hata',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: isActive ? AppColors.success : AppColors.danger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSync,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Senkronize Et'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBankSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddBankSheet({required this.onAdded});

  @override
  State<_AddBankSheet> createState() => _AddBankSheetState();
}

class _AddBankSheetState extends State<_AddBankSheet> {
  Map<String, dynamic>? _selectedBank;
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _apiKeyCtrl.dispose();
    _clientIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedBank == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final type = _selectedBank!['type'] as String;
      final Map<String, dynamic> payload = {
        'bank_slug': _selectedBank!['id'],
        'bank_name': _selectedBank!['name'],
      };
      if (type == 'credentials') {
        payload['username'] = _usernameCtrl.text.trim();
        payload['password'] = _passwordCtrl.text;
      } else if (type == 'api_key') {
        payload['api_key'] = _apiKeyCtrl.text.trim();
        payload['client_id'] = _clientIdCtrl.text.trim();
      } else if (type == 'oauth') {
        payload['oauth_token'] = _apiKeyCtrl.text.trim();
      }
      await DioClient.instance.post(ApiEndpoints.bankConnections, data: payload);
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Bağlantı kurulamadı.';
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Banka Ekle', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 20),
            if (_selectedBank == null) ...[
              Text('Bankanızı seçin', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              ..._banks.map((b) => ListTile(
                    leading:
                        Text(b['logo'] as String, style: const TextStyle(fontSize: 24)),
                    title: Text(b['name'] as String),
                    subtitle: Text(
                        b['type'] == 'oauth' ? 'OAuth ile bağlan' : 'Kullanıcı adı/şifre'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selectedBank = b),
                  )),
            ] else ...[
              Row(
                children: [
                  Text(_selectedBank!['logo'] as String,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(_selectedBank!['name'] as String,
                      style: AppTextStyles.titleMedium),
                  const Spacer(),
                  TextButton(
                      onPressed: () => setState(() => _selectedBank = null),
                      child: const Text('Değiştir')),
                ],
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: _buildFields(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Bağlan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    final type = _selectedBank!['type'] as String;
    if (type == 'credentials') {
      return Column(
        children: [
          TextFormField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı Adı / TC Kimlik No',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Kullanıcı adı gerekli' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'İnternet Bankacılığı Şifresi',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bilgileriniz şifreli olarak saklanır ve yalnızca bakiye/işlem okuma için kullanılır.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (type == 'api_key') {
      return Column(
        children: [
          TextFormField(
            controller: _apiKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'API Anahtarı',
              prefixIcon: Icon(Icons.key_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'API anahtarı gerekli' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clientIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Client ID',
              prefixIcon: Icon(Icons.fingerprint),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Client ID gerekli' : null,
          ),
        ],
      );
    } else {
      // oauth
      return Column(
        children: [
          TextFormField(
            controller: _apiKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'OAuth Token',
              prefixIcon: Icon(Icons.token_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Token gerekli' : null,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Garanti BBVA için developer.garantibbva.com.tr adresinden OAuth token almanız gerekmektedir.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      );
    }
  }
}
