import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Oluştur'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad *',
                  prefixIcon: const Icon(Icons.person_outlined),
                  errorText: _fieldErrors['name'],
                ),
                validator: (v) => AppValidators.required(v, 'Ad soyad'),
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'E-posta *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _fieldErrors['email'],
                ),
                validator: AppValidators.email,
              ),
              const SizedBox(height: 16),
              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Şifre *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: _fieldErrors['password'],
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: AppValidators.password,
              ),
              const SizedBox(height: 16),
              // Password confirm
              TextFormField(
                controller: _passwordConfCtrl,
                obscureText: _obscureConf,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: _fieldErrors['password_confirmation'],
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConf
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConf = !_obscureConf),
                  ),
                ),
                validator: (v) =>
                    AppValidators.passwordConfirm(v, _passwordCtrl.text),
              ),
              const SizedBox(height: 16),
              // Monthly income
              TextFormField(
                controller: _incomeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Aylık Gelir (₺) *',
                  prefixIcon: const Icon(Icons.attach_money),
                  errorText: _fieldErrors['monthly_income'],
                ),
                validator: (v) =>
                    AppValidators.positiveNumber(v, 'Aylık gelir'),
              ),
              const SizedBox(height: 16),
              // Phone (optional)
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Telefon (opsiyonel)',
                  hintText: '05XX XXX XX XX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  errorText: _fieldErrors['phone'],
                ),
                validator: AppValidators.phone,
              ),
              const SizedBox(height: 20),
              // KVKK
              Row(
                children: [
                  Checkbox(
                    value: _kvkk,
                    onChanged: (v) => setState(() => _kvkk = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _kvkk = !_kvkk),
                      child: Text(
                        'KVKK kapsamında kişisel verilerimin işlenmesini kabul ediyorum.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_loading || !_kvkk) ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Hesap Oluştur'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Zaten hesabınız var mı?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Giriş Yap'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
