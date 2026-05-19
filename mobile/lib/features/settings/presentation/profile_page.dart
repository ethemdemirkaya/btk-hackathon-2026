import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/auth_storage.dart';
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
  final _localAuth = LocalAuthentication();
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
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final bio = await AuthStorage.isBiometricEnabled();
    final notifs = await AuthStorage.isNotificationsEnabled();
    if (mounted) setState(() { _biometric = bio; _notifs = notifs; });
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (!enable) {
      setState(() => _biometric = false);
      AuthStorage.setBiometricEnabled(false);
      return;
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final devices = await _localAuth.getAvailableBiometrics();
      if (!canCheck || devices.isEmpty) {
        _snack('Cihazınızda biyometrik sensör bulunamadı.', isError: true);
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Biyometrik girişi etkinleştirmek için doğrulayın',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok && mounted) {
        setState(() => _biometric = true);
        AuthStorage.setBiometricEnabled(true);
      }
    } on PlatformException catch (e) {
      if (mounted) _snack('Biyometrik kullanılamıyor: ${e.message ?? e.code}', isError: true);
    }
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
                            _IconBtn(
                              icon: Icons.edit_outlined,
                              onTap: () => _showEditSheet(context),
                            ),
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
                      onChanged: _toggleBiometric,
                    ),
                    _TapRow(
                      icon: Icons.dialpad_outlined,
                      label: 'PIN Değiştir',
                      onTap: () => context.push('/pin-setup', extra: true),
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
                      onChanged: (v) {
                        setState(() => _notifs = v);
                        AuthStorage.setNotificationsEnabled(v);
                      },
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
                        onTap: () => _showInfoSheet(
                              context,
                              title: 'Yardım & Destek',
                              icon: Icons.help_outline,
                              iconColor: AppColors.accent,
                              sections: const [
                                _InfoBlock(
                                  heading: 'SIKÇA SORULAN SORULAR',
                                  body: 'Banka hesabımı nasıl bağlarım?\n'
                                      'Banka Bağlantıları sayfasından bankanızı seçip demo bağlantı kurabilirsiniz.\n\n'
                                      'AI ajanları nasıl çalışır?\n'
                                      'Gemini 2.5 Pro modeli finansal verilerinizi analiz ederek kişiselleştirilmiş öneriler sunar.\n\n'
                                      'Verilerim güvende mi?\n'
                                      'Hassas veriler flutter_secure_storage ile şifrelenir; hiçbir veri üçüncü taraflarla paylaşılmaz.\n\n'
                                      'Bildirimler gelmiyor?\n'
                                      'Profil › Bildirimler ayarını ve telefon bildirim izinlerini kontrol edin.',
                                ),
                                _InfoBlock(heading: 'İLETİŞİM', body: ''),
                                _InfoContact(
                                  icon: Icons.email_outlined,
                                  label: 'E-posta',
                                  value: 'support@paranette.app',
                                ),
                                _InfoContact(
                                  icon: Icons.code_outlined,
                                  label: 'GitHub',
                                  value: 'github.com/ethemdemirkaya/btk-hackathon-2026',
                                ),
                              ],
                            )),
                    _TapRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Gizlilik Politikası',
                        onTap: () => _showInfoSheet(
                              context,
                              title: 'Gizlilik Politikası',
                              icon: Icons.privacy_tip_outlined,
                              iconColor: const Color(0xFF28C76F),
                              sections: const [
                                _InfoBlock(
                                  heading: 'SON GÜNCELLEME',
                                  body: 'Mayıs 2026',
                                ),
                                _InfoBlock(
                                  heading: '1. TOPLANAN VERİLER',
                                  body: 'Finansal işlemleriniz, bütçe hedefleriniz ve uygulama tercihleri yerel cihazınızda saklanır. '
                                      'API sunucumuz yalnızca kimlik doğrulama ve senkronizasyon için gerekli yapılandırılmış verileri işler.',
                                ),
                                _InfoBlock(
                                  heading: '2. VERİ KULLANIMI',
                                  body: 'Verileriniz AI ajan analizleri ve kişisel finans önerileri üretmek amacıyla kullanılır. '
                                      'Verileriniz hiçbir üçüncü tarafa satılmaz veya ticari amaçla paylaşılmaz.',
                                ),
                                _InfoBlock(
                                  heading: '3. GÜVENLİK',
                                  body: 'Hassas veriler flutter_secure_storage ile AES şifreleme kullanılarak korunur. '
                                      'Sunucu ile tüm iletişim HTTPS/TLS üzerinden gerçekleştirilir. PIN ve biyometrik doğrulama zorunludur.',
                                ),
                                _InfoBlock(
                                  heading: '4. ÜÇÜNCÜ TARAF HİZMETLER',
                                  body: '• Google Gemini API — AI analizleri (Google Gizlilik Politikası geçerlidir)\n'
                                      '• Yahoo Finance — Döviz kuru ve piyasa verileri\n'
                                      'Bu hizmetlerin kendi gizlilik politikaları mevcuttur.',
                                ),
                                _InfoBlock(
                                  heading: '5. İLETİŞİM',
                                  body: 'Gizlilikle ilgili sorularınız için: privacy@paranette.app',
                                ),
                              ],
                            )),
                    _TapRow(
                        icon: Icons.description_outlined,
                        label: 'Kullanım Koşulları',
                        onTap: () => _showInfoSheet(
                              context,
                              title: 'Kullanım Koşulları',
                              icon: Icons.description_outlined,
                              iconColor: const Color(0xFFFF9F43),
                              sections: const [
                                _InfoBlock(
                                  heading: 'SON GÜNCELLEME',
                                  body: 'Mayıs 2026',
                                ),
                                _InfoBlock(
                                  heading: '1. KABUL EDİLEN KULLANIM',
                                  body: 'Paranette yalnızca kişisel finans yönetimi amacıyla kullanılabilir. '
                                      'Uygulamayı ticari, yasadışı veya zararlı amaçlarla kullanamazsınız.',
                                ),
                                _InfoBlock(
                                  heading: '2. HESAP GÜVENLİĞİ',
                                  body: 'PIN kodunuzu ve biyometrik kimlik doğrulama ayarlarınızı güvende tutmak tamamen sizin sorumluluğunuzdadır. '
                                      'Şüpheli bir erişim fark ederseniz derhal şifrenizi değiştirin.',
                                ),
                                _InfoBlock(
                                  heading: '3. SORUMLULUK REDDİ',
                                  body: 'Paranette finansal tavsiye vermez. Uygulama içindeki AI önerileri bilgi amaçlıdır; '
                                      'tüm yatırım ve finansal kararlar kullanıcının kendi sorumluluğundadır.',
                                ),
                                _InfoBlock(
                                  heading: '4. FİKRİ MÜLKİYET',
                                  body: 'Uygulama, tasarım ve içerikler BTK Akademi Hackathon 2026 projesi kapsamında geliştirilmiş olup '
                                      'tüm hakları Paranette ekibine aittir.',
                                ),
                                _InfoBlock(
                                  heading: '5. DEĞİŞİKLİKLER',
                                  body: 'Bu koşullar önceden bildirim yapılmaksızın güncellenebilir. '
                                      'Uygulamayı kullanmaya devam etmeniz güncel koşulları kabul ettiğiniz anlamına gelir.\n\n'
                                      'İletişim: legal@paranette.app',
                                ),
                              ],
                            )),
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

  void _showEditSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: ref.read(authProvider).user,
        onSaved: _fetchUser,
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
                  color: Colors.transparent,
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
                          filled: true,
                          fillColor: Colors.transparent,
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
  final void Function(bool) onChanged;
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

