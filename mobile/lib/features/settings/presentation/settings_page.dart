import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/colors.dart';

// ── Providers ─────────────────────────────────────────────────────────
final _settingsStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final results = await Future.wait([
    DioClient.instance.get(ApiEndpoints.dashboard),
    DioClient.instance.get(ApiEndpoints.goals),
    DioClient.instance.get(ApiEndpoints.authMe),
  ]);
  final dash = results[0].data as Map<String, dynamic>;
  final hsObj = dash['health_score'];
  final score = hsObj is Map<String, dynamic>
      ? (hsObj['score'] as num?)?.toInt() ?? 0
      : (dash['summary']?['health_score'] as num?)?.toInt() ?? 0;
  final goalsData = results[1].data;
  int goalCount = 0;
  if (goalsData is List) {
    goalCount = goalsData.length;
  } else if (goalsData is Map<String, dynamic>) {
    final list = (goalsData['goals'] as List?) ?? (goalsData['data'] as List?) ?? [];
    goalCount = list.length;
  }
  int days = 0;
  final meData = results[2].data;
  if (meData is Map<String, dynamic>) {
    final createdAt = meData['user']?['created_at'] as String?;
    if (createdAt != null) {
      try { days = DateTime.now().difference(DateTime.parse(createdAt)).inDays; } catch (_) {}
    }
  }
  return {'score': score, 'goal_count': goalCount, 'days': days};
});

final _securityProvider = FutureProvider.autoDispose<Map<String, bool>>((ref) async {
  final hasPin   = await AuthStorage.hasPin();
  final biometric = await AuthStorage.isBiometricEnabled();
  final notifs   = await AuthStorage.isNotificationsEnabled();
  return {'hasPin': hasPin, 'biometric': biometric, 'notifs': notifs};
});

const _quickActions = [
  (icon: Icons.receipt_long_outlined,   label: 'Fiş çek',   color: Color(0xFF00D4FF), route: '/receipts'),
  (icon: Icons.science_outlined,        label: 'Simüle et', color: Color(0xFFA78BFA), route: '/simulator'),
  (icon: Icons.handshake_outlined,      label: 'Müzakere',  color: Color(0xFFFFB547), route: '/negotiation'),
  (icon: Icons.trending_up,             label: 'Portföy',   color: Color(0xFF6FB1FC), route: '/investments'),
  (icon: Icons.picture_as_pdf_outlined, label: 'Rapor',     color: Color(0xFFF472B6), route: '/reports'),
];

const _modules = [
  (group: 'Bankacılık', items: [
    (id: 'cards',            icon: Icons.credit_card_outlined,           label: 'Kartlar',              sub: 'Kart borçları ve limitler',    route: '/cards'),
    (id: 'loans',            icon: Icons.account_balance_outlined,        label: 'Krediler',             sub: 'Aktif krediler',               route: '/loans'),
    (id: 'bank-connections', icon: Icons.account_balance_wallet_outlined, label: 'Banka Bağlantıları',   sub: 'Bağlı bankalar',               route: '/bank-connections'),
    (id: 'bills',            icon: Icons.bolt_outlined,                   label: 'Faturalar',            sub: 'Fatura takibi',                route: '/bills'),
  ]),
  (group: 'Planlama', items: [
    (id: 'budgets',       icon: Icons.pie_chart_outline,      label: 'Bütçe ve Kategoriler', sub: 'Aylık bütçe limitleri',  route: '/budgets'),
    (id: 'goals',         icon: Icons.flag_outlined,          label: 'Hedefler',             sub: 'Tasarruf hedefleri',     route: '/goals'),
    (id: 'subscriptions', icon: Icons.subscriptions_outlined, label: 'Abonelikler',          sub: 'Tekrarlayan ödemeler',   route: '/subscriptions'),
    (id: 'debts',         icon: Icons.people_outlined,        label: 'Kişisel Borçlar',      sub: 'Borç takibi',            route: '/personal-debts'),
  ]),
  (group: 'Varlık', items: [
    (id: 'investments', icon: Icons.trending_up,              label: 'Yatırım Portföyü',       sub: 'Altın, döviz, kripto, hisse', route: '/investments'),
    (id: 'fx',          icon: Icons.notifications_outlined,   label: 'Kur ve Altın Alarmları', sub: 'Fiyat alarmları',             route: '/fx-alerts'),
    (id: 'inflation',   icon: Icons.show_chart,               label: 'Enflasyon Takibi',       sub: 'Kişisel enflasyon oranı',     route: '/inflation'),
  ]),
  (group: 'Zeka', items: [
    (id: 'simulator',    icon: Icons.science_outlined,              label: 'Karar Simülatörü',    sub: 'Finansal senaryolar',   route: '/simulator'),
    (id: 'health',       icon: Icons.shield_outlined,               label: 'Finansal Sağlık',     sub: 'Detaylı analiz',        route: '/health-score'),
    (id: 'negotiation',  icon: Icons.handshake_outlined,            label: 'Müzakere Mektupları', sub: 'Otomatik müzakere',     route: '/negotiation'),
    (id: 'receipts',     icon: Icons.receipt_long_outlined,         label: 'Fişler',              sub: 'OCR fiş tanıma',        route: '/receipts'),
    (id: 'reports',      icon: Icons.picture_as_pdf_outlined,       label: 'Raporlar',            sub: 'Aylık ve yıllık özetler', route: '/reports'),
  ]),
];

