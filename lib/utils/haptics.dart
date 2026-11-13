import 'dart:async';

import 'package:flutter/services.dart';

/// How strongly a touch should be felt, from barely to very.
///
/// The rule: the bigger the consequence of a tap, the stronger the feel.
/// - [selection]: moving around (tabs, rows, links, back, steppers).
/// - [light]: small changes (switch on, opening a drawer, a small heart).
/// - [medium]: main actions (play/stop, saving a favorite, main buttons
///   that confirm something).
/// - [heavy]: something that cannot be undone (deleting the account).
/// - [success]: a reward, two quick taps (badge earned).
/// - [warning]: something went wrong, a strong tap and a softer echo.
enum Haptic { none, selection, light, medium, heavy, success, warning }

abstract final class Haptics {
  static void play(Haptic haptic) {
    switch (haptic) {
      case Haptic.none:
        return;
      case Haptic.selection:
        unawaited(HapticFeedback.selectionClick());
      case Haptic.light:
        unawaited(HapticFeedback.lightImpact());
      case Haptic.medium:
        unawaited(HapticFeedback.mediumImpact());
      case Haptic.heavy:
        unawaited(HapticFeedback.heavyImpact());
      case Haptic.success:
        unawaited(HapticFeedback.mediumImpact());
        _later(const Duration(milliseconds: 110), HapticFeedback.lightImpact);
      case Haptic.warning:
        unawaited(HapticFeedback.heavyImpact());
        _later(const Duration(milliseconds: 140), HapticFeedback.lightImpact);
    }
  }

  static void _later(Duration delay, Future<void> Function() feel) {
    Timer(delay, () => unawaited(feel()));
  }
}
