import '../config/routes.dart';

/// Rules for points and progress tracking, in one place.
abstract final class ProgressRules {
  /// Listening points: [pointsPerMinute] for every full minute of real
  /// listening.
  static const int pointsPerMinute = 2;

  /// Minutes needed in a day for it to count as a "listening day"
  /// (streaks, weekends, work weeks and total listening days).
  static const int minMinutesForListeningDay = 5;

  /// Minutes needed within a time slot for that day to count towards the
  /// time-of-day achievements.
  static const int minMinutesForTimeSlot = 5;

  /// A session counts for the session achievements once it lasts this long.
  static const int minMinutesForSession = 10;

  /// Progress is saved at least this often while listening.
  static const Duration saveInterval = Duration(minutes: 5);

  /// Pages that count towards the "Istraživač Aplikacije" achievement.
  static const List<String> explorablePages = [
    Routes.home,
    Routes.leaderboard,
    Routes.badges,
    Routes.favorites,
    Routes.profile,
    Routes.settings,
  ];
}

/// Shown when there is no song info (jingles, metadata unavailable).
const String kFallbackTitle = 'Feniks Radio';
const String kFallbackArtist = 'Samo dobre vijesti!';
