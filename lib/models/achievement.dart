import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart' show Color;

/// Groups of achievements, in the order they are shown on the badges page.
enum AchievementCategory {
  firstSteps('Prvi koraci'),
  dailyListening('Dnevno slušanje'),
  withoutPause('Bez pauze'),
  totalListening('Ukupno slušanje'),
  sessions('Sesije'),
  streaks('Nizovi'),
  listeningDays('Dani slušanja'),
  timeOfDay('Doba dana'),
  weekendAndWorkweek('Vikend i radni dan'),
  favorites('Omiljene pjesme'),
  discovery('Otkrivanje');

  const AchievementCategory(this.title);

  /// Section title shown to the user.
  final String title;
}

/// An achievement ("značka") the user can unlock.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirement,
    required this.points,
    required this.category,
  });

  /// Stable id, also used in saved progress. Never change an existing id.
  final String id;

  final String name;
  final String description;

  /// Emoji shown on the badge.
  final String icon;

  final Color color;

  /// Amount needed to unlock it (minutes, days, songs... depending on the
  /// category).
  final int requirement;

  /// Feniks points awarded when unlocked.
  final int points;

  final AchievementCategory category;
}

/// An achievement the user has unlocked, and when.
@immutable
class EarnedAchievement {
  const EarnedAchievement(this.achievement, this.earnedAt);

  final Achievement achievement;
  final DateTime earnedAt;

  String get id => achievement.id;
}
