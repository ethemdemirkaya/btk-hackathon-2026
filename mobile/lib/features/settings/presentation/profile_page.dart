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
  final _incomeCtrl = TextEditingController();
  bool _savingIncome = false;
  bool _biometric = false;
  bool _notifs = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _incomeCtrl.text = user?.monthlyIncome.toStringAsFixed(0) ?? '';
    _fetchUser();
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    try {
      final res = await DioClient.instance.get(ApiEndpoints.authMe);
      final raw = res.data;
      if (raw is! Map<String, dynamic>) return;
      final userJson = raw['user'] as Map<String, dynamic>?;
      if (userJson == null || !mounted) return;
      final user = UserModel.fromJson(userJson);
      ref.read(authProvider.notifier).setAuthenticated(user);
      if (mounted) {
        setState(() {
          _incomeCtrl.text = user.monthlyIncome.toStringAsFixed(0);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveIncome() async {
    final income = double.tryParse(
        _incomeCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (income == null || income < 0) {
      _snack('Geçerli bir tutar girin.', isError: true);
      return;
    }
    setState(() => _savingIncome = true);
    try {
      await DioClient.instance
          .patch(ApiEndpoints.authPatchMe(), data: {'monthly_income': income});
      if (mounted) _snack('Aylık gelir güncellendi.');
      await _fetchUser();
    } catch (_) {
      if (mounted) _snack('Kayıt başarısız.', isError: true);
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Çıkış yap?',
            style: TextStyle(color: c.text1, fontWeight: FontWeight.w700)),
        content: Text('Hesabınızdan çıkmak istediğinize emin misiniz?',
            style: TextStyle(color: c.text2, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal', style: TextStyle(color: c.text2))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Çıkış yap',
                  style: TextStyle(
                      color: AppColors.negative,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.negative : AppColors.positive,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final user = ref.watch(authProvider).user;
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
        onRefresh: _fetchUser,
        child: CustomScrollView(
          slivers: [
            // ── Hero header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.heroBgFrom, c.heroBgTo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(bottom: BorderSide(color: c.border)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      children: [
                        // top row
                        Row(
                          children: [
                            _IconBtn(
                              icon: Icons.arrow_back_ios_new,
                              onTap: () => Navigator.of(context).canPop()
                                  ? Navigator.of(context).pop()
                                  : context.go('/settings'),
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
                        const SizedBox(height: 24),
                        // avatar
                        _Avatar(initials: initials.isEmpty ? 'P' : initials),
                        const SizedBox(height: 14),
                        Text(name,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: c.text1)),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(email,
                              style: TextStyle(
                                  fontSize: 13, color: c.text3)),
                        ],
                        const SizedBox(height: 16),
                        // stats row
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: c.card.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.border),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _StatCell(
                                label: 'Aylık gelir',
                                value: user != null
                                    ? AppFormatters.currencyCompact(
                                        user.monthlyIncome)
                                    : '—',
                                color: AppColors.accent,
                              ),
                              Container(
                                  width: 1, height: 28, color: c.border),
                              const _StatCell(
                                label: 'Üyelik',
                                value: 'Premium',
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Finansal
                  _SectionLabel('FİNANSAL'),
                  const SizedBox(height: 8),
                  _IncomeCard(
                    controller: _incomeCtrl,
                    saving: _savingIncome,
                    onSave: _saveIncome,
                  ),
                  const SizedBox(height: 20),

                  // Hesap
                  _SectionLabel('HESAP'),
                  const SizedBox(height: 8),
                  _InfoCard(rows: [
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'E-posta',
                        value: email.isEmpty ? '—' : email),
                    _InfoRow(
                        icon: Icons.tag,
                        label: 'Üye No',
                        value: user != null ? '#${user.id}' : '—'),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Telefon',
                        value: (user?.phone ?? '').isEmpty
                            ? '—'
                            : user!.phone!),
                    _InfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Doğum tarihi',
                        value: (user?.birthDate ?? '').isEmpty
                            ? '—'
                            : user!.birthDate!),
                  ]),
                  const SizedBox(height: 20),

                  // Güvenlik
                  _SectionLabel('GÜVENLİK'),
                  const SizedBox(height: 8),
                  _SettingsCard(rows: [
                    _ToggleRow(
                      icon: Icons.fingerprint,
                      label: 'Biyometrik giriş',
                      value: _biometric,
                      onChanged: (v) => setState(() => _biometric = v),
                    ),
                    _TapRow(
                      icon: Icons.lock_outline,
                      label: 'Şifre değiştir',
                      onTap: () => _showPasswordSheet(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Tercihler
                  _SectionLabel('TERCİHLER'),
                  const SizedBox(height: 8),
                  _SettingsCard(rows: [
                    _ToggleRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Koyu tema',
                      value: isDark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    _ToggleRow(
                      icon: Icons.notifications_outlined,
                      label: 'Bildirimler',
                      value: _notifs,
                      onChanged: (v) => setState(() => _notifs = v),
                    ),
                    _TapRow(
                      icon: Icons.language_outlined,
                      label: 'Dil',
                      trailing: Text('Türkçe',
                          style: TextStyle(
                              fontSize: 12, color: context.appColors.text2)),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Uygulama
                  _SectionLabel('UYGULAMA'),
                  const SizedBox(height: 8),
                  _SettingsCard(rows: [
                    _TapRow(
                        icon: Icons.help_outline,
                        label: 'Yardım & Destek',
                        onTap: () {}),
                    _TapRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Gizlilik politikası',
                        onTap: () {}),
                    _TapRow(
                        icon: Icons.description_outlined,
                        label: 'Kullanım koşulları',
                        onTap: () {}),
                  ]),
                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.negative,
                        side: BorderSide(
                            color:
                                AppColors.negative.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Çıkış Yap',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Paranette · v1.0.0',
                        style: TextStyle(fontSize: 11, color: c.text3)),
                  ),
                ]),
              ),
            ),
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

// ── Small widgets ─────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 16, color: c.text2),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.6),
                AppColors.gold.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.bg),
          child: Center(
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent)),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.positive,
              border: Border.all(color: c.bg, width: 2),
            ),
            child:
                const Icon(Icons.check, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCell(
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Text(label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: c.text3,
            letterSpacing: 1.2));
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aylık Gelir',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text1)),
                Text('Bütçe analizleri için temel',
                    style: TextStyle(fontSize: 11, color: c.text3)),
              ],
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text('₺',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
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
                          contentPadding: EdgeInsets.zero,
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
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF051929)))
                    : const Text('Kaydet',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : Border(top: BorderSide(color: c.border)),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(row.icon, size: 15, color: c.text2),
              ),
              const SizedBox(width: 12),
              Text(row.label,
                  style: TextStyle(fontSize: 13, color: c.text2)),
              const Spacer(),
              Text(row.value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.text1)),
            ]),
          );
        }),
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────

