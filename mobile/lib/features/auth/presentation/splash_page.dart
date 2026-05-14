import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/colors.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _particleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _bgController.forward();
    Future.delayed(const Duration(milliseconds: 200),
        () => _logoController.forward());
    Future.delayed(const Duration(milliseconds: 600),
        () => _textController.forward());
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    try {
      await _doboot();
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }

  Future<void> _doboot() async {
    final notifier = ref.read(authProvider.notifier);
    final repo = AuthRepository.create();

    bool hasToken = false;
    try {
      hasToken =
          await AuthStorage.hasToken().timeout(const Duration(seconds: 3));
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
        // Token expired/invalid — repo.me() already cleared storage
        notifier.setUnauthenticated();
        if (!mounted) return;
        context.go('/login');
      }
    } else {
      // No token: navigate to onboarding on first launch, login otherwise
      notifier.setUnauthenticated();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarding_completed') ?? false;
      if (!mounted) return;
      context.go(onboarded ? '/login' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (_, __) => Stack(
          children: [
            // Dark gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF020D1A),
                    Color(0xFF061425),
                    Color(0xFF0A2540),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Animated radial glow behind logo
            Center(
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating particles
            CustomPaint(
              painter: _ParticlePainter(animation: _particleController),
              size: MediaQuery.of(context).size,
            ),

            // Grid lines (subtle)
            CustomPaint(
              painter: _GridPainter(),
              size: MediaQuery.of(context).size,
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: _LogoMark(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // App name + tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFF8EC5F8)],
                            ).createShader(bounds),
                            child: const Text(
                              'Paranette',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _taglineFade,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 1,
                                  color: AppColors.accent
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Yapay Zeka Destekli Finans',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text2Dark,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 20,
                                  height: 1,
                                  color: AppColors.accent
                                      .withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator
                  FadeTransition(
                    opacity: _taglineFade,
                    child: _PulsingDots(),
                  ),
                ],
              ),
            ),

            // Bottom badge
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineFade,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.border2Dark, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'TEKNOFEST 2026',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.text4Dark,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

// ── Logo mark ───────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D4FF), Color(0xFF0A7DA8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle glow
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          // Icon
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 44,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dots ────────────────────────────────────────────────────
class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = i * 0.25;
            final t = (_ctrl.value - offset).clamp(0.0, 1.0);
            final opacity = (math.sin(t * math.pi * 2) + 1) / 2;
            final scale = 0.6 + opacity * 0.4;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.4 + opacity * 0.6),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Particle painter ────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;

  _ParticlePainter({required this.animation}) : super(repaint: animation);

  static final _rng = math.Random(42);
  static final _particles = List.generate(20, (i) => _Particle(_rng));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final progress = (animation.value + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = size.height - progress * (size.height + 40) + p.yNoise * 30;
      final alpha = (math.sin(progress * math.pi) * p.opacity).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = AppColors.accent.withValues(alpha: alpha * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class _Particle {
  final double x;
  final double offset;
  final double size;
  final double opacity;
  final double yNoise;

  _Particle(math.Random rng)
      : x = rng.nextDouble(),
        offset = rng.nextDouble(),
        size = 1.0 + rng.nextDouble() * 2.0,
        opacity = 0.3 + rng.nextDouble() * 0.7,
        yNoise = rng.nextDouble() * 2 - 1;
}

// ── Grid painter (subtle background grid) ──────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
