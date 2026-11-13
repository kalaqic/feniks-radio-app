import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/log.dart';
import 'app_colors.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadSavedTheme();
  }

  static const _prefKey = 'settings.darkMode';

  bool _isDarkMode = false;

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKey);
      if (saved != null && saved != _isDarkMode) {
        _isDarkMode = saved;
        notifyListeners();
      }
    } catch (e) {
      logError('Loading saved theme', e);
    }
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_prefKey, isDark))
        .catchError((Object e) {
          logError('Saving theme', e);
          return false;
        });
  }

  static final lightTheme = _build(AppColors.light, Brightness.light);
  static final darkTheme = _build(AppColors.dark, Brightness.dark);

  static TextTheme _light(TextTheme t) => t.copyWith(
    bodySmall: t.bodySmall?.copyWith(fontWeight: FontWeight.w300),
    bodyMedium: t.bodyMedium?.copyWith(fontWeight: FontWeight.w300),
    bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w300),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w300),
    titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w300),
    labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w400),
  );

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTheme.fontFamily,
    );
    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.raspberry,
        brightness: brightness,
      ).copyWith(
        primary: AppTheme.raspberry,
        onPrimary: Colors.white,
        surface: c.surface,
        onSurface: c.text,
      ),
      // Body text is Lexend Light (300), like on radiofeniks.com.
      textTheme: _light(
        base.textTheme.apply(
          fontFamily: AppTheme.fontFamily,
          bodyColor: c.text,
          displayColor: c.ink,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppTheme.raspberry,
        selectionColor: AppTheme.raspberry.withValues(alpha: 0.25),
        selectionHandleColor: AppTheme.raspberry,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        hintStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: c.muted,
        ),
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: c.muted,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: c.muted,
        ),
        errorStyle: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          color: AppTheme.raspberry,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: c.fieldLine),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.raspberry, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.raspberry),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.raspberry, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTheme.raspberry
              : c.track,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.button,
        contentTextStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        actionTextColor: AppTheme.blue,
        shape: StadiumBorder(),
        insetPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTheme.raspberry,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
