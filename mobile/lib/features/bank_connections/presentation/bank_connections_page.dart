import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

// ── Design tokens ────────────────────────────────────────────────────
const _scaffoldBg   = Color(0xFF060D18);
const _cardBg       = Color(0xFF0D1B2A);
const _cardBorder   = Color(0xFF1A2940);
const _accent       = Color(0xFF00D4FF);
const _text1        = Color(0xFFE8F4FF);
const _text2        = Color(0xFF8BA4BC);
const _text3        = Color(0xFF4A6478);
const _positive     = Color(0xFF0DD9A0);
const _negative     = Color(0xFFFF4D6D);

// ── Provider ─────────────────────────────────────────────────────────
final _bankConnectionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.bankConnections);
  final data = res.data;
  return data is Map<String, dynamic> ? data : <String, dynamic>{};
});

// ── Bank catalogue ───────────────────────────────────────────────────
const _banks = [
  {'id': 'ziraat',  'name': 'Ziraat Bankası', 'type': 'credentials', 'color': Color(0xFF0D5922)},
  {'id': 'isbank',  'name': 'İş Bankası',     'type': 'credentials', 'color': Color(0xFF1B3A8C)},
  {'id': 'garanti', 'name': 'Garanti BBVA',   'type': 'oauth',       'color': Color(0xFF006A4E)},
  {'id': 'akbank',  'name': 'Akbank',          'type': 'api_key',     'color': Color(0xFFB71C1C)},
  {'id': 'vakifbank','name': 'Vakıfbank',      'type': 'credentials', 'color': Color(0xFF8B6914)},
  {'id': 'halkbank','name': 'Halkbank',        'type': 'credentials', 'color': Color(0xFF0056A6)},
  {'id': 'denizbank','name': 'Denizbank',      'type': 'credentials', 'color': Color(0xFF00539C)},
  {'id': 'ykb',     'name': 'Yapı Kredi',      'type': 'credentials', 'color': Color(0xFF7B1FA2)},
  {'id': 'qnb',     'name': 'QNB Finansbank',  'type': 'credentials', 'color': Color(0xFF4A148C)},
];

String _initials(String name) {
  final words = name.trim().split(' ');
  if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
  if (name.length >= 2) return name.substring(0, 2).toUpperCase();
  return name.toUpperCase();
}

// ── Page ─────────────────────────────────────────────────────────────
class BankConnectionsPage extends ConsumerWidget {
  const BankConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bankConnectionsProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBankSheet(context, ref),
        backgroundColor: _accent,
        foregroundColor: const Color(0xFF051929),
        elevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Banka Ekle',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            async.when(
              loading: () => _buildHeader('…'),
              error: (_, __) => _buildHeader(''),
              data: (data) {
                final count =
                    (data['connections'] as List? ?? []).length;
                return _buildHeader(
                    '$count hesap bağlı');
              },
            ),
            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                backgroundColor: _cardBg,
                onRefresh: () async =>
                    ref.invalidate(_bankConnectionsProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(_bankConnectionsProvider),
                  ),
                  data: (data) {
                    final connections =
                        data['connections'] as List? ?? [];
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: connections.length,
                      itemBuilder: (_, i) => _ConnectionCard(
                        conn: connections[i] as Map<String, dynamic>,
                        onSync: () async {
                          final id = connections[i]['id'] as int;
                          try {
                            await DioClient.instance.post(
                                ApiEndpoints.bankConnectionSync(id));
                            ref.invalidate(_bankConnectionsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Senkronizasyon başlatıldı')),
                              );
                            }
                          } catch (_) {}
                        },
                        onDelete: () => _confirmDelete(context, ref,
                            connections[i]['id'] as int),
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
                const Text('Banka Bağlantıları',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _text1)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: _text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBankSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
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
        backgroundColor: _cardBg,
        title: const Text('Bağlantıyı Sil',
            style: TextStyle(color: _text1)),
        content: const Text(
            'Bu banka bağlantısını silmek istediğinize emin misiniz?',
            style: TextStyle(color: _text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('İptal', style: TextStyle(color: _text2))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: _negative))),
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

