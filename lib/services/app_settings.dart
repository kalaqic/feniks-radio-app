import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/log.dart';

/// User settings, stored on the device.
class AppSettings {
  AppSettings({this.persist = true});

  /// False in tests: nothing is read from or written to the device.
  final bool persist;

  static const _keyNotifications = 'settings.notificationsEnabled';
  static const _keyAutoPlay = 'settings.autoPlay';
  static const _keyVolume = 'settings.volume';
  static const _keyReminderHour = 'settings.notificationHour';
  static const _keyReminderMinute = 'settings.notificationMinute';

  bool notificationsEnabled = false;
  bool autoPlay = false;
  double volume = 0.8;
  int reminderHour = 8;
  int reminderMinute = 0;

  Future<void> load() async {
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      notificationsEnabled =
          prefs.getBool(_keyNotifications) ?? notificationsEnabled;
      autoPlay = prefs.getBool(_keyAutoPlay) ?? autoPlay;
      volume = prefs.getDouble(_keyVolume) ?? volume;
      reminderHour = prefs.getInt(_keyReminderHour) ?? reminderHour;
      reminderMinute = prefs.getInt(_keyReminderMinute) ?? reminderMinute;
    } catch (e) {
      logError('Loading settings', e);
    }
  }

  /// Writes all settings in the background.
  void save() {
    if (!persist) return;
    unawaited(_write());
  }

  Future<void> _write() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifications, notificationsEnabled);
      await prefs.setBool(_keyAutoPlay, autoPlay);
      await prefs.setDouble(_keyVolume, volume);
      await prefs.setInt(_keyReminderHour, reminderHour);
      await prefs.setInt(_keyReminderMinute, reminderMinute);
    } catch (e) {
      logError('Saving settings', e);
    }
  }
}
