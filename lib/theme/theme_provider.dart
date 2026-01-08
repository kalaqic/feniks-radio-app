import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
  
  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
  
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF007AFF),
      primaryContainer: const Color(0xFFE3F2FD),
      secondary: const Color(0xFF5856D6),
      secondaryContainer: const Color(0xFFF3F2FF),
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFFAFAFA),
      outline: const Color(0xFFE5E5E7),
    ),
    fontFamily: 'SF Pro Display',
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: Color(0xFF1D1D1F),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1D1D1F),
        letterSpacing: -0.5,
      ),
    ),
  );
  
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF0A84FF),
      primaryContainer: const Color(0xFF1C1C1E),
      secondary: const Color(0xFF5E5CE6),
      secondaryContainer: const Color(0xFF1C1C1E),
      surface: const Color(0xFF1C1C1E),
      surfaceContainerHighest: const Color(0xFF2C2C2E),
      outline: const Color(0xFF38383A),
      onSurface: Colors.white,
      onPrimary: Colors.white,
    ),
    fontFamily: 'SF Pro Display',
    scaffoldBackgroundColor: const Color(0xFF000000),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      color: Color(0xFF1C1C1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    ),
  );
}