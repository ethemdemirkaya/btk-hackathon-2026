import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/theme_provider.dart';


class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _incomeCtrl;
  bool _savingIncome = false;
  bool _biometric = false;
  bool _notifs = true;
  UserModel? _lastUser;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _lastUser = user;
    _incomeCtrl = TextEditingController(
        text: user?.monthlyIncome.toStringAsFixed(0) ?? '');
    // Re-fetch in case the user opened profile from cold start without /auth/me
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    try {
      final res = await DioClient.instance.get(ApiEndpoints.authMe);
      final raw = res.data;
      final userJson = (raw is Map<String, dynamic>)
          ? (raw['user'] as Map<String, dynamic>?)
          : null;
      if (userJson == null || !mounted) return;
      final user = UserModel.fromJson(userJson);
      ref.read(authProvider.notifier).setAuthenticated(user);
      if (mounted) {
        setState(() {
          _lastUser = user;
          _incomeCtrl.text = user.monthlyIncome.toStringAsFixed(0);
        });
      }
    } catch (_) {
      // keep cached state — splash already validated the token
    }
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final raw = _incomeCtrl.text.replaceAll(',', '.').replaceAll('.', '').trim();
    final income = double.tryParse(raw);
    if (income == null || income < 0) {
      _snack('Geçerli bir tutar girin.', AppColors.negative);
      return;
    }
    setState(() => _savingIncome = true);
    try {
      await DioClient.instance.patch(
        ApiEndpoints.authPatchMe(),
        data: {'monthly_income': income},
      );
      _snack('Aylık gelir güncellendi.', AppColors.positive);
      await _refreshUser();
    } catch (_) {
      _snack('Kayıt başarısız. Tekrar deneyin.', AppColors.negative);
    } finally {
      if (mounted) setState(() => _savingIncome = false);
    }
  }

  Future<void> _logout() async {
    final c = context.appColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Çıkış yap?',
            style: TextStyle(color: c.text1, fontWeight: FontWeight.w700)),
        content: Text('Hesabınızdan çıkmak istediğinize emin misiniz?',
            style: TextStyle(color: c.text2, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: TextStyle(color: c.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış yap',
                style: TextStyle(color: AppColors.negative, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final user = ref.watch(authProvider).user ?? _lastUser;
    final name = user?.name ?? 'Kullanıcı';
    final email = user?.email ?? '';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: c.card,
        onRefresh: _refreshUser,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroHeader(
              name: name,
              email: email,
              initials: initials.isEmpty ? 'P' : initials,
              monthlyIncome: user?.monthlyIncome ?? 0,
            ),
            const SizedBox(height: 16),
            _SectionLabel('FİNANSAL'),
            _IncomeCard(
              controller: _incomeCtrl,
              saving: _savingIncome,
              onSave: _saveIncome,
            ),
            const SizedBox(height: 20),
            _SectionLabel('HESAP'),
            _AccountCard(user: user, email: email),
            const SizedBox(height: 20),
            _SectionLabel('GÜVENLİK'),
            _SecurityCard(
              biometric: _biometric,
              onBiometric: (v) => setState(() => _biometric = v),
              onChangePassword: () => _showPasswordSheet(context),
            ),
            const SizedBox(height: 20),
            _SectionLabel('TERCİHLER'),
            _PreferencesCard(
              darkMode: isDark,
              notifications: _notifs,
              onDark: (_) => ref.read(themeModeProvider.notifier).toggle(),
              onNotifications: (v) => setState(() => _notifs = v),
            ),
            const SizedBox(height: 20),
            _SectionLabel('UYGULAMA'),
            _AboutCard(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _LogoutButton(onTap: _logout),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text('Paranette · v1.0.0',
                  style: TextStyle(
                      fontSize: 11,
                      color: c.text3,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showPasswordSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PasswordSheet(),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final double monthlyIncome;

  const _HeroHeader({
    required this.name,
    required this.email,
    required this.initials,
    required this.monthlyIncome,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.heroBgFrom, c.heroBgTo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          // Top row: drawer + title + edit (placeholder)
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.card.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: 16, color: c.text2),
                ),
              ),
              const Spacer(),
              Text('Profilim',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.text1)),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 28),
          // Avatar with ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.7),
                      const Color(0xFFC99B5B).withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.bg,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.positive,
                    border: Border.all(color: c.bg, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: c.text1),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? '—' : email,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w400, color: c.text3),
          ),
          const SizedBox(height: 18),
          // Inline stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: c.card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: 'Aylık gelir',
                  value: AppFormatters.currencyCompact(monthlyIncome),
                  color: AppColors.accent,
                ),
                Container(width: 1, height: 28, color: c.border),
                _Stat(
                  label: 'Üyelik',
                  value: 'Premium',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: c.text3,
                letterSpacing: 0.4)),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c.text3,
              letterSpacing: 1.2)),
    );
  }
}

