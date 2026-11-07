import '../config/routes.dart';

abstract final class ProgressRules {
  static const int pointsPerMinute = 2;

  static const int minMinutesForListeningDay = 5;

  static const int minMinutesForTimeSlot = 5;

  static const int minMinutesForSession = 10;

  static const Duration saveInterval = Duration(minutes: 5);

  static const List<String> explorablePages = [
    Routes.home,
    Routes.leaderboard,
    Routes.badges,
    Routes.favorites,
    Routes.profile,
    Routes.settings,
  ];
}

const String kFallbackTitle = 'Feniks Radio';
const String kFallbackArtist = 'Samo dobre vijesti!';
