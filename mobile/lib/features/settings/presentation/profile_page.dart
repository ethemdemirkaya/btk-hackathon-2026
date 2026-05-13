import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _incomeCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _incomeCtrl = TextEditingController(
        text: user?.monthlyIncome.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await DioClient.instance.patch(ApiEndpoints.authPatchMe(), data: {
        'name': _nameCtrl.text.trim(),
        if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        'monthly_income':
            double.tryParse(_incomeCtrl.text.replaceAll(',', '.')) ?? 0,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  child: Text(
                    (user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U'),
                    style: AppTextStyles.displayMedium,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (user != null)
                Center(
                  child: Text(user.email, style: AppTextStyles.bodySmall),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (v) => AppValidators.required(v, 'Ad soyad'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: user?.email,
                decoration: const InputDecoration(
                  labelText: 'E-posta (değiştirilemez)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: AppValidators.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _incomeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Aylık Gelir (₺)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) =>
                    AppValidators.positiveNumber(v, 'Aylık gelir'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
