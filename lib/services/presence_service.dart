import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/log.dart';
import 'firestore_service.dart';

class PresenceService {
  PresenceService({this.enabled = true});

  final bool enabled;

  static const Duration heartbeat = Duration(minutes: 2);
  static const Duration _minGapBetweenWrites = Duration(seconds: 10);

  bool? _lastListening;
  bool? _lastActive;
  DateTime? _lastWrite;

  void update({required bool listening, required bool active}) {
    if (!enabled) return;
    final now = DateTime.now();
    final lastWrite = _lastWrite;
    final changed = listening != _lastListening || active != _lastActive;
    final heartbeatDue =
        active && (lastWrite == null || now.difference(lastWrite) >= heartbeat);
    if (!changed && !heartbeatDue) return;
    if (lastWrite != null && now.difference(lastWrite) < _minGapBetweenWrites) {
      return;
    }

    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      logError('Reading the signed-in user', e);
      return;
    }
    if (uid == null) return;

    _lastListening = listening;
    _lastActive = active;
    _lastWrite = now;
    unawaited(
      FirestoreService.instance
          .updatePresence(
            uid,
            listening: listening,
            active: active,
            platform: defaultTargetPlatform.name,
          )
          .catchError((Object e) => logError('Updating presence', e)),
    );
  }
}
