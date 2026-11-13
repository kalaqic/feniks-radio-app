import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';
import 'badge_style.dart';
import 'ui.dart';

/// Popup shown when a badge is unlocked. Meant to be shown with
/// [showAppDialog].
class BadgeEarnedModal extends StatelessWidget {
  const BadgeEarnedModal({
    super.key,
    required this.badge,
    required this.onDismiss,
  });

  final Achievement badge;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .6, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: BadgeIcon(achievement: badge, earned: true, size: 64),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          offset: const Offset(0, 8),
          child: Text(
            'Značka osvojena',
            style: TextStyle(fontSize: 13, color: colors.muted),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 320),
          offset: const Offset(0, 8),
          child: PageTitle(badge.name, fontSize: 30),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 400),
          offset: const Offset(0, 8),
          child: Text(
            badge.description,
            style: TextStyle(fontSize: 16, height: 1.6, color: colors.text),
          ),
        ),
        const SizedBox(height: 14),
        CountUp(
          value: badge.points,
          delay: const Duration(milliseconds: 600),
          duration: const Duration(milliseconds: 900),
          format: (v) => '+$v poena',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.raspberry,
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 550),
          offset: const Offset(0, 8),
          child: Column(
            children: [
              PillButton(label: 'Nastavi slušanje', onPressed: onDismiss),
              const SizedBox(height: 16),
              TextLink(
                'Pogledaj sve svoje značke',
                padding: EdgeInsets.zero,
                onTap: () {
                  final navigator = Navigator.of(context);
                  onDismiss();
                  navigator.pushNamed(Routes.badges);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
