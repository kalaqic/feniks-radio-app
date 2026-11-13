import 'package:flutter/material.dart';

/// Brand colors and font, taken from radiofeniks.com.
abstract final class AppTheme {
  static const String fontFamily = 'Lexend';

  static const Color raspberry = Color(0xFFA65262);
  static const Color coral = Color(0xFFDC6D5D);
  static const Color blue = Color(0xFF6AA0DA);

  /// Orange used between coral and blue on the landing play button.
  static const Color orange = Color(0xFFE8894A);

  static const Color ink = Color(0xFF151515);
  static const Color text = Color(0xFF212529);
  static const Color button = Color(0xFF343A40);
  static const Color paper = Color(0xFFFAF9F8);
  static const Color white = Colors.white;

  /// Accent colors of the admin panel.
  static const Color primary = Color(0xFFEB6556);
  static const Color primaryDark = Color(0xFFD54532);

  /// Text and icon color that reads well on top of [background].
  static Color onBrand(Color background) =>
      background == raspberry || background == button ? white : ink;
}