// ── Connection card ───────────────────────────────────────────────────
class _ConnectionCard extends StatelessWidget {
  final Map<String, dynamic> conn;
  final VoidCallback onSync;
  final VoidCallback onDelete;
  const _ConnectionCard(
      {required this.conn, required this.onSync, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bankInfo = _banks.firstWhere(
        (b) => b['id'] == conn['bank_slug'],
        orElse: () => {
              'name': conn['bank_name'] ?? 'Banka',
              'color': _text3,
              'type': 'credentials'
            });
    final bankName = bankInfo['name'] as String;
    final bankColor = bankInfo['color'] as Color;
    final isActive = conn['status'] == 'active';
    final lastSynced = conn['last_synced_at'] as String?;
    final balance = (conn['balance'] as num?)?.toDouble();
    final accountType = conn['account_type'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Bank initials circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bankColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: bankColor.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(
                      _initials(bankName),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: bankColor == _text3
                              ? _text2
                              : Color.lerp(bankColor, Colors.white, 0.6)!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bankName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _text1)),
                      const SizedBox(height: 2),
                      Text(
                        accountType ??
                            (lastSynced != null
                                ? 'Son sync: ${AppFormatters.dateFromIso(lastSynced)}'
                                : 'Henüz senkronize edilmedi'),
                        style: const TextStyle(
                            fontSize: 12, color: _text3),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _positive.withValues(alpha: 0.12)
                        : _negative.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive
                            ? _positive.withValues(alpha: 0.3)
                            : _negative.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 12,
                        color: isActive ? _positive : _negative,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Bağlı' : 'Hata',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? _positive : _negative,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (balance != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _scaffoldBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 14, color: _text3),
                    const SizedBox(width: 6),
                    Text('Bakiye',
                        style: const TextStyle(
                            fontSize: 12, color: _text3)),
                    const Spacer(),
                    Text(
                      '₺ ${AppFormatters.currencyCompact(balance)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _text1),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onSync,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _accent.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync, size: 14, color: _accent),
                          SizedBox(width: 6),
                          Text('Senkronize Et',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _accent)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _negative.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _negative.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: _negative),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add bank sheet ────────────────────────────────────────────────────
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
      await DioClient.instance
          .post(ApiEndpoints.bankConnections, data: payload);
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

  InputDecoration _inputDeco(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _text3, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: _text3)
            : null,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text('Banka Ekle',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _text1)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _text2, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedBank == null) ...[
              const Text('Bankanızı seçin',
                  style: TextStyle(fontSize: 13, color: _text2)),
              const SizedBox(height: 12),
              ..._banks.map((b) {
                final col = b['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBank = b),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _scaffoldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _initials(b['name'] as String),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Color.lerp(col, Colors.white, 0.6)!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['name'] as String,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _text1)),
                              Text(
                                b['type'] == 'oauth'
                                    ? 'OAuth ile bağlan'
                                    : 'Kullanıcı adı / şifre',
                                style: const TextStyle(
                                    fontSize: 11, color: _text3),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: _text3),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (_selectedBank!['color'] as Color)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _initials(_selectedBank!['name'] as String),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color.lerp(
                                _selectedBank!['color'] as Color,
                                Colors.white,
                                0.6)!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_selectedBank!['name'] as String,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _text1)),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedBank = null),
                    child: const Text('Değiştir',
                        style: TextStyle(color: _accent, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Form(key: _formKey, child: _buildFields()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF051929),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Bağlan',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)),
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
            style: const TextStyle(color: _text1),
            decoration: _inputDeco('Kullanıcı Adı / TC Kimlik No',
                icon: Icons.person_outline),
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Kullanıcı adı gerekli'
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: const TextStyle(color: _text1),
            decoration: _inputDeco(
                    'İnternet Bankacılığı Şifresi',
                    icon: Icons.lock_outline)
                .copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: _text3),
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
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined,
                    color: Color(0xFFF59E0B), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bilgileriniz şifreli saklanır ve yalnızca okuma için kullanılır.',
                    style: TextStyle(fontSize: 12, color: _text2),
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
            style: const TextStyle(color: _text1),
            decoration:
                _inputDeco('API Anahtarı', icon: Icons.key_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'API anahtarı gerekli'
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clientIdCtrl,
            style: const TextStyle(color: _text1),
            decoration:
                _inputDeco('Client ID', icon: Icons.fingerprint),
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Client ID gerekli'
                    : null,
          ),
        ],
      );
    } else {
      // oauth
      return Column(
        children: [
          TextFormField(
            controller: _apiKeyCtrl,
            style: const TextStyle(color: _text1),
            decoration:
                _inputDeco('OAuth Token', icon: Icons.token_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Token gerekli' : null,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _accent.withValues(alpha: 0.15)),
            ),
            child: const Text(
              'Garanti BBVA için developer.garantibbva.com.tr adresinden OAuth token almanız gerekmektedir.',
              style: TextStyle(fontSize: 12, color: _text2),
            ),
          ),
        ],
      );
    }
  }
}
