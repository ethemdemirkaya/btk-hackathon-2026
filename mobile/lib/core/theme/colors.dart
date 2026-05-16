import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand palette (from design tokens) ──
  // Primary: #0A2540 (deep navy)
  // Accent: #00D4FF (cyan CTA)
  static const primary = Color(0xFF0A2540);
  static const primaryLight = Color(0xFF102E4F);
  static const primaryDark = Color(0xFF061425);

  // Accent (cyan)
  static const accent = Color(0xFF00D4FF);
  static const accentText = Color(0xFF051929);
  static const accentDim = Color(0x2E00D4FF); // rgba(0,212,255,0.18)

  // ── Dark theme backgrounds ──
  static const bg0 = Color(0xFF061425);
  static const bg1 = Color(0xFF0A2540);
  static const bg2 = Color(0xFF102E4F);
  static const bg3 = Color(0xFF18395C);

  // ── Light theme backgrounds ──
  static const lightBg0 = Color(0xFFF2F5F9);
  static const lightBg1 = Color(0xFFFFFFFF);
  static const lightBg2 = Color(0xFFFFFFFF);
  static const lightBg3 = Color(0xFFEBF0F5);

  // ── Dark text ──
  static const text1Dark = Color(0xFFE8F1FF);
  static const text2Dark = Color(0xFF8FA5C2);
  static const text3Dark = Color(0xFF5A7593);
  static const text4Dark = Color(0xFF3D5677);

  // ── Light text ──
  static const text1Light = Color(0xFF0A2540);
  static const text2Light = Color(0xFF4A5870);
  static const text3Light = Color(0xFF777779);
  static const text4Light = Color(0xFFB5BEC9);

  // ── Semantic ──
  static const positive = Color(0xFF2BE0A0);
  static const positiveLight = Color(0xFF008F66);
  static const negative = Color(0xFFFF5C7C);
  static const negativeLight = Color(0xFFE53E5C);
  static const warning = Color(0xFFFFC857);
  static const warningLight = Color(0xFFD97706);
  static const gold = Color(0xFFC99B5B);
  static const info = Color(0xFF6FB1FC);

  // ── Legacy aliases (kept for backward compat) ──
  static const success = positive;
  static const successLight = Color(0xFF008F66);
  static const danger = negative;
  static const dangerLight = Color(0x1FFF5C7C);
  static const income = positive;
  static const expense = negative;

  // ── Borders (dark) ──
  static const border1Dark = Color(0x148FC0FF); // rgba(143,192,255,0.08)
  static const border2Dark = Color(0x248FC0FF); // rgba(143,192,255,0.14)

  // ── Borders (light) ──
  static const border1Light = Color(0x140A2540); // rgba(10,37,64,0.08)
  static const borderLight = Color(0xFFE2E8F0);

  // Legacy background aliases
  static const backgroundDark = bg0;
  static const backgroundLight = lightBg0;
  static const cardDark = bg1;
  static const cardLight = lightBg1;
  static const surfaceDark = bg2;
  static const surfaceLight = lightBg3;
  static const textPrimaryDark = text1Dark;
  static const textPrimaryLight = text1Light;
  static const textSecondaryDark = text2Dark;
  static const textSecondaryLight = text2Light;
  static const borderDark = border1Dark;

  static Color fromHint(String hint) {
    switch (hint) {
      case 'danger':
        return danger;
      case 'warning':
        return warning;
      case 'info':
        return info;
      case 'success':
        return success;
      case 'primary':
        return accent;
      default:
        return text3Light;
    }
  }

  static Color fromHintLight(String hint) {
    switch (hint) {
      case 'danger':
        return danger.withValues(alpha: 0.12);
      case 'warning':
        return warning.withValues(alpha: 0.12);
      case 'info':
        return info.withValues(alpha: 0.12);
      case 'success':
        return success.withValues(alpha: 0.12);
      case 'primary':
        return accentDim;
      default:
        return surfaceLight;
    }
  }
}

// ── Theme-aware design tokens (registered as ThemeExtension) ──────────────
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color bg;
  final Color card;
  final Color border;
  final Color heroBgFrom;
  final Color heroBgTo;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color positive;
  final Color negative;
  final Color warning;

  const AppColorTokens({
    required this.bg,
    required this.card,
    required this.border,
    required this.heroBgFrom,
    required this.heroBgTo,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.positive,
    required this.negative,
    required this.warning,
  });

  static const dark = AppColorTokens(
    bg:         Color(0xFF060D18),
    card:       Color(0xFF0D1B2A),
    border:     Color(0xFF1A2940),
    heroBgFrom: Color(0xFF0A1929),
    heroBgTo:   Color(0xFF0D2240),
    text1:      Color(0xFFE8F4FF),
    text2:      Color(0xFF8BA4BC),
    text3:      Color(0xFF4A6478),
    positive:   Color(0xFF0DD9A0),
    negative:   Color(0xFFFF4D6D),
    warning:    Color(0xFFF59E0B),
  );

  static const light = AppColorTokens(
    bg:         Color(0xFFF2F5F9),
    card:       Color(0xFFFFFFFF),
    border:     Color(0xFFE2E8F0),
    heroBgFrom: Color(0xFFE8F0FA),
    heroBgTo:   Color(0xFFD0E2F5),
    text1:      Color(0xFF0A2540),
    text2:      Color(0xFF4A5870),
    text3:      Color(0xFF8899AA),
    positive:   Color(0xFF008F66),
    negative:   Color(0xFFE53E5C),
    warning:    Color(0xFFD97706),
  );

  @override
  AppColorTokens copyWith({
    Color? bg, Color? card, Color? border,
    Color? heroBgFrom, Color? heroBgTo,
    Color? text1, Color? text2, Color? text3,
    Color? positive, Color? negative, Color? warning,
  }) => AppColorTokens(
    bg:         bg         ?? this.bg,
    card:       card       ?? this.card,
    border:     border     ?? this.border,
    heroBgFrom: heroBgFrom ?? this.heroBgFrom,
    heroBgTo:   heroBgTo   ?? this.heroBgTo,
    text1:      text1      ?? this.text1,
    text2:      text2      ?? this.text2,
    text3:      text3      ?? this.text3,
    positive:   positive   ?? this.positive,
    negative:   negative   ?? this.negative,
    warning:    warning    ?? this.warning,
  );

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      bg:         Color.lerp(bg,         other.bg,         t)!,
      card:       Color.lerp(card,       other.card,       t)!,
      border:     Color.lerp(border,     other.border,     t)!,
      heroBgFrom: Color.lerp(heroBgFrom, other.heroBgFrom, t)!,
      heroBgTo:   Color.lerp(heroBgTo,   other.heroBgTo,   t)!,
      text1:      Color.lerp(text1,      other.text1,      t)!,
      text2:      Color.lerp(text2,      other.text2,      t)!,
      text3:      Color.lerp(text3,      other.text3,      t)!,
      positive:   Color.lerp(positive,   other.positive,   t)!,
      negative:   Color.lerp(negative,   other.negative,   t)!,
      warning:    Color.lerp(warning,    other.warning,    t)!,
    );
  }
}
