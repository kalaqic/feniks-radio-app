import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colors that change between light and dark mode.
@immutable
class AppColors {
  const AppColors._({
    required this.background,
    required this.surface,
    required this.surfaceHover,
    required this.ink,
    required this.text,
    required this.muted,
    required this.divider,
    required this.track,
    required this.fieldLine,
    required this.soft,
    required this.button,
    required this.onButton,
  });

  /// Page background.
  final Color background;

  /// Flat blocks on top of the background.
  final Color surface;

  /// Pressed or hovered row inside a [surface].
  final Color surfaceHover;

  /// Headings and strong text.
  final Color ink;

  /// Body text.
  final Color text;

  /// Secondary text.
  final Color muted;

  /// Thin separators and field underlines.
  final Color divider;

  /// Empty part of progress bars and switches.
  final Color track;

  /// Underline of text fields and outline of the favorite button.
  final Color fieldLine;

  /// Slightly softer body text (artist names, footnotes).
  final Color soft;

  /// Main pill button.
  final Color button;
  final Color onButton;

  static const AppColors light = AppColors._(
    background: AppTheme.paper,
    surface: Colors.white,
    surfaceHover: Color(0xFFF3F1EF),
    ink: AppTheme.ink,
    text: AppTheme.text,
    muted: Color(0x99151515),
    divider: Color(0x12151515),
    track: Color(0x2E151515),
    fieldLine: Color(0x40151515),
    soft: Color(0xB3151515),
    button: AppTheme.button,
    onButton: Colors.white,
  );

  static const AppColors dark = AppColors._(
    background: AppTheme.ink,
    surface: Color(0xFF212529),
    surfaceHover: Color(0xFF2B3035),
    ink: Colors.white,
    text: Color(0xFFE9ECEF),
    muted: Color(0x99FFFFFF),
    divider: Color(0x1AFFFFFF),
    track: Color(0x2EFFFFFF),
    fieldLine: Color(0x40FFFFFF),
    soft: Color(0xB3FFFFFF),
    button: Colors.white,
    onButton: AppTheme.ink,
  );

  static AppColors of(bool isDarkMode) => isDarkMode ? dark : light;
}
