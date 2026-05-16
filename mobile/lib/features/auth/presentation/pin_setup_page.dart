import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../shared/providers/auth_provider.dart';

enum _Step { enter, confirm }

class PinSetupPage extends ConsumerStatefulWidget {
  final bool isChange;
  final bool mandatory;
  const PinSetupPage({super.key, this.isChange = false, this.mandatory = false});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage>
    with SingleTickerProviderStateMixin {
  _Step  _step    = _Step.enter;
  String _first   = '';
  String _entered = '';
  bool   _mismatch = false;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_entered.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() { _entered += digit; _mismatch = false; });
    if (_entered.length == 6) {
      Future.delayed(const Duration(milliseconds: 80), _advance);
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _advance() async {
    if (_step == _Step.enter) {
      setState(() { _first = _entered; _entered = ''; _step = _Step.confirm; });
    } else {
      if (_entered == _first) {
        await AuthStorage.savePin(_entered);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isChange ? 'PIN güncellendi.' : 'PIN kuruldu.'),
          backgroundColor: context.appColors.positive,
        ));
        context.go('/dashboard');
      } else {
        HapticFeedback.heavyImpact();
        _shakeCtrl.forward(from: 0);
        setState(() { _mismatch = true; _entered = ''; _step = _Step.enter; _first = ''; });
      }
    }
  }

  void _skip() {
    context.go('/dashboard');
  }

  String get _title => _step == _Step.enter
      ? (widget.isChange ? 'Yeni PIN oluştur' : 'PIN kodu oluştur')
      : 'PIN kodunu onayla';

  String get _subtitle => _step == _Step.enter
      ? '6 haneli bir PIN belirleyin'
      : 'PIN kodunuzu tekrar girin';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: widget.isChange
          ? AppBar(
              backgroundColor: c.bg,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: c.text2),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Lock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Icon(
                _step == _Step.enter
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                size: 32,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(_step),
                children: [
                  Text(_title,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: c.text1)),
                  const SizedBox(height: 6),
                  Text(_subtitle,
                      style: TextStyle(fontSize: 13, color: c.text2)),
                  if (_mismatch) ...[
                    const SizedBox(height: 8),
                    Text('PIN kodları eşleşmedi, tekrar deneyin.',
                        style: TextStyle(fontSize: 12, color: c.negative)),
                  ],
                ],
              ),
            ),

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
                  final color  = _mismatch ? c.negative : AppColors.accent;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? color : Colors.transparent,
                      border: Border.all(
                          color: filled ? color : c.border, width: 2),
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
                    ['','0','del'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: row.map((k) => _buildKey(k, c)).toList(),
                      ),
                    ),
                ],
              ),
            ),

            if (!widget.isChange && !widget.mandatory)
              TextButton(
                onPressed: _skip,
                child: Text('Şimdi değil, atla',
                    style: TextStyle(fontSize: 13, color: c.text3)),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String key, AppColorTokens c) {
    if (key == 'del') {
      return _KeyBtn(
        onTap: _onBackspace,
        card: c.card,
        border: c.border,
        child: Icon(Icons.backspace_outlined, size: 22, color: c.text2),
      );
    }
    if (key.isEmpty) return const SizedBox(width: 80, height: 64);
    return _KeyBtn(
      onTap: () => _onKey(key),
      card: c.card,
      border: c.border,
      child: Text(key,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w400, color: c.text1)),
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color card;
  final Color border;
  const _KeyBtn({
    required this.onTap,
    required this.child,
    required this.card,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 64,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Center(child: child),
      ),
    );
  }
}
