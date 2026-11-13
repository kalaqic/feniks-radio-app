import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Goes up by one every time a heart lands on the "Moj profil" tab.
final ValueNotifier<int> favoriteLanded = ValueNotifier(0);

/// True while there is a new favorite song the user has not looked at yet;
/// shows a small dot on the "Moj profil" tab.
final ValueNotifier<bool> hasNewFavorite = ValueNotifier(false);

/// Where the "Moj profil" icon sits inside an overlay of [size], with
/// [bottomInset] being the bottom safe area. Hearts fly there.
Offset profileTabCenter(Size size, double bottomInset) {
  const horizontal = 24.0;
  final x = horizontal + (size.width - horizontal * 2) * 5 / 6;
  final bottom = bottomInset < 12 ? 12.0 : bottomInset;
  // Below the icon: gap 6, label ~15, gap 6, line 2.
  final y = size.height - bottom - 29 - 11;
  return Offset(x, y);
}

/// Bottom navigation: Početna, Ljestvica, Moj profil.
class CommonFooter extends StatelessWidget {
  const CommonFooter({super.key, required this.currentRoute});

  final String currentRoute;

  void _open(BuildContext context, String route) {
    if (route == currentRoute) return;
    if (route == Routes.home) {
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (route, icon, label) in const [
              (Routes.home, Icons.home_outlined, 'Početna'),
              (Routes.leaderboard, Icons.bar_chart_rounded, 'Ljestvica'),
              (Routes.profile, Icons.person_outline_rounded, 'Moj profil'),
            ])
              Expanded(
                child: _Tab(
                  icon: icon,
                  label: label,
                  active: route == currentRoute,
                  catchesHearts: route == Routes.profile,
                  onTap: () => _open(context, route),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.catchesHearts = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Bounces when a favorite heart lands on it and shows the "new" dot.
  final bool catchesHearts;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 1.35).chain(
        CurveTween(curve: Curves.easeOut),
      ),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.35, end: 1).chain(
        CurveTween(curve: Curves.elasticOut),
      ),
      weight: 70,
    ),
  ]).animate(_bounce);

  @override
  void initState() {
    super.initState();
    if (widget.catchesHearts) favoriteLanded.addListener(_onLanded);
  }

  void _onLanded() {
    if (!mounted) return;
    Haptics.play(Haptic.light);
    _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    favoriteLanded.removeListener(_onLanded);
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final active = widget.active;
    final color = active ? colors.ink : colors.muted;
    return Semantics(
      button: true,
      selected: active,
      child: Pressable(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (context, child) => Transform.scale(
                scale: _scale.value,
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _bounce,
                    builder: (context, _) => Icon(
                      widget.icon,
                      size: 22,
                      // Flashes raspberry while it catches a heart.
                      color: Color.lerp(
                        color,
                        AppTheme.raspberry,
                        _bounce.isAnimating ? 1 - _bounce.value : 0,
                      ),
                    ),
                  ),
                  if (widget.catchesHearts)
                    Positioned(
                      right: -3,
                      top: -1,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: hasNewFavorite,
                        builder: (context, show, _) => AnimatedScale(
                          scale: show ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.raspberry,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w500 : FontWeight.w300,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: active ? 1 : 0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Container(
                width: 18 * v,
                height: 2,
                color: AppTheme.raspberry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
