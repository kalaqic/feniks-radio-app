import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/listening_progress.dart';
import '../utils/log.dart';
import 'firestore_service.dart';

/// Saves [ListeningProgress] and the leaderboard entry to Firestore.
///
/// Guarantees:
///  * nothing is saved before the user's progress has been loaded
///    ([loadedUserId]), so an empty state can never overwrite real progress;
///  * only one save runs at a time; changes made during a save are written
///    right after it.
class ProgressSync {
  ProgressSync(this._progress, {this.enabled = true});

  final ListeningProgress _progress;

  /// False in tests: no Firebase calls at all.
  final bool enabled;

  /// Firebase uid whose progress is loaded (null = nothing loaded yet).
  String? loadedUserId;

  bool _running = false;
  bool _runAgain = false;
  Completer<void>? _done;

  /// Starts a save in the background.
  void request() => unawaited(save());

  /// Saves now (no-op when logged out or nothing is loaded yet).
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
        // Stop if the user logged out meanwhile.
        if (loadedUserId != user.uid) break;
        _runAgain = false;
        // One consistent snapshot before any await.
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

  /// Waits until a save that is already running has finished.
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
