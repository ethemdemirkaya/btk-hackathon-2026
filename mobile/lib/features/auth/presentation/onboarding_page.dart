import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _bg = Color(0xFF060D18);
  static const _accent = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFE8F4FF);
  static const _textSecondary = Color(0xFF8BA4BC);
  static const _border = Color(0xFF1A2940);

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.currency_lira,
      title: 'Paranoya yok, sadece para',
      subtitle:
          'Tüm banka hesaplarını, kartlarını ve kredilerini tek bir yerde birleştir. Finansa bakışın değişecek.',
      glowColor: Color(0xFF00D4FF),
    ),
    _OnboardingSlide(
      icon: Icons.psychology_rounded,
      title: 'AI Finansal Koçunuz',
      subtitle:
          'Kişisel yapay zeka asistanın harcamalarını analiz eder, tasarruf fırsatlarını bulur ve geleceğini planlar.',
      glowColor: Color(0xFF7C3AED),
    ),
    _OnboardingSlide(
      icon: Icons.bar_chart_rounded,
      title: 'Tüm hesaplarınız tek yerde',
      subtitle:
          'Ziraat, Garanti, İşbank ve daha fazlası. Anlık bakiye, harcama grafikleri ve trend analizleri.',
      glowColor: Color(0xFF0DD9A0),
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'Güvenli ve şifreli',
      subtitle:
          'Banka düzeyinde şifreleme ve KVKK uyumlu altyapıyla verileriniz her zaman güvende.',
      glowColor: Color(0xFFF59E0B),
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Paranette',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _complete,
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Atla',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _OnboardingSlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page ? _accent : Colors.transparent,
                          border: i == _page
                              ? null
                              : Border.all(color: _border, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (isLast) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.go('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: const Color(0xFF051929),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Başlayalım',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.go('/login'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: const BorderSide(color: _border, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: const Color(0xFF051929),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'İleri',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
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
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color glowColor;
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.glowColor,
  });
}

class _OnboardingSlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _OnboardingSlideView({required this.slide});

  static const _cardBg = Color(0xFF0D1B2A);
  static const _border = Color(0xFF1A2940);
  static const _textPrimary = Color(0xFFE8F4FF);
  static const _textSecondary = Color(0xFF8BA4BC);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(48),
              border: Border.all(color: _border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: slide.glowColor.withValues(alpha: 0.18),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: slide.glowColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: slide.glowColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: slide.glowColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(slide.icon, size: 52, color: slide.glowColor),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
