import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/auth_repository.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    try {
      await _doboot();
    } catch (e) {
      // Herhangi bir hata olursa güvenli fallback: login ekranı
      if (mounted) context.go('/login');
    }
  }

  Future<void> _doboot() async {
    final notifier = ref.read(authProvider.notifier);
    final repo = AuthRepository.create();

    bool hasToken = false;
    try {
      hasToken = await AuthStorage.hasToken()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      hasToken = false;
    }

    if (hasToken) {
      UserModel? user;
      try {
        user = await repo.me().timeout(const Duration(seconds: 8));
      } catch (_) {
        user = null;
      }
      if (!mounted) return;

      if (user != null) {
        notifier.setAuthenticated(user);
        context.go('/dashboard');
      } else {
        bool stillHas = false;
        try {
          stillHas = await AuthStorage.hasToken()
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          stillHas = false;
        }
        if (!mounted) return;
        if (!stillHas) {
          context.go('/login');
        } else {
          await notifier.initialize();
          if (!mounted) return;
          context.go('/dashboard');
        }
      }
    } else {
      // Token yok → onboarding veya login
      await notifier.initialize();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarding_completed') ?? false;
      if (!mounted) return;
      context.go(onboarded ? '/login' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Paranette',
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Finansal özgürlüğünüz',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