// ── Edit profile sheet ────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel? user;
  final VoidCallback onSaved;
  const _EditProfileSheet({required this.user, required this.onSaved});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _birthCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    _birthCtrl = TextEditingController(text: widget.user?.birthDate ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial;
    try {
      initial = _birthCtrl.text.isNotEmpty
          ? DateTime.parse(_birthCtrl.text)
          : DateTime(1990);
    } catch (_) {
      initial = DateTime(1990);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final y = picked.year.toString();
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() => _birthCtrl.text = '$y-$m-$d');
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Ad soyad boş bırakılamaz.'); return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{'name': name};
      final phone = _phoneCtrl.text.trim();
      final birth = _birthCtrl.text.trim();
      if (phone.isNotEmpty) data['phone'] = phone;
      if (birth.isNotEmpty) data['birth_date'] = birth;
      await DioClient.instance.patch(ApiEndpoints.authPatchMe(), data: data);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (_) {
      _snack('Güncelleme başarısız.');
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
              width: 38, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                  color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Profili Düzenle',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: c.text1)),
          const SizedBox(height: 18),
          _SheetField(ctrl: _nameCtrl, hint: 'Ad Soyad', icon: Icons.person_outline),
          const SizedBox(height: 10),
          _SheetField(ctrl: _phoneCtrl, hint: 'Telefon', icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: _SheetField(ctrl: _birthCtrl, hint: 'Doğum Tarihi (YYYY-AA-GG)',
                  icon: Icons.cake_outlined),
            ),
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
                minimumSize: Size.zero,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF051929)))
                  : const Text('Kaydet',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  const _SheetField(
      {required this.ctrl,
      required this.hint,
      required this.icon,
      this.keyboardType});

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
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: c.text1),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: c.text3),
          prefixIcon: Icon(icon, size: 18, color: c.text3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          isDense: true,
        ),
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

// ── Info bottom sheet ─────────────────────────────────────────────────

void _showInfoSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color iconColor,
  required List<Widget> sections,
}) {
  final c = context.appColors;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.93,
      minChildSize: 0.35,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.text1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  icon: Icon(Icons.close_rounded, size: 20, color: c.text3),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ]),
            ),
            Divider(height: 1, color: c.border),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: sections,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoBlock extends StatelessWidget {
  final String? heading;
  final String body;
  const _InfoBlock({this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            Text(
              heading!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (body.isNotEmpty)
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                color: c.text2,
                height: 1.65,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoContact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoContact(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: c.text3,
                      letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      color: c.text1,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
    );
  }
}
