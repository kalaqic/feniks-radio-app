import 'package:feniksflutter/models/radio_player_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
}

class Sim {
  Sim([DateTime? start])
    : clock = FakeClock(start ?? DateTime(2026, 1, 5, 9, 0))  {
    model = RadioPlayerModel(
      clock: clock.call,
      enableSync: false,
      enablePersistence: false,
    );
    model.debugTick(listening: false);
  }

  final FakeClock clock;
  late final RadioPlayerModel model;

  void listen(Duration d, {bool stop = true}) {
    model.debugTick(listening: true);
    for (var i = 0; i < d.inSeconds; i++) {
      clock.now = clock.now.add(const Duration(seconds: 1));
      model.debugTick(listening: true);
    }
    if (stop) pause();
  }

  void pause() {
    clock.now = clock.now.add(const Duration(seconds: 1));
    model.debugTick(listening: false);
  }

  void goTo(DateTime t) {
    clock.now = t;
    model.debugTick(listening: false);
  }

  void nextDay([int days = 1]) {
    final n = clock.now;
    goTo(DateTime(n.year, n.month, n.day + days, n.hour, n.minute));
  }

  bool has(String id) => model.hasAchievement(Achievements.byId(id)!);
}

const min = Duration(minutes: 1);

void main() {
  group('Listening points', () {
    test('2 points for every full minute', () {
      final s = Sim();
      s.listen(const Duration(seconds: 59));
      expect(s.model.listeningPoints, 0);
      s.listen(const Duration(seconds: 1));
      expect(s.model.listeningPoints, 2);
      s.listen(min * 24);
      expect(s.model.listeningPoints, 50);
      expect(s.model.totalListeningMinutes, 25);
    });

    test('pressing play/pause many times gives no points or sessions', () {
      final s = Sim();
      for (var i = 0; i < 100; i++) {
        s.listen(const Duration(seconds: 3));
      }

      expect(s.model.totalListeningMinutes, 5);
      expect(s.model.listeningPoints, 10);
      expect(s.model.sessionCount, 0);

      expect(s.model.earnedAchievements.map((e) => e.id), ['first_listen']);
    });

    test('buffering (playing but not ready) is not counted', () {
      final s = Sim();
      s.model.debugTick(listening: true);
      for (var i = 0; i < 600; i++) {
        s.clock.now = s.clock.now.add(const Duration(seconds: 1));
        s.model.debugTick(listening: false);
      }
      expect(s.model.totalListeningMinutes, 0);
    });

    test('total points = listening points + badge points', () {
      final s = Sim();
      s.listen(min * 61);
      final badgeSum = s.model.earnedAchievements.fold<int>(
        0,
        (sum, e) => sum + e.achievement.points,
      );
      expect(s.model.achievementPoints, badgeSum);
      expect(
        s.model.totalFeniksPoints,
        s.model.listeningPoints + s.model.achievementPoints,
      );
    });
  });

  group('Badges', () {
    test('first listen only after audio really plays', () {
      final s = Sim();
      expect(s.has('first_listen'), isFalse);
      s.listen(const Duration(seconds: 2));
      expect(s.has('first_listen'), isTrue);
    });

    test('daily listening adds up within one day', () {
      final s = Sim(DateTime(2026, 1, 5, 8, 0));
      s.listen(min * 40);
      s.listen(min * 20);
      expect(s.has('first_hour'), isTrue);
      expect(s.has('marathon'), isFalse);
    });

    test('daily total resets at midnight', () {
      final s = Sim(DateTime(2026, 1, 5, 23, 30));
      s.listen(min * 59);
      expect(s.model.todayListeningMinutes, inInclusiveRange(28, 30));
      expect(s.has('first_hour'), isFalse);
    });

    test('"bez pauze" needs one continuous session', () {
      final s = Sim();
      s.listen(min * 20);
      s.listen(min * 20);
      expect(s.has('quality_listener'), isFalse);
      s.listen(min * 30);
      expect(s.has('quality_listener'), isTrue);
    });

    test('sessions count only from 10 minutes', () {
      final s = Sim();
      for (var i = 0; i < 10; i++) {
        s.listen(min * 9);
      }
      expect(s.model.sessionCount, 0);
      for (var i = 0; i < 10; i++) {
        s.listen(min * 10);
      }
      expect(s.model.sessionCount, 10);
      expect(s.has('ten_sessions'), isTrue);
    });

    test('streak of 7 days', () {
      final s = Sim();
      for (var d = 0; d < 7; d++) {
        s.listen(min * 6);
        expect(s.model.consecutiveDays, d + 1);
        s.nextDay();
      }
      expect(s.has('daily_listener'), isTrue);
    });

    test('a missed day breaks the streak', () {
      final s = Sim();
      for (var d = 0; d < 8; d++) {
        if (d != 3) s.listen(min * 6);
        s.nextDay();
      }
      expect(s.has('daily_listener'), isFalse);
      expect(s.model.totalListeningDays, 7);
      expect(s.has('first_week'), isTrue);
    });

    test('less than 5 minutes does not count as a listening day', () {
      final s = Sim();
      for (var d = 0; d < 7; d++) {
        s.listen(min * 4);
        s.nextDay();
      }
      expect(s.model.totalListeningDays, 0);
      expect(s.model.consecutiveDays, 0);
    });

    test('streak survives daylight saving changes', () {
      for (final start in [
        DateTime(2026, 3, 27, 9),
        DateTime(2026, 10, 23, 9),
      ]) {
        final s = Sim(start);
        for (var d = 0; d < 5; d++) {
          s.goTo(DateTime(start.year, start.month, start.day + d, 9));
          s.listen(min * 6);
        }
        expect(s.model.consecutiveDays, 5);
      }
    });

    test('streak shows 0 after a missed day', () {
      final s = Sim();
      s.listen(min * 6);
      expect(s.model.consecutiveDays, 1);
      s.nextDay(2);
      expect(s.model.consecutiveDays, 0);
    });

    test('time of day needs different days', () {
      final s = Sim(DateTime(2026, 1, 5, 6, 0));
      for (var i = 0; i < 5; i++) {
        s.listen(min * 6);
      }
      expect(s.has('early_bird'), isFalse);
      for (var d = 0; d < 4; d++) {
        s.goTo(DateTime(2026, 1, 6 + d, 6, 0));
        s.listen(min * 6);
      }
      expect(s.has('early_bird'), isTrue);
    });

    test('listening across 22h counts for the night slot', () {
      final s = Sim(DateTime(2026, 1, 5, 21, 50));
      for (var d = 0; d < 5; d++) {
        s.goTo(DateTime(2026, 1, 5 + d, 21, 50));
        s.listen(min * 20);
      }
      expect(s.has('night_owl'), isTrue);
    });

    test('weekend warrior: 8 weekend days', () {
      final s = Sim(DateTime(2026, 1, 10, 12, 0));
      for (var w = 0; w < 4; w++) {
        s.goTo(DateTime(2026, 1, 10 + w * 7, 12, 0));
        s.listen(min * 6);
        s.goTo(DateTime(2026, 1, 11 + w * 7, 12, 0));
        s.listen(min * 6);
      }
      expect(s.has('weekend_warrior'), isTrue);
    });

    test('workweek needs Mon–Fri of the same week', () {
      final s = Sim(DateTime(2026, 1, 6, 12, 0));
      for (final day in [6, 7, 8, 9, 12]) {
        s.goTo(DateTime(2026, 1, day, 12, 0));
        s.listen(min * 6);
      }
      expect(s.has('workday_warrior'), isFalse);
      for (final day in [13, 14, 15, 16]) {
        s.goTo(DateTime(2026, 1, day, 12, 0));
        s.listen(min * 6);
      }
      expect(s.has('workday_warrior'), isTrue);
    });

    test('favorites: 10 songs, station jingle cannot be added', () {
      final s = Sim();
      s.model.debugSetSong('Feniks Radio', 'Samo dobre vijesti!');
      s.model.toggleFavorite();
      expect(s.model.favoriteSongs, isEmpty);
      for (var i = 0; i < 10; i++) {
        s.model.debugSetSong('Pjesma $i', 'Izvođač');
        s.model.toggleFavorite();
      }
      expect(s.model.favoriteSongs.length, 10);
      expect(s.has('music_lover'), isTrue);

      s.model.toggleFavorite();
      s.model.toggleFavorite();
      final ids = s.model.earnedAchievements.map((e) => e.id).toList();
      expect(ids.where((id) => id == 'music_lover').length, 1);
    });

    test('songs only count while listening', () {
      final s = Sim();
      for (var i = 0; i < 60; i++) {
        s.model.debugSetSong('Pjesma $i', 'Izvođač');
      }
      expect(s.has('song_discoverer'), isFalse);
      s.model.debugTick(listening: true);
      for (var i = 0; i < 50; i++) {
        s.model.debugSetSong('Pjesma $i', 'Izvođač');
      }
      expect(s.has('song_discoverer'), isTrue);
    });

    test('explorer needs all 6 pages', () {
      final s = Sim();
      for (final p in ProgressRules.explorablePages.take(5)) {
        s.model.trackPageVisit(p);
      }
      s.model.trackPageVisit('/ether-messages');
      expect(s.has('app_explorer'), isFalse);
      s.model.trackPageVisit(ProgressRules.explorablePages.last);
      expect(s.has('app_explorer'), isTrue);
    });

    test('every badge can be earned, each exactly once', () {
      final s = Sim(DateTime(2026, 1, 5, 9, 0));

      s.listen(const Duration(hours: 6));

      const slotStarts = [1, 6, 9, 13, 19, 22];
      for (var d = 1; d <= 180; d++) {
        final h = slotStarts[d % slotStarts.length];
        s.goTo(DateTime(2026, 1, 5 + d, h, h == 22 ? 10 : 0));
        s.listen(min * 34);
      }
      for (var i = 0; i < 250; i++) {
        s.model.debugTick(listening: true);
        s.model.debugSetSong('Pjesma $i', 'Izvođač');
        if (i < 100) s.model.toggleFavorite();
      }
      for (final p in ProgressRules.explorablePages) {
        s.model.trackPageVisit(p);
      }

      final earned = s.model.earnedAchievements.map((e) => e.id);
      expect(earned.toSet(), s.model.allAchievements.map((a) => a.id).toSet());
      expect(earned.length, earned.toSet().length, reason: 'no duplicates');

      final allPoints = s.model.allAchievements.fold<int>(
        0,
        (sum, a) => sum + a.points,
      );
      expect(s.model.achievementPoints, allPoints);

      expect(allPoints, lessThanOrEqualTo(9500));
      expect(s.model.allAchievements.length, lessThanOrEqualTo(35));
    });

    test('badge ids, names and icons are unique', () {
      expect(
        Achievements.all.map((a) => a.id).toSet().length,
        Achievements.all.length,
      );
      expect(
        Achievements.appExplorer.requirement,
        ProgressRules.explorablePages.length,
      );
      const badges = Achievements.all;
      final names = badges.map((a) => a.name).toList();
      final icons = badges.map((a) => a.icon).toList();
      expect(names.toSet().length, names.length);
      expect(icons.toSet().length, icons.length);
    });
  });

  group('Saving and loading', () {
    test('daily listening history is kept for 90 days', () {
      final s = Sim(DateTime(2026, 1, 5, 9));
      s.listen(min * 12);
      s.nextDay();
      s.listen(min * 3);
      var history = s.model.progressToJson()['dailyMinutes'] as Map;
      expect(history['2026-01-05'], 12);
      expect(history['2026-01-06'], 3);

      s.goTo(DateTime(2026, 4, 10, 9));
      s.listen(min * 1);
      history = s.model.progressToJson()['dailyMinutes'] as Map;
      expect(history.containsKey('2026-01-05'), isFalse);
      expect(history['2026-04-10'], 1);
    });

    test('save -> load keeps everything', () {
      final a = Sim();
      a.listen(min * 65);
      a.nextDay();
      a.listen(min * 6);
      final data = a.model.progressToJson();

      final b = Sim(a.clock.now);
      b.model.loadUserProgress('u1', data);
      expect(b.model.totalListeningMinutes, a.model.totalListeningMinutes);
      expect(b.model.listeningPoints, a.model.listeningPoints);
      expect(b.model.achievementPoints, a.model.achievementPoints);
      expect(b.model.consecutiveDays, a.model.consecutiveDays);
      expect(
        b.model.earnedAchievements.map((e) => e.id).toSet(),
        a.model.earnedAchievements.map((e) => e.id).toSet(),
      );
    });

    test('listening before login is added, not lost', () {
      final saved = Sim();
      saved.listen(min * 30);
      final data = saved.model.progressToJson();

      final s = Sim(saved.clock.now.add(const Duration(minutes: 5)));
      s.listen(min * 15);
      s.model.loadUserProgress('u1', data);
      expect(s.model.totalListeningMinutes, 45);
      expect(s.model.todayListeningMinutes, 45);
      expect(s.model.loadedUserId, 'u1');
    });

    test('logout clears progress', () {
      final s = Sim();
      s.listen(min * 30);
      s.model.loadUserProgress('u1', s.model.progressToJson());
      s.model.resetProgress();
      expect(s.model.totalFeniksPoints, 0);
      expect(s.model.earnedAchievements, isEmpty);
      expect(s.model.loadedUserId, isNull);
    });
  });
}