// ── Page ───────────────────────────────────────────────────────────────
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _localAuth = LocalAuthentication();

  // ── Biometric toggle ───────────────────────────────────────────────
  Future<void> _toggleBiometric(bool current) async {
    if (!current) {
      // Enabling: verify first
      try {
        final canAuth = await _localAuth.canCheckBiometrics;
        if (!canAuth) {
          if (mounted) _snack('Bu cihaz biyometrik kimlik doğrulamayı desteklemiyor.', isError: true);
          return;
        }
        final ok = await _localAuth.authenticate(
          localizedReason: 'Biyometrik girişi etkinleştirmek için doğrulayın',
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (!ok) return;
        await AuthStorage.setBiometricEnabled(true);
      } catch (e) {
        if (mounted) _snack('Biyometrik hata: ${e.toString()}', isError: true);
        return;
      }
    } else {
      await AuthStorage.setBiometricEnabled(false);
    }
    if (mounted) {
      _snack(current ? 'Biyometrik giriş kapatıldı.' : 'Biyometrik giriş açıldı.', isError: false);
      ref.invalidate(_securityProvider);
    }
  }

  // ── Notifications toggle ───────────────────────────────────────────
  Future<void> _toggleNotifs(bool current) async {
    await AuthStorage.setNotificationsEnabled(!current);
    if (mounted) {
      _snack(!current ? 'Bildirimler açıldı.' : 'Bildirimler kapatıldı.', isError: false);
      ref.invalidate(_securityProvider);
    }
  }

  // ── PIN management ─────────────────────────────────────────────────
  void _onPinTap(bool hasPin) {
    if (hasPin) {
      _showPinOptions();
    } else {
      context.push('/pin-setup');
    }
  }

  void _showPinOptions() {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('PIN Ayarları',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text1)),
            const SizedBox(height: 20),
            _BottomSheetRow(
              icon: Icons.refresh_outlined,
              label: 'PIN kodunu değiştir',
              onTap: () {
                Navigator.pop(context);
                context.push('/pin-setup', extra: true);
              },
            ),
            _BottomSheetRow(
              icon: Icons.delete_outline,
              label: 'PIN kodunu kaldır',
              danger: true,
              onTap: () async {
                Navigator.pop(context);
                await AuthStorage.clearPin();
                if (mounted) {
                  _snack('PIN kodu kaldırıldı.', isError: false);
                  ref.invalidate(_securityProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Password change ────────────────────────────────────────────────
  void _changePassword() {
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ChangePasswordSheet(
        onChanged: () => _snack('Şifre değiştirildi.', isError: false),
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final c = context.appColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Çıkış Yap',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text1)),
        content: Text('Hesabınızdan çıkmak istiyor musunuz?',
            style: TextStyle(fontSize: 14, color: c.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal', style: TextStyle(color: c.text2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: c.negative,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Çıkış Yap',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try { await DioClient.instance.delete(ApiEndpoints.authLogout); } catch (_) {}
      if (mounted) {
        await ref.read(authProvider.notifier).logout();
        GoRouter.of(context).go('/login');
      }
    }
  }

  void _snack(String msg, {required bool isError}) {
    final c = context.appColors;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? c.negative : c.positive,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final user    = ref.watch(authProvider).user;
    final name    = user?.name ?? 'Kullanıcı';
    final email   = user?.email ?? '';
    final income  = (user?.monthlyIncome ?? 0).toDouble();
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 48),
          children: [
            // ── Profile card ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0D1B2A), Color(0xFF0A1929)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFFC99B5B)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Center(child: Text(
                          initials.isEmpty ? 'U' : initials,
                          style: const TextStyle(fontSize: 20,
                              fontWeight: FontWeight.w700, color: Color(0xFF051929)))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: c.text1)),
                        const SizedBox(height: 2),
                        Text(email, style: TextStyle(
                            fontSize: 11, color: c.text3)),
                        const SizedBox(height: 5),
                        RichText(text: TextSpan(
                          style: TextStyle(fontSize: 11, color: c.text3),
                          children: [
                            const TextSpan(text: 'Gelir: '),
                            TextSpan(text: AppFormatters.currencyCompact(income),
                                style: TextStyle(color: c.text1, fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ],
                    )),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: c.bg, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border)),
                        child: Icon(Icons.edit_outlined, size: 16, color: c.text2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick stats ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: ref.watch(_settingsStatsProvider).when(
                loading: () => Row(children: List.generate(3, (_) => Expanded(
                  child: Container(margin: const EdgeInsets.only(right: 8), height: 60,
                      decoration: BoxDecoration(color: c.card,
                          borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border))),
                ))),
                error: (_, __) => _statsRow('—', '—', '—', c),
                data: (s) => _statsRow(s['score'].toString(), s['goal_count'].toString(), s['days'].toString(), c),
              ),
            ),

            // ── Quick actions ────────────────────────────────────────
            _SectionHeader('Hızlı Erişim'),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _quickActions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final a = _quickActions[i];
                  return GestureDetector(
                    onTap: () => context.push(a.route),
                    child: Container(
                      width: 88,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(color: c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border)),
                      child: Column(children: [
                        Container(width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: a.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(a.icon, size: 18, color: a.color)),
                        const SizedBox(height: 8),
                        Text(a.label, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: c.text2)),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // ── Security ─────────────────────────────────────────────
            _SectionHeader('Güvenlik'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ref.watch(_securityProvider).when(
                loading: () => _cardSkeleton(height: 140, c: c),
                error: (_, __) => const SizedBox(),
                data: (sec) => _SettingsCard(children: [
                  _SwitchRow(
                    icon: Icons.notifications_outlined,
                    label: 'Bildirimler',
                    value: sec['notifs'] ?? true,
                    onChanged: (_) => _toggleNotifs(sec['notifs'] ?? true),
                  ),
                  _SwitchRow(
                    icon: Icons.fingerprint,
                    label: 'Biyometrik giriş',
                    value: sec['biometric'] ?? false,
                    onChanged: (_) => _toggleBiometric(sec['biometric'] ?? false),
                  ),
                  _TileRow(
                    icon: Icons.pin_outlined,
                    label: (sec['hasPin'] ?? false) ? 'PIN kod (aktif)' : 'PIN kod kur',
                    trailing: (sec['hasPin'] ?? false)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: c.positive.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text('Aktif',
                                style: TextStyle(fontSize: 10, color: c.positive, fontWeight: FontWeight.w600)))
                        : null,
                    onTap: () => _onPinTap(sec['hasPin'] ?? false),
                  ),
                ]),
              ),
            ),

            // ── Module groups ────────────────────────────────────────
            ..._modules.map((g) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(g.group),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SettingsCard(
                    children: g.items.map((m) => _TileRow(
                      icon: m.icon,
                      label: m.label,
                      subtitle: m.sub,
                      onTap: () => context.push(m.route),
                    )).toList(),
                  ),
                ),
              ],
            )),

            // ── Appearance ───────────────────────────────────────────
            _SectionHeader('Görünüm'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SettingsCard(children: [
                _SwitchRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Karanlık mod',
                  value: ref.watch(themeModeProvider) == ThemeMode.dark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ]),
            ),

            // ── Account ───────────────────────────────────────────────
            _SectionHeader('Hesap'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SettingsCard(children: [
                _TileRow(
                  icon: Icons.lock_outlined,
                  label: 'Şifre değiştir',
                  onTap: _changePassword,
                ),
                _TileRow(
                  icon: Icons.logout,
                  label: 'Çıkış yap',
                  danger: true,
                  onTap: _logout,
                ),
              ]),
            ),

            // ── Version ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Paranette v1.2 · TEKNOFEST 2026',
                    style: TextStyle(fontSize: 10, color: c.text3.withValues(alpha: 0.6))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(String score, String goals, String days, AppColorTokens c) {
    return Row(children: [
      Expanded(child: _StatChip(value: score, label: 'SKOR', color: AppColors.accent)),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(value: goals, label: 'HEDEF', color: c.text1)),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(value: days, label: 'GÜN', color: c.text1)),
    ]);
  }

  Widget _cardSkeleton({required double height, required AppColorTokens c}) => Container(
    height: height,
    decoration: BoxDecoration(
        color: c.card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border)),
  );
}