class _ToggleRow {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});
}

class _TapRow {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _TapRow(
      {required this.icon,
      required this.label,
      this.onTap,
      this.trailing});
}

class _SettingsCard extends StatelessWidget {
  final List<Object> rows;
  const _SettingsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isFirst = i == 0;
          final borderDeco = isFirst
              ? null
              : Border(top: BorderSide(color: c.border));

          if (row is _ToggleRow) {
            return Container(
              decoration: BoxDecoration(border: borderDeco),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                secondary: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(row.icon, size: 16, color: c.text2),
                ),
                title: Text(row.label,
                    style: TextStyle(fontSize: 13, color: c.text1)),
                value: row.value,
                onChanged: row.onChanged,
                activeThumbColor: AppColors.accent,
                inactiveThumbColor: c.text3,
                inactiveTrackColor: c.border,
              ),
            );
          }

          if (row is _TapRow) {
            return InkWell(
              onTap: row.onTap,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : i == rows.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(16))
                      : BorderRadius.zero,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                decoration: BoxDecoration(border: borderDeco),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(row.icon, size: 16, color: c.text2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(row.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.text1)),
                  ),
                  row.trailing ??
                      Icon(Icons.chevron_right,
                          size: 18, color: c.text3),
                ]),
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ),
    );
  }
}

// ── Password sheet ────────────────────────────────────────────────────

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _curCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _conCtrl = TextEditingController();
  bool _saving = false;
  bool _showCur = false, _showNew = false, _showCon = false;

  @override
  void dispose() {
    _curCtrl.dispose();
    _newCtrl.dispose();
    _conCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cur = _curCtrl.text.trim();
    final next = _newCtrl.text.trim();
    final con = _conCtrl.text.trim();
    if (cur.isEmpty || next.isEmpty || con.isEmpty) {
      _snack('Tüm alanları doldurun.');
      return;
    }
    if (next.length < 8) {
      _snack('Yeni şifre en az 8 karakter.');
      return;
    }
    if (next != con) {
      _snack('Yeni şifreler eşleşmiyor.');
      return;
    }
    setState(() => _saving = true);
    try {
      await DioClient.instance.patch(ApiEndpoints.authPatchMe(), data: {
        'current_password': cur,
        'password': next,
        'password_confirmation': con,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Şifre güncellendi.')));
    } catch (_) {
      _snack('Şifre güncellenemedi.');
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(22)),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Şifre Değiştir',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.text1)),
          const SizedBox(height: 18),
          _PwField(
              ctrl: _curCtrl,
              hint: 'Mevcut şifre',
              show: _showCur,
              onToggle: () => setState(() => _showCur = !_showCur)),
          const SizedBox(height: 10),
          _PwField(
              ctrl: _newCtrl,
              hint: 'Yeni şifre (en az 8 karakter)',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew)),
          const SizedBox(height: 10),
          _PwField(
              ctrl: _conCtrl,
              hint: 'Yeni şifre tekrar',
              show: _showCon,
              onToggle: () => setState(() => _showCon = !_showCon)),
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
                minimumSize: Size.zero,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF051929)))
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
  final TextEditingController ctrl;
  final String hint;
  final bool show;
  final VoidCallback onToggle;
  const _PwField(
      {required this.ctrl,
      required this.hint,
      required this.show,
      required this.onToggle});

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
        controller: ctrl,
        obscureText: !show,
        style: TextStyle(fontSize: 14, color: c.text1),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: c.text3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          isDense: true,
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              show
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: c.text3,
            ),
          ),
        ),
      ),
    );
  }
}
