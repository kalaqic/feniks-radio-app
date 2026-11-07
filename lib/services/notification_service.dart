import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  /// Daily reminders. One per day, in rotation (20 days, then again).
  static const List<(String, String)> dailyMessages = [
    ('Pogodi šta upravo svira 🎶', 'Imamo osjećaj da će ti se svidjeti…'),
    ('Ovo nisi očekivao/la danas 👀', 'Uključi se i saznaj zašto svi slušaju.'),
    ('Tvoj niz je u opasnosti 🔥', 'Samo 5 minuta danas i niz ostaje živ!'),
    ('Fali ti samo malo do nove značke 🏅', 'Uključi radio i provjeri koja te čeka.'),
    ('Ovo je tvoj trenutak', 'Isključi buku, uključi Feniks. Zaslužio/la si.'),
    ('Tvoji bodovi te čekaju', 'Svaki minut slušanja = 2 boda. Hajde po njih!'),
    ('Popravi dan za 3, 2, 1…', 'Jedan klik i Feniks je s tobom.'),
    ('Psst… 🤫', 'Ova pjesma bi ti mogla popraviti cijeli dan.'),
    ('Znaš šta ti danas fali?', 'Malo dobre muzike. A mi imamo baš to 🎧'),
    ('Ne pitaj zašto, samo uključi 😄', 'Vjeruj Feniksu bar ovaj put.'),
    ('Ovo moraš čuti 🔊', 'Hitovi izabrani baš za tebe!'),
    ('Tvoja dnevna doza ljubavi 💛', 'Spremna je i čeka samo tebe.'),
    ('Kladimo se da ćeš se nasmijati 😊', 'Pet minuta Feniksa i vidjećeš.'),
    ('Ljestvica se mrda 📈', 'Svaki minut slušanja te gura naprijed. Gdje si ti?'),
    ('Hej, nedostaješ nam! 💛', 'Feniks nije isti bez tebe. Svrati na jednu pjesmu.'),
    ('Skupljaš li značke? 🏆', 'Neke se otključavaju samo slušanjem. Spreman/na?'),
    ('Pauza samo za tebe ☕', 'Kafa, Feniks i pet minuta mira.'),
    ('Dobre vijesti stižu 📻', 'Na Feniksu samo one. Uključi se.'),
    ('Ne skrolaj, slušaj Feniks! 🎶', 'Daj očima odmor, a ušima nešto lijepo.'),
    ('Vikend raspoloženje, bilo koji dan 🎉', 'Pojačaj Feniks i osjeti razliku.'),
  ];

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permission is asked only when the user turns reminders on.
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const macOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const init = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: macOS,
    );

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        // Open the player when the user taps the reminder
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      },
    );
  }

  /// Reminders use ids 1001..1030 (one per day for the next 30 days).
  static const int _firstReminderId = 1001;
  static const int _daysScheduledAhead = 30;

  /// Asks the user for permission to show notifications. Returns true if allowed.
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macos != null) {
        return await macos.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (_) {
      return false;
    }
    return true;
  }

  Future<void> cancelDailyReminder() async {
    for (var i = 0; i < _daysScheduledAhead; i++) {
      await _plugin.cancel(_firstReminderId + i);
    }
  }

  /// Which message is shown on a given day (rotates through all of them).
  static (String, String) messageForDay(DateTime day) {
    final dayNumber = DateTime.utc(day.year, day.month, day.day)
        .difference(DateTime.utc(2024, 1, 1))
        .inDays;
    return dailyMessages[dayNumber % dailyMessages.length];
  }

  /// Schedules one reminder per day at [hour]:[minute] for the next 30 days,
  /// each with the message of that day. Called again on every app start, so
  /// the schedule keeps rolling forward (and stays right after DST changes).
  Future<void> scheduleDailyGoodNews({
    required int hour,
    required int minute,
  }) async {
    await cancelDailyReminder(); // replace existing

    const androidDetails = AndroidNotificationDetails(
      'feniks_daily',
      'Dnevni podsjetnik',
      channelDescription: 'Dnevna notifikacija sa lijepom viješću',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day, hour, minute);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    for (var i = 0; i < _daysScheduledAhead; i++) {
      // Built from date parts (not +24h) so the local time stays the same.
      final local = DateTime(
        first.year,
        first.month,
        first.day + i,
        hour,
        minute,
      );
      final (title, body) = messageForDay(local);
      await _plugin.zonedSchedule(
        _firstReminderId + i,
        title,
        body,
        // tz.local is UTC in this app, so convert the local time explicitly.
        tz.TZDateTime.from(local, tz.UTC),
        details,
        // Inexact: needs no special "alarms" permission on Android 12+.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_reminder',
      );
    }
  }
}
