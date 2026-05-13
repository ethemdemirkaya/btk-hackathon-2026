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