// ── Income card ───────────────────────────────────────────────────────
class _IncomeCard extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  const _IncomeCard(
      {required this.controller,
      required this.saving,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_outlined,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aylık Gelir',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.text1)),
                      const SizedBox(height: 2),
                      Text('Bütçe analizleri için temel',
                          style: TextStyle(fontSize: 11, color: c.text3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Text('₺',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: false),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: c.text1),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(color: c.text3),
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF051929),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Color(0xFF051929)),
                          )
                        : const Text('Kaydet',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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

// ── Account card ──────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final UserModel? user;
  final String email;
  const _AccountCard({required this.user, required this.email});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'E-posta',
              value: email.isEmpty ? '—' : email,
              isFirst: true,
            ),
            _InfoRow(
              icon: Icons.tag,
              label: 'Üye No',
              value: user?.id != null ? '#${user!.id}' : '—',
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telefon',
              value: (user?.phone ?? '').isEmpty ? '—' : user!.phone!,
            ),
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Doğum tarihi',
              value: (user?.birthDate ?? '').isEmpty ? '—' : user!.birthDate!,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: c.text2),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: c.text2)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.text1)),
        ],
      ),
    );
  }
}

// ── Security card ─────────────────────────────────────────────────────
class _SecurityCard extends StatelessWidget {
  final bool biometric;
  final ValueChanged<bool> onBiometric;
  final VoidCallback onChangePassword;

  const _SecurityCard({
    required this.biometric,
    required this.onBiometric,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            _SettingRow(
              icon: Icons.lock_outline,
              label: 'Şifre değiştir',
              trailing: Icon(Icons.chevron_right,
                  size: 18, color: c.text3),
              onTap: onChangePassword,
              isFirst: true,
            ),
            _SettingRow(
              icon: Icons.fingerprint,
              label: 'Biyometrik giriş',
              trailing: Switch(
                value: biometric,
                onChanged: onBiometric,
                activeThumbColor: AppColors.accent,
                inactiveThumbColor: c.text3,
                inactiveTrackColor: c.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Preferences ──────────────────────────────────────────────────────
class _PreferencesCard extends StatelessWidget {
  final bool darkMode;
  final bool notifications;
  final ValueChanged<bool> onDark;
  final ValueChanged<bool> onNotifications;
  const _PreferencesCard({
    required this.darkMode,
    required this.notifications,
    required this.onDark,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            _SettingRow(
              icon: Icons.dark_mode_outlined,
              label: 'Koyu tema',
              trailing: Switch(
                value: darkMode,
                onChanged: onDark,
                activeThumbColor: AppColors.accent,
                inactiveThumbColor: c.text3,
                inactiveTrackColor: c.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              isFirst: true,
            ),
            _SettingRow(
              icon: Icons.notifications_outlined,
              label: 'Bildirimler',
              trailing: Switch(
                value: notifications,
                onChanged: onNotifications,
                activeThumbColor: AppColors.accent,
                inactiveThumbColor: c.text3,
                inactiveTrackColor: c.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            _SettingRow(
              icon: Icons.language_outlined,
              label: 'Dil',
              trailing: Text('Türkçe',
                  style: TextStyle(
                      fontSize: 12,
                      color: c.text2,
                      fontWeight: FontWeight.w500)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            _SettingRow(
              icon: Icons.help_outline,
              label: 'Yardım & Destek',
              trailing: Icon(Icons.chevron_right,
                  size: 18, color: c.text3),
              onTap: () {},
              isFirst: true,
            ),
            _SettingRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Gizlilik politikası',
              trailing: Icon(Icons.chevron_right,
                  size: 18, color: c.text3),
              onTap: () {},
            ),
            _SettingRow(
              icon: Icons.description_outlined,
              label: 'Kullanım koşulları',
              trailing: Icon(Icons.chevron_right,
                  size: 18, color: c.text3),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool isFirst;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: c.text2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.text1)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ── Logout ────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.negative,
          side: BorderSide(color: AppColors.negative.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Çıkış Yap',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Password change sheet ─────────────────────────────────────────────
class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final next = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _snack('Tüm alanları doldurun.');
      return;
    }
    if (next.length < 8) {
      _snack('Yeni şifre en az 8 karakter olmalı.');
      return;
    }
    if (next != confirm) {
      _snack('Yeni şifreler eşleşmiyor.');
      return;
    }

    setState(() => _saving = true);
    try {
      await DioClient.instance.patch(
        ApiEndpoints.authPatchMe(),
        data: {
          'current_password': current,
          'password': next,
          'password_confirmation': confirm,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre güncellendi.')),
      );
    } catch (_) {
      _snack('Şifre güncellenemedi. Mevcut şifreyi kontrol edin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 22 + bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Şifre Değiştir',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.text1)),
          const SizedBox(height: 18),
          _PwField(
            controller: _currentCtrl,
            label: 'Mevcut şifre',
            show: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: 10),
          _PwField(
            controller: _newCtrl,
            label: 'Yeni şifre (en az 8 karakter)',
            show: _showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
          ),
          const SizedBox(height: 10),
          _PwField(
            controller: _confirmCtrl,
            label: 'Yeni şifre tekrar',
            show: _showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF051929),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF051929)),
                    )
                  : const Text('Güncelle',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  const _PwField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: !show,
        style: TextStyle(fontSize: 14, color: c.text1),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(fontSize: 13, color: c.text3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          isDense: true,
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: c.text3,
            ),
          ),
        ),
      ),
    );
  }
}
