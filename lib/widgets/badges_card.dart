import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'badge_style.dart';
import 'ui.dart';

/// One compact row on the home screen: badge progress when logged in, a
/// short sign-in invitation when not. Details are one tap away.
class BadgesCard extends StatelessWidget {
  const BadgesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();
    if (!context.watch<AuthService>().isAuthenticated) {
      return _SignInRow(preview: model.allAchievements.take(3).toList());
    }

    final colors = colorsOf(context);
    final earned = model.earnedAchievements;
    final total = model.allAchievements.length;
    final share = total > 0 ? earned.length / total : 0.0;
    // Newest earned badges, or the first ones still to win.
    final shown = earned.isEmpty
        ? [
            for (final a in model.allAchievements.take(3))
              (achievement: a, earned: false),
          ]
        : [
            for (final e in earned.reversed.take(3))
              (achievement: e.achievement, earned: true),
          ];

    return Semantics(
      button: true,
      label: 'Moje značke, ${earned.length} od $total osvojeno',
      child: Pressable(
        scale: .98,
        onTap: () => Navigator.pushNamed(context, Routes.badges),
        child: Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              _Ring(value: share, count: earned.length),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moje značke',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${earned.length} od $total osvojeno',
                      style: TextStyle(fontSize: 13, color: colors.muted),
                    ),
                  ],
                ),
              ),
              _FannedBadges(badges: shown),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 20, color: colors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// Raspberry row that invites logged-out users to collect badges.
class _SignInRow extends StatelessWidget {
  const _SignInRow({required this.preview});

  final List<Achievement> preview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Prijavi se i skupljaj značke',
      child: Pressable(
        scale: .98,
        onTap: () => Navigator.pushNamed(context, Routes.login),
        child: Container(
          color: AppTheme.raspberry,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Row(
            children: [
              _FannedBadges(
                badges: [
                  for (final a in preview) (achievement: a, earned: false),
                ],
                locked: true,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skupljaj značke dok slušaš',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Prijavi se i otključavaju se same',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Up to three badge tiles laid over each other like a small hand of cards,
/// which fan out once when they appear.
class _FannedBadges extends StatelessWidget {
  const _FannedBadges({required this.badges, this.locked = false});

  final List<({Achievement achievement, bool earned})> badges;

  /// White, see-through tiles for the raspberry sign-in row.
  final bool locked;

  static const _size = 30.0;
  static const _step = 18.0;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    final width = _size + _step * (badges.length - 1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => SizedBox(
        width: width,
        height: _size + 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (i, badge) in badges.indexed.toList().reversed)
              Positioned(
                left: _step * i * t,
                top: 3,
                child: Transform.rotate(
                  angle: (i - (badges.length - 1) / 2) * .12 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: locked
                            ? AppTheme.raspberry
                            : colorsOf(context).surface,
                        width: 2,
                      ),
                    ),
                    child: BadgeIcon(
                      achievement: badge.achievement,
                      earned: badge.earned,
                      size: _size,
                      lockedBackground: locked
                          ? Colors.white.withValues(alpha: .25)
                          : null,
                      lockedForeground: locked ? Colors.white : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Thin circle that fills up to [value] with the earned count inside.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.count});

  final double value;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        painter: _RingPainter(
          value: v,
          color: AppTheme.blue,
          track: colors.track,
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas
      ..drawArc(rect, 0, math.pi * 2, false, paint..color = track)
      ..drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
