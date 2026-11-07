import 'package:flutter/material.dart';

/// Colors that differ between the light and the dark theme.
///
/// Use `AppColors.of(isDarkMode)` instead of writing
/// `isDarkMode ? darkColor : lightColor` in every widget.
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

  /// Titles and main text.
  final Color primaryText;

  /// Subtitles, labels and descriptions.
  final Color secondaryText;

  /// Hints, empty states and other low-emphasis text.
  final Color mutedText;

  /// Background of cards.
  final Color card;

  /// Background of list items and small boxes inside cards.
  final Color surface;

  /// Card and input borders.
  final Color border;

  /// Background of text fields.
  final Color inputFill;

  /// Card shadows.
  final Color shadow;

  static const AppColors light = AppColors._(
    primaryText: Color(0xFF1D1D1F),
    secondaryText: Color(0xFF757575), // grey 600
    mutedText: Color(0xFF9E9E9E), // grey 500
    card: Colors.white,
    surface: Color(0xFFFAFAFA), // grey 50
    border: Color(0xFFEEEEEE), // grey 200
    inputFill: Colors.white,
    shadow: Color(0x0D000000), // black 5%
  );

  static const AppColors dark = AppColors._(
    primaryText: Colors.white,
    secondaryText: Color(0xFFB0B0B0),
    mutedText: Color(0xFFB0B0B0),
    card: Color(0x08FFFFFF), // white 3%
    surface: Color(0x08FFFFFF), // white 3%
    border: Color(0x14FFFFFF), // white 8%
    inputFill: Color(0xFF16213E),
    shadow: Color(0x4D000000), // black 30%
  );

  static AppColors of(bool isDarkMode) => isDarkMode ? dark : light;
}
