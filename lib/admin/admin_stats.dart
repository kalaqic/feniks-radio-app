import '../models/achievement.dart';
import '../models/achievements.dart';
import 'admin_data.dart';

class DayStat {
  const DayStat(this.day, this.listeners, this.minutes);

  final DateTime day;
  final int listeners;
  final int minutes;
}

class AchievementStat {
  const AchievementStat(this.achievement, this.users);

  final Achievement achievement;
  final int users;
}

class SongStat {
  const SongStat(this.song, this.users);

  final String song;
  final int users;
}

class AdminStats {
  AdminStats._({
    required this.totalUsers,
    required this.listeningNow,
    required this.activeNow,
    required this.listenedToday,
    required this.minutesToday,
    required this.listenedLast7Days,
    required this.listenedLast30Days,
    required this.listenedEveryDayLast7,
    required this.newUsersLast7Days,
    required this.retentionEligible,
    required this.retained,
    required this.totalMinutesAllTime,
    required this.minutesLast7Days,
    required this.last14Days,
    required this.topAchievements,
    required this.topFavorites,
  });

  factory AdminStats.compute(
    List<AdminUser> users,
    List<PresenceEntry> presence,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);

    bool listenedWithin(AdminUser u, int days) {
      for (var i = 0; i < days; i++) {
        if (u.minutesOn(daysAgo(i)) > 0) return true;
      }
      return false;
    }

    bool listenedEveryDay(AdminUser u) {
      for (var i = 1; i <= 7; i++) {
        if (u.minutesOn(daysAgo(i)) == 0) return false;
      }
      return true;
    }

    final fresh = presence.where((p) => p.isFresh(now)).toList();

    var minutesLast7Days = 0;
    for (final u in users) {
      for (var i = 0; i < 7; i++) {
        minutesLast7Days += u.minutesOn(daysAgo(i));
      }
    }

    final last14Days = [
      for (var i = 13; i >= 0; i--)
        DayStat(
          daysAgo(i),
          users.where((u) => u.minutesOn(daysAgo(i)) > 0).length,
          users.fold<int>(0, (total, u) => total + u.minutesOn(daysAgo(i))),
        ),
    ];

    final retentionEligible = users.where((u) {
      final created = u.createdAt;
      return created != null && !created.isAfter(daysAgo(7));
    }).toList();

    final achievementCounts = <Achievement, int>{};
    for (final u in users) {
      for (final e in u.achievements) {
        achievementCounts[e.achievement] =
            (achievementCounts[e.achievement] ?? 0) + 1;
      }
    }
    final topAchievements = [
      for (final a in Achievements.all)
        AchievementStat(a, achievementCounts[a] ?? 0),
    ]..sort((a, b) => b.users.compareTo(a.users));

    final songCounts = <String, int>{};
    for (final u in users) {
      for (final song in u.favorites.toSet()) {
        songCounts[song] = (songCounts[song] ?? 0) + 1;
      }
    }
    final topFavorites = [
      for (final entry in songCounts.entries) SongStat(entry.key, entry.value),
    ]..sort((a, b) => b.users.compareTo(a.users));

    return AdminStats._(
      totalUsers: users.length,
      listeningNow: fresh.where((p) => p.listening).length,
      activeNow: fresh.where((p) => p.active).length,
      listenedToday: users.where((u) => u.minutesOn(today) > 0).length,
      minutesToday: users.fold<int>(0, (total, u) => total + u.minutesOn(today)),
      listenedLast7Days: users.where((u) => listenedWithin(u, 7)).length,
      listenedLast30Days: users.where((u) => listenedWithin(u, 30)).length,
      listenedEveryDayLast7: users.where(listenedEveryDay).length,
      newUsersLast7Days: users.where((u) {
        final created = u.createdAt;
        return created != null && created.isAfter(daysAgo(7));
      }).length,
      retentionEligible: retentionEligible.length,
      retained: retentionEligible.where((u) => listenedWithin(u, 7)).length,
      totalMinutesAllTime: users.fold<int>(0, (total, u) => total + u.totalMinutes),
      minutesLast7Days: minutesLast7Days,
      last14Days: last14Days,
      topAchievements: topAchievements,
      topFavorites: topFavorites.take(10).toList(),
    );
  }

  final int totalUsers;
  final int listeningNow;
  final int activeNow;
  final int listenedToday;
  final int minutesToday;
  final int listenedLast7Days;
  final int listenedLast30Days;
  final int listenedEveryDayLast7;
  final int newUsersLast7Days;
  final int retentionEligible;
  final int retained;
  final int totalMinutesAllTime;
  final int minutesLast7Days;
  final List<DayStat> last14Days;
  final List<AchievementStat> topAchievements;
  final List<SongStat> topFavorites;

  double shareOfUsers(int part) =>
      totalUsers == 0 ? 0 : part * 100 / totalUsers;

  double get retentionPercent =>
      retentionEligible == 0 ? 0 : retained * 100 / retentionEligible;

  double get avgMinutesPerListenerToday =>
      listenedToday == 0 ? 0 : minutesToday / listenedToday;

  double get avgDailyMinutesPerWeeklyListener =>
      listenedLast7Days == 0 ? 0 : minutesLast7Days / 7 / listenedLast7Days;
}
