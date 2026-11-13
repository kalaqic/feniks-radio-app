import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/app_theme.dart';

/// Icon and brand color for every achievement (the model keeps an emoji for
/// older screens; the redesign uses line icons in the site's colors).
abstract final class BadgeStyle {
  static const Map<String, IconData> _icons = {
    'first_listen': Icons.headphones_outlined,
    'app_explorer': Icons.explore_outlined,
    'first_hour': Icons.alarm_outlined,
    'marathon': Icons.directions_run,
    'five_hours': Icons.local_fire_department_outlined,
    'quality_listener': Icons.volume_up_outlined,
    'stable_connection': Icons.cell_tower,
    'ultra_marathon': Icons.rocket_launch_outlined,
    'ten_hours': Icons.schedule,
    'fifty_hours': Icons.hourglass_empty,
    'hundred_hours': Icons.workspace_premium_outlined,
    'ten_sessions': Icons.play_circle_outline,
    'fifty_sessions': Icons.radio_outlined,
    'hundred_sessions': Icons.track_changes,
    'daily_listener': Icons.today_outlined,
    'weekly_champion': Icons.military_tech_outlined,
    'loyal_fan': Icons.emoji_events_outlined,
    'legend': Icons.bolt,
    'first_week': Icons.date_range_outlined,
    'first_month': Icons.calendar_month_outlined,
    'loyal_user': Icons.diamond_outlined,
    'midnight_listener': Icons.dark_mode_outlined,
    'early_bird': Icons.wb_twilight,
    'morning_person': Icons.wb_sunny_outlined,
    'afternoon_listener': Icons.light_mode_outlined,
    'evening_enthusiast': Icons.nights_stay_outlined,
    'night_owl': Icons.bedtime_outlined,
    'weekend_warrior': Icons.celebration_outlined,
    'workday_warrior': Icons.work_outline,
    'music_lover': Icons.favorite_border,
    'music_collector': Icons.album_outlined,
    'music_expert': Icons.music_note_outlined,
    'music_master': Icons.queue_music,
    'song_discoverer': Icons.search,
    'song_hunter': Icons.library_music_outlined,
  };

  static IconData icon(Achievement a) => _icons[a.id] ?? Icons.star_outline;

  static Color color(Achievement a) => switch (a.category) {
    AchievementCategory.firstSteps ||
    AchievementCategory.totalListening ||
    AchievementCategory.weekendAndWorkweek ||
    AchievementCategory.favorites => AppTheme.raspberry,
    AchievementCategory.dailyListening ||
    AchievementCategory.sessions ||
    AchievementCategory.streaks => AppTheme.coral,
    AchievementCategory.withoutPause ||
    AchievementCategory.listeningDays ||
    AchievementCategory.timeOfDay ||
    AchievementCategory.discovery => AppTheme.blue,
  };
}

/// Square tile with the badge icon; grey when not earned.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({
    super.key,
    required this.achievement,
    required this.earned,
    this.size = 44,
    this.lockedBackground,
    this.lockedForeground,
    this.earnedForeground,
  });

  final Achievement achievement;
  final bool earned;
  final double size;
  final Color? lockedBackground;
  final Color? lockedForeground;

  /// Icon color of an earned badge; defaults to what reads best on its color.
  final Color? earnedForeground;

  @override
  Widget build(BuildContext context) {
    final bg = earned
        ? BadgeStyle.color(achievement)
        : lockedBackground ?? const Color(0xFFF3F1EF);
    final fg = earned
        ? earnedForeground ?? AppTheme.onBrand(bg)
        : lockedForeground ?? const Color(0x73151515);
    return Container(
      width: size,
      height: size,
      color: bg,
      child: Icon(BadgeStyle.icon(achievement), size: size * .5, color: fg),
    );
  }
}
