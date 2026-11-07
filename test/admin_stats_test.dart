import 'package:feniksflutter/admin/admin_data.dart';
import 'package:feniksflutter/admin/admin_stats.dart';
import 'package:feniksflutter/models/achievements.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 3, 10, 12);

String day(int daysAgo) =>
    dayKey(DateTime(now.year, now.month, now.day - daysAgo));

AdminUser user(
  String uid, {
  Map<String, int> daily = const {},
  DateTime? createdAt,
  List<String> badges = const [],
  List<String> favorites = const [],
}) {
  return AdminUser.fromFirestore(uid, {
    'displayName': uid,
    if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
    'achievements': {
      'totalListeningSeconds':
          daily.values.fold<int>(0, (total, m) => total + m) * 60,
      'dailyMinutes': daily,
      'favoriteSongs': favorites,
      'earnedBadges': [
        for (final id in badges) {'id': id, 'earnedDate': '2026-03-01'},
      ],
    },
  });
}

void main() {
  test('counts today, weekly and every-day listeners', () {
    final everyDay = {for (var i = 0; i <= 7; i++) day(i): 20};
    final users = [
      user('a', daily: everyDay),
      user('b', daily: {day(0): 10}),
      user('c', daily: {day(3): 5}),
      user('d', daily: {day(20): 5}),
      user('e'),
    ];
    final stats = AdminStats.compute(users, const [], now);

    expect(stats.totalUsers, 5);
    expect(stats.listenedToday, 2);
    expect(stats.minutesToday, 30);
    expect(stats.avgMinutesPerListenerToday, 15);
    expect(stats.listenedLast7Days, 3);
    expect(stats.listenedLast30Days, 4);
    expect(stats.listenedEveryDayLast7, 1);
    expect(stats.shareOfUsers(stats.listenedEveryDayLast7), 20);
    expect(stats.last14Days.length, 14);
    expect(stats.last14Days.last.listeners, 2);
    expect(stats.last14Days.last.minutes, 30);
  });

  test('live counts use only recent presence', () {
    final presence = [
      PresenceEntry(
        uid: 'a',
        listening: true,
        active: true,
        platform: 'iOS',
        lastSeen: now.subtract(const Duration(minutes: 1)),
      ),
      PresenceEntry(
        uid: 'b',
        listening: false,
        active: true,
        platform: 'android',
        lastSeen: now.subtract(const Duration(minutes: 2)),
      ),
      PresenceEntry(
        uid: 'c',
        listening: true,
        active: true,
        platform: 'android',
        lastSeen: now.subtract(const Duration(minutes: 30)),
      ),
    ];
    final stats = AdminStats.compute(const [], presence, now);
    expect(stats.listeningNow, 1);
    expect(stats.activeNow, 2);
  });

  test('retention, new users, badges and favorite songs', () {
    final users = [
      user(
        'old-active',
        createdAt: DateTime(2026, 1, 1),
        daily: {day(2): 30},
        badges: ['first_listen', 'first_hour'],
        favorites: ['Pjesma A - X', 'Pjesma B - Y'],
      ),
      user(
        'old-gone',
        createdAt: DateTime(2026, 1, 1),
        badges: ['first_listen'],
        favorites: ['Pjesma A - X'],
      ),
      user('new', createdAt: DateTime(2026, 3, 8)),
    ];
    final stats = AdminStats.compute(users, const [], now);

    expect(stats.newUsersLast7Days, 1);
    expect(stats.retentionEligible, 2);
    expect(stats.retained, 1);
    expect(stats.retentionPercent, 50);

    expect(stats.topAchievements.first.achievement, Achievements.firstListen);
    expect(stats.topAchievements.first.users, 2);

    expect(stats.topFavorites.first.song, 'Pjesma A - X');
    expect(stats.topFavorites.first.users, 2);
  });

  test('points match the app rules', () {
    final u = user('a', daily: {day(0): 10}, badges: ['first_listen']);
    expect(u.points, 10 * 2 + Achievements.firstListen.points);
  });
}
