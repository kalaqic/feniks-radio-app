import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  static const List<(String, String)> _dailyNotificationVariants = [
    (
      'Vrijeme je za dobar osjećaj',
      'Uključi se i razbistri glavu uz muziku i pozitivnu energiju',
    ),
    (
      'Mali reset za dan',
      'Odvoji trenutak za sebe i popravi raspoloženje uz program uživo',
    ),
    (
      'Udahni, opusti se, slušaj',
      'Pusti dobar ritam da ti razvedri dan i vrati fokus',
    ),
    (
      'Vrijeme je da popraviš dan',
      'Uključi slušanje i unesi više dobre energije u ostatak dana',
    ),
    (
      'Dnevna doza boljeg raspoloženja',
      'Pridruži se programu i napravi lagani restart misli',
    ),
  ];

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const macOS = DarwinInitializationSettings();
    const init = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: macOS,
    );

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        // Navigate to good news screen when user taps notification
        navigatorKey.currentState?.pushNamed('/good-news');
      },
    );
  }

  Future<void> scheduleDailyGoodNews({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(1001); // replace existing

    const androidDetails = AndroidNotificationDetails(
      'feniks_daily',
      'Daily Good News',
      channelDescription: 'Dnevna notifikacija sa lijepom viješću',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final location = tz.getLocation(tz.local.name);
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final variantIndex = scheduled.weekday % _dailyNotificationVariants.length;
    final (title, body) = _dailyNotificationVariants[variantIndex];

    await _plugin.zonedSchedule(
      1001,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'good_news',
    );
  }
}
