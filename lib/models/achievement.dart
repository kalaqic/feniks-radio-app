import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart' show Color;

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

  final String title;
}

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

  final String id;

  final String name;
  final String description;

  final String icon;

  final Color color;

  final int requirement;

  final int points;

  final AchievementCategory category;
}

@immutable
class EarnedAchievement {
  const EarnedAchievement(this.achievement, this.earnedAt);

  final Achievement achievement;
  final DateTime earnedAt;

  String get id => achievement.id;
}