// ── Change Password Sheet ─────────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  final VoidCallback onChanged;
  const _ChangePasswordSheet({required this.onChanged});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;

  @override
  void dispose() {
    _currentCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final next    = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || next.isEmpty) {
      _snack('Tüm alanları doldurun.', isError: true); return;
    }
    if (next.length < 8) {
      _snack('Yeni şifre en az 8 karakter olmalı.', isError: true); return;
    }
    if (next != confirm) {
      _snack('Şifreler eşleşmiyor.', isError: true); return;
    }

    setState(() => _loading = true);
    try {
      await DioClient.instance.patch(ApiEndpoints.authPatchMe(), data: {
        'current_password': current,
        'password':         next,
        'password_confirmation': confirm,
      });
      widget.onChanged();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Şifre değiştirilemedi.';
      if (mounted) _snack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    final c = context.appColors;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? c.negative : c.positive,
    ));
  }

  InputDecoration _deco(String label, {required bool obscure, required VoidCallback onToggle, required AppColorTokens c}) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.text3, fontSize: 13),
        filled: true, fillColor: c.bg,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18, color: c.text3),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Şifre Değiştir',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text1)),
          const SizedBox(height: 20),
          TextField(
            controller: _currentCtrl,
            obscureText: _obscure1,
            style: TextStyle(color: c.text1, fontSize: 14),
            decoration: _deco('Mevcut Şifre', c: c,
                obscure: _obscure1, onToggle: () => setState(() => _obscure1 = !_obscure1)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newCtrl,
            obscureText: _obscure2,
            style: TextStyle(color: c.text1, fontSize: 14),
            decoration: _deco('Yeni Şifre', c: c,
                obscure: _obscure2, onToggle: () => setState(() => _obscure2 = !_obscure2)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure3,
            style: TextStyle(color: c.text1, fontSize: 14),
            decoration: _deco('Yeni Şifre (Tekrar)', c: c,
                obscure: _obscure3, onToggle: () => setState(() => _obscure3 = !_obscure3)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: const Color(0xFF051929),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Güncelle', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 20, 10),
      child: Text(title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: c.text3, letterSpacing: 0.6)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
          color: c.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border)),
      child: Column(children: children),
    );
  }
}

class _TileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool danger;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _TileRow({
    required this.icon, required this.label,
    this.subtitle, this.danger = false,
    this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border))),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: danger ? c.negative.withValues(alpha: 0.1) : c.bg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, size: 15, color: danger ? c.negative : c.text2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                  color: danger ? c.negative : c.text1)),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 11, color: c.text3)),
            ],
          )),
          if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
          Icon(Icons.chevron_right, size: 14,
              color: danger ? c.negative.withValues(alpha: 0.5) : c.text3),
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border))),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: c.bg,
              borderRadius: BorderRadius.circular(9), border: Border.all(color: c.border)),
          child: Icon(icon, size: 15, color: c.text2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.text1))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
          activeTrackColor: AppColors.accent.withValues(alpha: 0.25),
          inactiveThumbColor: c.text3,
          inactiveTrackColor: c.border,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: c.card,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w600, color: c.text3, letterSpacing: 0.8)),
      ]),
    );
  }
}

class _BottomSheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;
  const _BottomSheetRow({required this.icon, required this.label,
      this.danger = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ListTile(
      leading: Icon(icon, color: danger ? c.negative : c.text2, size: 20),
      title: Text(label, style: TextStyle(
          fontSize: 14, color: danger ? c.negative : c.text1, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
