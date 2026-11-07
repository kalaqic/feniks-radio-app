import 'package:flutter/material.dart';

@immutable
class AppColors {
  const AppColors._({
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.card,
    required this.surface,
    required this.border,
    required this.inputFill,
    required this.shadow,
  });

  final Color primaryText;

  final Color secondaryText;

  final Color mutedText;

  final Color card;

  final Color surface;

  final Color border;

  final Color inputFill;

  final Color shadow;

  static const AppColors light = AppColors._(
    primaryText: Color(0xFF1D1D1F),
    secondaryText: Color(0xFF757575),
    mutedText: Color(0xFF9E9E9E),
    card: Colors.white,
    surface: Color(0xFFFAFAFA),
    border: Color(0xFFEEEEEE),
    inputFill: Colors.white,
    shadow: Color(0x0D000000),
  );

  static const AppColors dark = AppColors._(
    primaryText: Colors.white,
    secondaryText: Color(0xFFB0B0B0),
    mutedText: Color(0xFFB0B0B0),
    card: Color(0x08FFFFFF),
    surface: Color(0x08FFFFFF),
    border: Color(0x14FFFFFF),
    inputFill: Color(0xFF16213E),
    shadow: Color(0x4D000000),
  );

  static AppColors of(bool isDarkMode) => isDarkMode ? dark : light;
}
