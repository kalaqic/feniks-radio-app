import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class AppBackgroundLayer extends StatefulWidget {
  const AppBackgroundLayer({super.key});

  @override
  State<AppBackgroundLayer> createState() => _AppBackgroundLayerState();
}

class AppBackgroundOverlay extends StatefulWidget {
  const AppBackgroundOverlay({super.key});

  @override
  State<AppBackgroundOverlay> createState() => _AppBackgroundOverlayState();
}

class _AppBackgroundOverlayState extends State<AppBackgroundOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _shift = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _shift,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                top: -120 + (_shift.value * 40),
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: isDarkMode ? 0.06 : 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: -140 - (_shift.value * 35),
                left: -90,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryDark.withValues(alpha: isDarkMode ? 0.05 : 0.035),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppBackgroundLayerState extends State<AppBackgroundLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _shift = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _shift,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDarkMode
                        ? AppTheme.backgroundGradient
                        : const LinearGradient(
                            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: -120 + (_shift.value * 40),
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: isDarkMode ? 0.12 : 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -140 - (_shift.value * 35),
                left: -90,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryDark.withValues(alpha: isDarkMode ? 0.10 : 0.06),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
