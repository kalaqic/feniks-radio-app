import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/badge_style.dart';
import '../widgets/ui.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.badges);
      }
    });
  }

  void _openBadge(Achievement badge, bool loggedIn) {
    final model = context.read<RadioPlayerModel>();
    final earnedAt = model.earnedAchievements
        .where((e) => e.id == badge.id)
        .firstOrNull
        ?.earnedAt;
    final earned = loggedIn && earnedAt != null;

    showAppSheet<void>(
      context,
      builder: (sheetContext) {
        final colors = colorsOf(sheetContext);
        final status = earned
            ? 'Osvojeno ${_formatDate(earnedAt)}'
            : loggedIn
            ? 'Još nije osvojeno'
            : 'Zaključano';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BadgeIcon(
                achievement: badge,
                earned: earned,
                size: 56,
                lockedBackground: colors.surfaceHover,
                lockedForeground: colors.muted,
              ),
            ),
            const SizedBox(height: 14),
            Text(status, style: TextStyle(fontSize: 13, color: colors.muted)),
            const SizedBox(height: 14),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              badge.description,
              style: TextStyle(fontSize: 16, height: 1.6, color: colors.text),
            ),
            const SizedBox(height: 24),
            if (loggedIn)
              PillButton(
                label: 'Zatvori i vrati se na značke',
                onPressed: () => Navigator.pop(sheetContext),
              )
            else ...[
              PillButton(
                label: 'Prijavi se i osvoji ovu značku',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, Routes.login);
                },
              ),
              const SizedBox(height: 6),
              Center(
                child: TextLink(
                  'Zatvori',
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final model = context.watch<RadioPlayerModel>();
    final loggedIn = context.watch<AuthService>().isAuthenticated;
    final earned = loggedIn ? model.earnedAchievements.length : 0;
    final total = model.allAchievements.length;
    var tileIndex = 0;
    var sectionIndex = 0;

    return StripedPage(
      children: [
        const FadeSlideIn(child: BackLink('Nazad na početnu')),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: FadeSlideIn(
            delay: Duration(milliseconds: 40),
            child: PageTitle('Značke'),
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: loggedIn
              ? _Progress(earned: earned, total: total)
              : const LoginPrompt(
                  title: 'Skupljaj značke uz radio',
                  message:
                      'Prijavi se i značke se otključavaju same dok slušaš.',
                ),
        ),
        for (final MapEntry(key: category, value: badges)
            in model.achievementsByCategory.entries)
          if (badges.isNotEmpty)
            FadeSlideIn(
              delay: Duration(
                milliseconds: 140 + 80 * math.min(sectionIndex++, 6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            category.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: colors.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${loggedIn ? badges.where(model.hasAchievement).length : 0} / ${badges.length}',
                          style: TextStyle(fontSize: 13, color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final badge in badges)
                            SizedBox(
                              width: width,
                              child: FadeSlideIn(
                                delay: Duration(
                                  milliseconds:
                                      200 + 30 * math.min(tileIndex++, 20),
                                ),
                                offset: const Offset(0, 10),
                                child: _BadgeTile(
                                  badge: badge,
                                  earned:
                                      loggedIn && model.hasAchievement(badge),
                                  onTap: () => _openBadge(badge, loggedIn),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final days = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
    if (days <= 0) return 'danas';
    if (days == 1) return 'juče';
    if (days < 7) return 'prije $days dana';
    return '${date.day}.${date.month}.${date.year}.';
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.blue,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUp(
                value: earned,
                style: const TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                ' / $total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.ink,
                ),
              ),
              const Spacer(),
              const Text(
                'osvojeno',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressLine(
            value: total > 0 ? earned / total : 0,
            color: AppTheme.ink,
            track: AppTheme.ink.withValues(alpha: .18),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.earned,
    required this.onTap,
  });

  final Achievement badge;
  final bool earned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Semantics(
      button: true,
      label: '${badge.name}, ${earned ? 'osvojeno' : 'nije osvojeno'}',
      child: Pressable(
        onTap: onTap,
        child: Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(6, 18, 6, 14),
          child: Column(
            children: [
              BadgeIcon(
                achievement: badge,
                earned: earned,
                lockedBackground: colors.surfaceHover,
                lockedForeground: colors.muted,
              ),
              const SizedBox(height: 10),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                  color: earned ? colors.ink : colors.soft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
