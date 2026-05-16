import 'package:flutter/material.dart';
import 'colors.dart';

extension AppColorsX on BuildContext {
  AppColorTokens get appColors =>
      Theme.of(this).extension<AppColorTokens>() ?? AppColorTokens.dark;
}
