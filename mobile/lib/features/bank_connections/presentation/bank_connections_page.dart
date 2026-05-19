import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

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

// Maps bank ID → SVG asset filename (some IDs differ from file names)
const _bankSvgSlug = {
  'ykb': 'yapikredi',
};
String _svgPath(String bankId) {
  final slug = _bankSvgSlug[bankId] ?? bankId;
  return 'assets/banks/$slug.svg';
}

// ── Page ─────────────────────────────────────────────────────────────
class BankConnectionsPage extends ConsumerWidget {
  const BankConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final async = ref.watch(_bankConnectionsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBankSheet(context, ref),
        backgroundColor: AppColors.accent,
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
              loading: () => _buildHeader(context, '…'),
              error: (_, __) => _buildHeader(context, ''),
              data: (data) {
                final count =
                    (data['connections'] as List? ?? []).length;
                return _buildHeader(context, '$count hesap bağlı');
              },
            ),
            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: c.card,
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
                                        Text('Senkronizasyon tamamlandı')),
                              );
                            }
                          } on DioException catch (e) {
                            if (context.mounted) {
                              final msg = e.response?.data?['message']
                                  ?? 'Senkronizasyon başarısız.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: ${e.toString()}'),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
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

  Widget _buildHeader(BuildContext context, String subtitle) {
    final c = context.appColors;
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
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.menu, size: 18, color: c.text2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Banka Bağlantıları',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.text1)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: c.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBankSheet(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
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
    final c = context.appColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Bağlantıyı Sil',
            style: TextStyle(color: c.text1)),
        content: Text(
            'Bu banka bağlantısını silmek istediğinize emin misiniz?',
            style: TextStyle(color: c.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal', style: TextStyle(color: c.text2))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sil',
                  style: TextStyle(color: c.negative))),
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
    final c = context.appColors;
    // API returns connection.bank.{slug,name,...} and connection.accounts[...]
    final bankNode = conn['bank'];
    final String? bankSlug = bankNode is Map ? bankNode['slug']?.toString() : conn['bank_slug']?.toString();
    final String? apiBankName = bankNode is Map ? bankNode['name']?.toString() : conn['bank_name']?.toString();
    final accounts = (conn['accounts'] as List?) ?? const [];
    final firstAccount = accounts.isNotEmpty && accounts.first is Map
        ? accounts.first as Map
        : null;

    final bankInfo = _banks.firstWhere(
        (b) => b['id'] == bankSlug,
        orElse: () => {
              'id': bankSlug ?? '',
              'name': apiBankName ?? 'Banka',
              'color': const Color(0xFF4A6478),
              'type': 'credentials'
            });
    final bankName = bankInfo['name'] as String;
    final bankColor = bankInfo['color'] as Color;
    final isActive = conn['status'] == 'active' || conn['status'] == 'connected';
    final lastSynced = (conn['last_sync_at'] ?? conn['last_synced_at']) as String?;
    final double? balance = firstAccount != null && firstAccount['balance'] is num
        ? (firstAccount['balance'] as num).toDouble()
        : (conn['balance'] as num?)?.toDouble();
    final accountType = firstAccount?['type']?.toString()
        ?? firstAccount?['account_type']?.toString()
        ?? conn['account_type']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Bank logo circle
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
                    child: SvgPicture.asset(
                      _svgPath(bankInfo['id'] as String? ?? ''),
                      width: 26,
                      height: 26,
                      placeholderBuilder: (_) => Text(
                        _initials(bankName),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: bankColor == const Color(0xFF4A6478)
                                ? c.text2
                                : Color.lerp(bankColor, Colors.white, 0.6)!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bankName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.text1)),
                      const SizedBox(height: 2),
                      Text(
                        accountType ??
                            (lastSynced != null
                                ? 'Son sync: ${AppFormatters.dateFromIso(lastSynced)}'
                                : 'Henüz senkronize edilmedi'),
                        style: TextStyle(
                            fontSize: 12, color: c.text3),
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
                        ? c.positive.withValues(alpha: 0.12)
                        : c.negative.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive
                            ? c.positive.withValues(alpha: 0.3)
                            : c.negative.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 12,
                        color: isActive ? c.positive : c.negative,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Bağlı' : 'Hata',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? c.positive : c.negative,
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
                  color: c.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 14, color: c.text3),
                    const SizedBox(width: 6),
                    Text('Bakiye',
                        style: TextStyle(
                            fontSize: 12, color: c.text3)),
                    const Spacer(),
                    Text(
                      AppFormatters.currencyCompact(balance),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.text1),
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
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync, size: 14, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text('Senkronize Et',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent)),
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
                      color: c.negative.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: c.negative.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.delete_outline,
                        size: 16, color: c.negative),
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
      final bankId = _selectedBank!['id'] as String;
      final Map<String, dynamic> credentials = {};
      if (type == 'credentials') {
        credentials['tckn'] = _usernameCtrl.text.trim();
        if (bankId == 'isbank') {
          credentials['hmac_secret'] = _passwordCtrl.text;
        } else {
          credentials['password'] = _passwordCtrl.text;
        }
      } else if (type == 'api_key') {
        credentials['api_key'] = _apiKeyCtrl.text.trim();
      } else if (type == 'oauth') {
        // Garanti: client_id (TCKN) + client_secret
        credentials['client_id'] = _usernameCtrl.text.trim();
        credentials['client_secret'] = _passwordCtrl.text;
      }
      final payload = <String, dynamic>{
        'bank_slug': _selectedBank!['id'],
        'credentials': credentials,
      };
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

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    final c = context.appColors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.text3, fontSize: 13),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: c.text3)
          : null,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Banka Ekle',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.text1)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: c.text2, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedBank == null) ...[
              Text('Bankanızı seçin',
                  style: TextStyle(fontSize: 13, color: c.text2)),
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
                      color: c.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border),
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
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: c.text1)),
                              Text(
                                b['type'] == 'oauth'
                                    ? 'OAuth ile bağlan'
                                    : 'Kullanıcı adı / şifre',
                                style: TextStyle(
                                    fontSize: 11, color: c.text3),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: c.text3),
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
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.text1)),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedBank = null),
                    child: const Text('Değiştir',
                        style: TextStyle(color: AppColors.accent, fontSize: 13)),
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
                    backgroundColor: AppColors.accent,
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
    final c = context.appColors;
    final type = _selectedBank!['type'] as String;
    final bankId = _selectedBank!['id'] as String;

    // Shared security notice
    Widget securityNote(String text) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: c.text2))),
      ]),
    );

    if (type == 'api_key') {
      // Akbank — only API key needed
      return TextFormField(
        controller: _apiKeyCtrl,
        style: TextStyle(color: c.text1),
        decoration: _inputDeco('API Anahtarı', icon: Icons.key_outlined),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'API anahtarı gerekli' : null,
      );
    }

    if (type == 'oauth') {
      // Garanti BBVA — client_id (TCKN) + client_secret
      return Column(children: [
        TextFormField(
          controller: _usernameCtrl,
          style: TextStyle(color: c.text1),
          decoration: _inputDeco('TCKN / Client ID', icon: Icons.person_outline),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Client ID gerekli' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: TextStyle(color: c.text1),
          decoration: _inputDeco('Client Secret', icon: Icons.vpn_key_outlined)
              .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: c.text3),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Client secret gerekli' : null,
        ),
        const SizedBox(height: 12),
        securityNote(
            'Bilgileriniz şifreli saklanır ve yalnızca okuma için kullanılır.'),
      ]);
    }

    // credentials type — Ziraat, İşbank, diğerleri
    final secondLabel = bankId == 'isbank'
        ? 'HMAC Secret Anahtarı'
        : 'İnternet Bankacılığı Şifresi';

    return Column(children: [
      TextFormField(
        controller: _usernameCtrl,
        style: TextStyle(color: c.text1),
        decoration:
            _inputDeco('TCKN / TC Kimlik No', icon: Icons.person_outline),
        keyboardType: TextInputType.number,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'TCKN gerekli' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        style: TextStyle(color: c.text1),
        decoration:
            _inputDeco(secondLabel, icon: Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: c.text3),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Bu alan zorunlu' : null,
      ),
      const SizedBox(height: 12),
      securityNote(
          'Bilgileriniz şifreli saklanır ve yalnızca okuma için kullanılır.'),
    ]);
  }
}
