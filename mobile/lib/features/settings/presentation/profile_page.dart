import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../shared/providers/auth_provider.dart';

const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _negative   = Color(0xFFFF4D6D);

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _incomeCtrl;
  bool _savingIncome = false;
  bool _biometricEnabled = false;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _incomeCtrl = TextEditingController(
        text: user?.monthlyIncome.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final raw =
        _incomeCtrl.text.replaceAll(',', '.').trim();
    final income = double.tryParse(raw);
    if (income == null || income < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Geçerli bir tutar girin.')),
      );
      return;
    }
    setState(() => _savingIncome = true);
    try {
      await DioClient.instance.patch(
        ApiEndpoints.authPatchMe(),
        data: {'monthly_income': income},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aylık gelir güncellendi.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Kayıt başarısız. Tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _savingIncome = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Kullanıcı';
    final email = user?.email ?? '';
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.only(bottom: 40),
                children: [
                  // Avatar section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 28, 20, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF00D4FF),
                                Color(0xFFC99B5B)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials.isEmpty
                                  ? 'U'
                                  : initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF051929),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _text1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _text3),
                        ),
                      ],
                    ),
                  ),
                  _SectionLabel(label: 'FİNANSAL BİLGİLER'),
                  _IncomeCard(
                    controller: _incomeCtrl,
                    saving: _savingIncome,
                    onSave: _saveIncome,
                  ),
                  _SectionLabel(label: 'HESAP BİLGİLERİ'),
                  _AccountInfoCard(
                      email: email, user: user),
                  _SectionLabel(label: 'GÜVENLİK'),
                  _SecuritySection(
                    biometricEnabled: _biometricEnabled,
                    onBiometricChanged: (v) =>
                        setState(() => _biometricEnabled = v),
                  ),
                  _SectionLabel(label: 'GÖRÜNÜM'),
                  _AppearanceSection(
                    darkMode: _darkMode,
                    onDarkModeChanged: (v) async {
                      setState(() => _darkMode = v);
                      try {
                        await DioClient.instance.patch(
                          ApiEndpoints.authPatchMe(),
                          data: {
                            'theme': v ? 'dark' : 'light'
                          },
                        );
                      } catch (_) {}
                    },
                  ),
                  const SizedBox(height: 28),
                  _LogoutButton(onLogout: _logout),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                border: Border.all(
                    color: _cardBorder),
              ),
              child: const Icon(Icons.menu,
                  size: 18, color: _text2),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Profilim',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _text1),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _text3,
            letterSpacing: 1.2),
      ),
    );
  }
}

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
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aylık Gelir',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _text3),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _scaffoldBg,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: _cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12),
                          child: Text(
                            '₺',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: _text1),
                            decoration:
                                const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                  color: _text3),
                              contentPadding:
                                  EdgeInsets.symmetric(
                                      vertical: 12),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: saving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor:
                          const Color(0xFF051929),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF051929)),
                          )
                        : const Text('Kaydet',
                            style: TextStyle(
                                fontWeight:
                                    FontWeight.w700)),
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

class _AccountInfoCard extends StatelessWidget {
  final String email;
  final dynamic user;
  const _AccountInfoCard(
      {required this.email, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _cardBorder),
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
              value: user?.id != null
                  ? '#${user!.id}'
                  : '—',
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
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(
                top: BorderSide(
                    color: _cardBorder)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: _text3),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _text2)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _text1)),
        ],
      ),
    );
  }
}

class _SecuritySection extends StatelessWidget {
  final bool biometricEnabled;
  final ValueChanged<bool> onBiometricChanged;
  const _SecuritySection(
      {required this.biometricEnabled,
      required this.onBiometricChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            _TappableRow(
              icon: Icons.lock_outline,
              label: 'Şifreyi Değiştir',
              isFirst: true,
              onTap: () => _showPasswordChange(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: _cardBorder)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint,
                      size: 16, color: _text3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: const Text('Biyometrik Giriş',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _text2)),
                  ),
                  Switch(
                    value: biometricEnabled,
                    onChanged: onBiometricChanged,
                    activeThumbColor: _accent,
                    inactiveThumbColor: _text3,
                    inactiveTrackColor: _cardBorder,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showPasswordChange(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PasswordChangeSheet(),
  );
}

class _PasswordChangeSheet extends StatefulWidget {
  const _PasswordChangeSheet();

  @override
  State<_PasswordChangeSheet> createState() => _PasswordChangeSheetState();
}

class _PasswordChangeSheetState extends State<_PasswordChangeSheet> {
  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _saving        = false;
  bool _showCurrent   = false;
  bool _showNew       = false;
  bool _showConfirm   = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final next    = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tüm alanları doldurun.')));
      return;
    }
    if (next.length < 8) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Yeni şifre en az 8 karakter olmalı.')));
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Yeni şifreler eşleşmiyor.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await DioClient.instance.patch(
        ApiEndpoints.authPatchMe(),
        data: {
          'current_password':      current,
          'password':              next,
          'password_confirmation': confirm,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Şifre başarıyla güncellendi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Şifre güncellenemedi. Mevcut şifrenizi kontrol edin.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Şifre Değiştir',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _text1)),
          const SizedBox(height: 20),
          _PwField(
            controller: _currentCtrl,
            label: 'Mevcut şifre',
            show: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: 12),
          _PwField(
            controller: _newCtrl,
            label: 'Yeni şifre (en az 8 karakter)',
            show: _showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
          ),
          const SizedBox(height: 12),
          _PwField(
            controller: _confirmCtrl,
            label: 'Yeni şifre tekrar',
            show: _showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: const Color(0xFF051929),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
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
    return Container(
      decoration: BoxDecoration(
        color: _scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: !show,
        style: const TextStyle(fontSize: 14, color: _text1),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintText: label,
          hintStyle: const TextStyle(fontSize: 13, color: _text3),
          isDense: true,
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: _text3,
            ),
          ),
        ),
      ),
    );
  }
}

class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  const _TappableRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(
                  top: BorderSide(
                      color: _cardBorder)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: _text3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _text2)),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: _text3),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  const _AppearanceSection(
      {required this.darkMode,
      required this.onDarkModeChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.dark_mode_outlined,
                size: 16, color: _text3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                darkMode ? 'Koyu Tema' : 'Açık Tema',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _text2),
              ),
            ),
            Switch(
              value: darkMode,
              onChanged: onDarkModeChanged,
              activeThumbColor: _accent,
              inactiveThumbColor: _text3,
              inactiveTrackColor: _cardBorder,
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onLogout,
          icon:
              const Icon(Icons.logout, size: 18),
          label: const Text('Çıkış Yap',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _negative,
            side: BorderSide(
                color: _negative.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
