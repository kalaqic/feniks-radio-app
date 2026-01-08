import 'package:flutter/material.dart';

class AppTheme {
  // Primary brand color - red
  static const Color primary = Color(0xFFEB6556);
  
  // Red color variations
  static const Color primaryLight = Color(0xFFFF8A75);
  static const Color primaryDark = Color(0xFFD54532);
  
  // Gradient colors
  static const Color gradientStart = Color(0xFFEB6556);
  static const Color gradientEnd = Color(0xFFD54532);
  static const Color gradientLight = Color(0xFFFF8A75);
  
  // Secondary red variations
  static const Color accent = Color(0xFFFF6B47);
  static const Color accentLight = Color(0xFFFF9578);
  static const Color accentDark = Color(0xFFE55039);
  
  // Background colors
  static const Color background = Color(0xFF0A0A0F);
  static const Color backgroundLight = Color(0xFF1A1A2E);
  static const Color backgroundMedium = Color(0xFF16213E);
  
  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF8E8E93);
  
  // Common gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    colors: [gradientLight, gradientStart],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Background gradient
  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      backgroundLight,
      backgroundMedium,
      background,
    ],
  );
  
  // Helper methods for colors with opacity
  static Color primaryWithOpacity(double opacity) => primary.withValues(alpha: opacity);
  static Color primaryLightWithOpacity(double opacity) => primaryLight.withValues(alpha: opacity);
  static Color primaryDarkWithOpacity(double opacity) => primaryDark.withValues(alpha: opacity);
  static Color whiteWithOpacity(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color blackWithOpacity(double opacity) => Colors.black.withValues(alpha: opacity);
  
  // Badge colors
  static const Color badgeBackground = primary;
  static const Color badgeBorder = primaryLight;
  
  // Button colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = primaryLight;
  static const Color buttonDisabled = Color(0xFF6B6B6B);
  
  // Card colors
  static Color cardBackground = whiteWithOpacity(0.03);
  static Color cardBorder = whiteWithOpacity(0.08);
  
  // Icon colors
  static const Color iconPrimary = primary;
  static const Color iconSecondary = primaryLight;
  static Color iconMuted = whiteWithOpacity(0.7);
}