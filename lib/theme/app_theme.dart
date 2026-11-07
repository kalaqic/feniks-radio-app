import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color primary = Color(0xFFEB6556);
  static const Color primaryLight = Color(0xFFFF8A75);
  static const Color primaryDark = Color(0xFFD54532);
  static const Color accentDark = Color(0xFFE55039);

  static const Color background = Color(0xFF0A0A0F);
  static const Color backgroundLight = Color(0xFF1A1A2E);
  static const Color backgroundMedium = Color(0xFF16213E);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF8E8E93);

  static const Color cardBackground = Color(0x08FFFFFF);
  static const Color cardBorder = Color(0x14FFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient backgroundGradient = RadialGradient(
    radius: 1.2,
    colors: [backgroundLight, backgroundMedium, background],
  );

  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
}
