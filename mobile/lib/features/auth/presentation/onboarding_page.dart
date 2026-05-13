import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.account_balance,
      title: 'Tüm bankalarını tek yerde',
      subtitle:
          'Ziraat, Garanti, İşbank ve daha fazlasını bağla. Hesaplarını, kartlarını ve kredilerini tek yerden yönet.',
    ),
    _OnboardingSlide(
      icon: Icons.psychology,
      title: 'AI ile finansal tavsiye',
      subtitle:
          'Kişisel finans asistanın her zaman yanında. Harcamalarını analiz et, bütçeni optimize et.',
    ),
    _OnboardingSlide(
      icon: Icons.flag,
      title: 'Hedeflerini takip et',
      subtitle:
          'Tasarruf hedefleri oluştur, kişisel enflasyonunu gör ve geleceğini simüle et.',
    ),
    _OnboardingSlide(
      icon: Icons.document_scanner,
      title: 'Fişini çek, otomatik kaydet',
      subtitle:
          'Kamerandan fişini tara, AI otomatik olarak işlem oluştursun. Garanti takibini hiç kaçırma.',
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
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _complete,
                  child: const Text('Geç'),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _OnboardingSlideView(slide: _slides[i]),
              ),
            ),
            // Dots + buttons
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
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isLast) ...[
                    ElevatedButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Hesap Oluştur'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Giriş Yap'),
                    ),
                  ] else
                    ElevatedButton(
                      onPressed: _next,
                      child: const Text('İleri'),
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
  const _OnboardingSlide(
      {required this.icon, required this.title, required this.subtitle});
}

class _OnboardingSlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _OnboardingSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: AppTextStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
