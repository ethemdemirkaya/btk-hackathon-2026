import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _bgController;
  late AnimationController _floatController;
  late AnimationController _slideController;
  late Animation<double> _slideAnim;

  static const _slides = [
    _SlideData(
      accentColor: Color(0xFF00D4FF),
      secondaryColor: Color(0xFF0099CC),
      bgFrom: Color(0xFF020D1A),
      bgTo: Color(0xFF061830),
      title: 'Paranoya yok,\nsadece para',
      subtitle:
          'Tüm banka hesaplarını, kartlarını ve kredilerini tek ekranda gör. Finansal özgürlük bir dokunuşta.',
      illustrationType: _IllType.wallet,
    ),
    _SlideData(
      accentColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFFAB6EF8),
      bgFrom: Color(0xFF08021A),
      bgTo: Color(0xFF130830),
      title: 'AI koçun\nher zaman yanında',
      subtitle:
          'Yapay zeka asistanın harcamalarını analiz eder, tasarruf fırsatlarını bulur ve geleceğini planlar.',
      illustrationType: _IllType.ai,
    ),
    _SlideData(
      accentColor: Color(0xFF0DD9A0),
      secondaryColor: Color(0xFF00A87A),
      bgFrom: Color(0xFF01150F),
      bgTo: Color(0xFF022B1E),
      title: 'Tüm bankalar\nbir arada',
      subtitle:
          'Ziraat, Garanti, İşbank ve daha fazlası. Anlık bakiye, harcama grafikleri ve trend analizleri.',
      illustrationType: _IllType.banks,
    ),
    _SlideData(
      accentColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFD97706),
      bgFrom: Color(0xFF150D01),
      bgTo: Color(0xFF291A03),
      title: 'Banka düzeyinde\ngüvenlik',
      subtitle:
          'KVKK uyumlu altyapı ve uçtan uca şifrelemeyle verileriniz her zaman koruma altında.',
      illustrationType: _IllType.shield,
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _floatController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _slideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: slide.bgFrom,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.4,
            colors: [
              slide.bgTo,
              slide.bgFrom,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient background glow
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.2,
              right: -size.width * 0.2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                height: size.height * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      slide.accentColor.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Grid pattern
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter(slide.accentColor)),
            ),

            // Floating orbs
            AnimatedBuilder(
              animation: _floatController,
              builder: (_, __) {
                final t = _floatController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: size.height * 0.08 + math.sin(t * math.pi) * 12,
                      right: size.width * 0.08,
                      child: _GlowOrb(
                        color: slide.accentColor,
                        size: 80,
                        opacity: 0.15,
                      ),
                    ),
                    Positioned(
                      top: size.height * 0.18 + math.cos(t * math.pi) * 8,
                      left: size.width * 0.04,
                      child: _GlowOrb(
                        color: slide.secondaryColor,
                        size: 50,
                        opacity: 0.1,
                      ),
                    ),
                    Positioned(
                      bottom: size.height * 0.28 + math.sin(t * math.pi + 1) * 10,
                      right: size.width * 0.06,
                      child: _GlowOrb(
                        color: slide.accentColor,
                        size: 40,
                        opacity: 0.08,
                      ),
                    ),
                  ],
                );
              },
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: [
                                    slide.accentColor,
                                    slide.secondaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.accentColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Paranette',
                              style: TextStyle(
                                color: Color(0xFFE8F4FF),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),

                        // Skip
                        GestureDetector(
                          onTap: _complete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Atla',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page view
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _slides.length,
                      itemBuilder: (_, i) => _SlidePage(
                        slide: _slides[i],
                        floatController: _floatController,
                        slideAnim: i == _currentPage ? _slideAnim : null,
                      ),
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dot indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (i) {
                            final active = i == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 32 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: active
                                    ? slide.accentColor
                                    : Colors.white.withValues(alpha: 0.18),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          color: slide.accentColor
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        )
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 28),

                        // Action buttons
                        if (isLast) ...[
                          _PrimaryButton(
                            label: 'Hesap Oluştur',
                            color: slide.accentColor,
                            onTap: () => context.go('/register'),
                          ),
                          const SizedBox(height: 12),
                          _SecondaryButton(
                            label: 'Zaten hesabım var',
                            accentColor: slide.accentColor,
                            onTap: () => context.go('/login'),
                          ),
                        ] else
                          Row(
                            children: [
                              // Back indicator dots (mobile-friendly)
                              if (_currentPage > 0)
                                GestureDetector(
                                  onTap: () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  ),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white.withValues(alpha: 0.5),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              if (_currentPage > 0) const SizedBox(width: 12),
                              Expanded(
                                child: _PrimaryButton(
                                  label: 'İleri',
                                  color: slide.accentColor,
                                  trailing: Icons.arrow_forward_rounded,
                                  onTap: _next,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
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

// ── Slide page ─────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  final AnimationController floatController;
  final Animation<double>? slideAnim;

  const _SlidePage({
    required this.slide,
    required this.floatController,
    this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    final anim = slideAnim ?? const AlwaysStoppedAnimation(1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: _Illustration(
                type: slide.illustrationType,
                accentColor: slide.accentColor,
                secondaryColor: slide.secondaryColor,
                floatController: floatController,
              ),
            ),
          ),

          const SizedBox(height: 52),

          // Title
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(
              opacity: anim,
              child: Text(
                slide.title,
                style: const TextStyle(
                  color: Color(0xFFEDF5FF),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Subtitle
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
            )),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: anim,
                  curve: const Interval(0.15, 1.0, curve: Curves.easeIn),
                ),
              ),
              child: Text(
                slide.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w400,
                  height: 1.65,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration switcher ──────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final _IllType type;
  final Color accentColor;
  final Color secondaryColor;
  final AnimationController floatController;

  const _Illustration({
    required this.type,
    required this.accentColor,
    required this.secondaryColor,
    required this.floatController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (_, __) {
        final t = floatController.value;
        final floatOffset = math.sin(t * math.pi) * 8.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                // Card base
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.18),
                        secondaryColor.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.28),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.22),
                        blurRadius: 50,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _IllustrationIcon(type: type, accentColor: accentColor),
                  ),
                ),

                // Floating chips around
                ..._buildFloatingChips(t),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingChips(double t) {
    switch (type) {
      case _IllType.wallet:
        return [
          _FloatingChip(
            angle: -0.6,
            radius: 108,
            t: t,
            phase: 0,
            child: _MiniChip(
              label: '+₺2.450',
              color: const Color(0xFF0DD9A0),
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          _FloatingChip(
            angle: 2.2,
            radius: 108,
            t: t,
            phase: 0.5,
            child: _MiniChip(
              label: '3 Banka',
              color: accentColor,
              icon: Icons.account_balance_rounded,
            ),
          ),
        ];
      case _IllType.ai:
        return [
          _FloatingChip(
            angle: -0.5,
            radius: 108,
            t: t,
            phase: 0,
            child: _MiniChip(
              label: 'AI Analiz',
              color: const Color(0xFF7C3AED),
              icon: Icons.auto_awesome_rounded,
            ),
          ),
          _FloatingChip(
            angle: 2.3,
            radius: 108,
            t: t,
            phase: 0.6,
            child: _MiniChip(
              label: '%18 tasarruf',
              color: const Color(0xFFAB6EF8),
              icon: Icons.trending_up_rounded,
            ),
          ),
        ];
      case _IllType.banks:
        return [
          _FloatingChip(
            angle: -0.55,
            radius: 108,
            t: t,
            phase: 0,
            child: _MiniChip(
              label: 'Garanti',
              color: accentColor,
              icon: Icons.account_balance_rounded,
            ),
          ),
          _FloatingChip(
            angle: 2.4,
            radius: 108,
            t: t,
            phase: 0.5,
            child: _MiniChip(
              label: 'Ziraat',
              color: const Color(0xFF0DD9A0),
              icon: Icons.account_balance_rounded,
            ),
          ),
        ];
      case _IllType.shield:
        return [
          _FloatingChip(
            angle: -0.6,
            radius: 108,
            t: t,
            phase: 0,
            child: _MiniChip(
              label: 'KVKK',
              color: const Color(0xFFF59E0B),
              icon: Icons.verified_rounded,
            ),
          ),
          _FloatingChip(
            angle: 2.3,
            radius: 108,
            t: t,
            phase: 0.5,
            child: _MiniChip(
              label: '256-bit',
              color: const Color(0xFFD97706),
              icon: Icons.lock_rounded,
            ),
          ),
        ];
    }
  }
}

class _IllustrationIcon extends StatelessWidget {
  final _IllType type;
  final Color accentColor;
  const _IllustrationIcon({required this.type, required this.accentColor});

  IconData get _icon => switch (type) {
        _IllType.wallet => Icons.account_balance_wallet_rounded,
        _IllType.ai => Icons.psychology_rounded,
        _IllType.banks => Icons.account_balance_rounded,
        _IllType.shield => Icons.shield_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: 64, color: accentColor);
  }
}

class _FloatingChip extends StatelessWidget {
  final double angle;
  final double radius;
  final double t;
  final double phase;
  final Widget child;

  const _FloatingChip({
    required this.angle,
    required this.radius,
    required this.t,
    required this.phase,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin((t + phase) * math.pi) * 5;
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius + floatY;

    return Transform.translate(
      offset: Offset(x, y),
      child: child,
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MiniChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buttons ────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? trailing;

  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, size: 20, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color accentColor;
  const _GridPainter(this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.035)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.accentColor != accentColor;
}

// ── Data models ────────────────────────────────────────────────────────────

enum _IllType { wallet, ai, banks, shield }

class _SlideData {
  final Color accentColor;
  final Color secondaryColor;
  final Color bgFrom;
  final Color bgTo;
  final String title;
  final String subtitle;
  final _IllType illustrationType;

  const _SlideData({
    required this.accentColor,
    required this.secondaryColor,
    required this.bgFrom,
    required this.bgTo,
    required this.title,
    required this.subtitle,
    required this.illustrationType,
  });
}
