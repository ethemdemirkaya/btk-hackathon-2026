import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────
const _bg      = Color(0xFF060D18);
const _cardBg  = Color(0xFF0D1B2A);
const _border  = Color(0xFF1A2940);
const _accent  = Color(0xFF00D4FF);
const _text1   = Color(0xFFE8F4FF);
const _text2   = Color(0xFF8BA4BC);
const _text3   = Color(0xFF4A6478);
const _neg     = Color(0xFFFF4D6D);

class PinLoginPage extends ConsumerStatefulWidget {
  const PinLoginPage({super.key});

  @override
  ConsumerState<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends ConsumerState<PinLoginPage>
    with SingleTickerProviderStateMixin {
  final _localAuth = LocalAuthentication();
  String _entered  = '';
  bool   _shaking  = false;
  bool   _biometricAvailable = false;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _checkBiometric();
    _tryBiometricOnOpen();
  }

  Future<void> _checkBiometric() async {
    try {
      final enabled = await AuthStorage.isBiometricEnabled();
      if (!enabled) return;
      final canAuth = await _localAuth.canCheckBiometrics;
      final devices = await _localAuth.getAvailableBiometrics();
      if (mounted) {
        setState(() => _biometricAvailable = canAuth && devices.isNotEmpty);
      }
    } catch (_) {}
  }

  Future<void> _tryBiometricOnOpen() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final enabled = await AuthStorage.isBiometricEnabled();
    if (enabled) _authenticateBiometric();
  }

  Future<void> _authenticateBiometric() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Paranette\'ye giriş yapmak için doğrulayın',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok && mounted) _unlock();
    } catch (_) {}
  }

  void _onKey(String digit) {
    if (_entered.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() => _entered += digit);
    if (_entered.length == 6) {
      Future.delayed(const Duration(milliseconds: 80), _verifyPin);
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verifyPin() async {
    final stored = await AuthStorage.getPin();
    if (stored == _entered) {
      _unlock();
    } else {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() { _entered = ''; _shaking = true; });
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _shaking = false);
    }
  }

  void _unlock() {
    final pending = ref.read(pendingUserProvider);
    if (pending != null) {
      ref.read(authProvider.notifier).setAuthenticated(pending);
      ref.read(pendingUserProvider.notifier).state = null;
    }
    context.go('/dashboard');
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  UserModel? get _user => ref.watch(pendingUserProvider) ?? ref.watch(authProvider).user;

  String get _initials {
    final name = _user?.name ?? '';
    return name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0A7DA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(_initials.isEmpty ? 'U' : _initials,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700,
                        color: Color(0xFF051929))),
              ),
            ),
            const SizedBox(height: 16),
            Text(_user?.name ?? 'Hoş geldiniz',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _text1)),
            const SizedBox(height: 6),
            const Text('PIN kodunuzu girin',
                style: TextStyle(fontSize: 13, color: _text2)),
            const SizedBox(height: 40),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _entered.length;
                  final color  = _shaking ? _neg : _accent;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? color : Colors.transparent,
                      border: Border.all(
                          color: filled ? color : _border, width: 2),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Number pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (final row in [
                    ['1','2','3'],
                    ['4','5','6'],
                    ['7','8','9'],
                    ['bio','0','del'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: row.map((k) => _buildKey(k)).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Şifre ile giriş
            TextButton(
              onPressed: () {
                ref.read(pendingUserProvider.notifier).state = null;
                ref.read(authProvider.notifier).setUnauthenticated();
                context.go('/login');
              },
              child: const Text('Şifre ile giriş yap',
                  style: TextStyle(fontSize: 13, color: _text3)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String key) {
    if (key == 'del') {
      return _KeyButton(
        onTap: _onBackspace,
        child: const Icon(Icons.backspace_outlined, size: 22, color: _text2),
      );
    }
    if (key == 'bio') {
      return _biometricAvailable
          ? _KeyButton(
              onTap: _authenticateBiometric,
              child: const Icon(Icons.fingerprint, size: 26, color: _accent),
            )
          : const SizedBox(width: 80, height: 64);
    }
    return _KeyButton(
      onTap: () => _onKey(key),
      child: Text(key,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w400, color: _text1)),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _KeyButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 64,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Center(child: child),
      ),
    );
  }
}
