import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/listening_progress.dart';
import '../utils/log.dart';
import 'firestore_service.dart';

class ProgressSync {
  ProgressSync(this._progress, {this.enabled = true});

  final ListeningProgress _progress;

  final bool enabled;

  String? loadedUserId;

  bool _running = false;
  bool _runAgain = false;
  Completer<void>? _done;

  void request() => unawaited(save());

  Future<void> save() async {
    if (!enabled) return;
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      logError('Reading the signed-in user', e);
      return;
    }
    if (user == null || loadedUserId != user.uid) return;

    if (_running) {
      _runAgain = true;
      return;
    }
    _running = true;
    final done = _done = Completer<void>();
    try {
      do {
        if (loadedUserId != user.uid) break;
        _runAgain = false;

        final data = _progress.toJson();
        final listeningPoints = _progress.listeningPoints;
        final achievementPoints = _progress.achievementPoints;
        final achievementCount = _progress.earned.length;

        await FirestoreService.instance.saveUserAchievements(user.uid, data);
        await FirestoreService.instance.updateLeaderboardEntry(
          user.uid,
          displayName: user.displayName ?? 'Anonim',
          listeningPoints: listeningPoints,
          badgePoints: achievementPoints,
          badgeCount: achievementCount,
        );
      } while (_runAgain);
    } catch (e) {
      logError('Saving progress', e);
    } finally {
      _running = false;
      done.complete();
      if (identical(_done, done)) _done = null;
    }
  }

  Future<void> waitForPending({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final done = _done;
    if (done == null) return;
    try {
      await done.future.timeout(timeout);
    } catch (e) {
      logError('Waiting for a running save', e);
    }
  }
}
