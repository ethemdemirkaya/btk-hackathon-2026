import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConf = true;
  bool _kvkk = false;
  bool _loading = false;
  Map<String, String> _fieldErrors = {};

  static const _bg = Color(0xFF060D18);
  static const _accent = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFE8F4FF);
  static const _textSecondary = Color(0xFF8BA4BC);
  static const _textTertiary = Color(0xFF4A6478);
  static const _cardBg = Color(0xFF0D1B2A);
  static const _border = Color(0xFF1A2940);
  static const _negative = Color(0xFFFF4D6D);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfCtrl.dispose();
    _incomeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_kvkk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KVKK onayı zorunludur.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _fieldErrors = {};
    });

    final repo = AuthRepository.create();
    final income =
        double.tryParse(_incomeCtrl.text.replaceAll(',', '.')) ?? 0;

    try {
      final result = await repo.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        passwordConfirmation: _passwordConfCtrl.text,
        monthlyIncome: income,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      ref.read(authProvider.notifier).setAuthenticated(result.user);
      context.go('/dashboard');
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 422) {
        setState(() => _fieldErrors = parseValidationErrors(e));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: const TextStyle(color: _textTertiary, fontSize: 14),
      labelStyle: const TextStyle(color: _textTertiary, fontSize: 14),
      errorText: errorText,
      prefixIcon: Icon(prefixIcon, color: _textTertiary, size: 20),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: _textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _cardBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _negative, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _negative, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: _textSecondary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Hesap Oluştur',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Finansa yeni bir bakış açısı',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: _textPrimary, fontSize: 15),
                        decoration: _fieldDecoration(
                          label: 'Ad Soyad',
                          prefixIcon: Icons.person_outlined,
                          errorText: _fieldErrors['name'],
                        ),
                        validator: (v) => AppValidators.required(v, 'Ad soyad'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: _textPrimary, fontSize: 15),
                        decoration: _fieldDecoration(
                          label: 'E-posta',
                          prefixIcon: Icons.email_outlined,
                          errorText: _fieldErrors['email'],
                        ),
                        validator: AppValidators.email,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: _textPrimary, fontSize: 15),
                        decoration: _fieldDecoration(
                          label: 'Şifre',
                          prefixIcon: Icons.lock_outlined,
                          errorText: _fieldErrors['password'],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _textTertiary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: AppValidators.password,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordConfCtrl,
                        obscureText: _obscureConf,
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: _textPrimary, fontSize: 15),
                        decoration: _fieldDecoration(
                          label: 'Şifre Tekrar',
                          prefixIcon: Icons.lock_outlined,
                          errorText: _fieldErrors['password_confirmation'],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConf
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _textTertiary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscureConf = !_obscureConf),
                          ),
                        ),
                        validator: (v) =>
                            AppValidators.passwordConfirm(v, _passwordCtrl.text),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _incomeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: _textPrimary, fontSize: 15),
                        decoration: _fieldDecoration(
                          label: 'Aylık Gelir',
                          prefixIcon: Icons.attach_money_rounded,
                          prefixText: '₺ ',
                          errorText: _fieldErrors['monthly_income'],
                        ),
                        validator: (v) =>
                            AppValidators.positiveNumber(v, 'Aylık gelir'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        style:
                            const TextStyle(color: _textPrimary, fontSize: 15),
                        decoration: _fieldDecoration(
                          label: 'Telefon (opsiyonel)',
                          prefixIcon: Icons.phone_outlined,
                          hintText: '05XX XXX XX XX',
                          errorText: _fieldErrors['phone'],
                        ),
                        validator: AppValidators.phone,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => setState(() => _kvkk = !_kvkk),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _kvkk ? _accent.withValues(alpha:0.4) : _border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color:
                                      _kvkk ? _accent : Colors.transparent,
                                  border: Border.all(
                                    color: _kvkk ? _accent : _border,
                                    width: 1.5,
                                  ),
                                ),
                                child: _kvkk
                                    ? const Icon(Icons.check_rounded,
                                        size: 14,
                                        color: Color(0xFF051929))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'KVKK kapsamında kişisel verilerimin işlenmesini kabul ediyorum.',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_loading || !_kvkk) ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            disabledBackgroundColor: _accent.withValues(alpha:0.3),
                            foregroundColor: const Color(0xFF051929),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF051929)),
                                  ),
                                )
                              : const Text(
                                  'Kayıt Ol',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Zaten hesabın var mı?',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                            child: const Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
