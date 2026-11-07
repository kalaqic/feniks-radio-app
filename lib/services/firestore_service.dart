import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';

class UsernameTakenException implements Exception {
  UsernameTakenException();
}

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _usernameLookup =>
      _firestore.collection('usernameLookup');

  CollectionReference<Map<String, dynamic>> get _leaderboard =>
      _firestore.collection('leaderboard');

  static String _normalizeUsername(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Returns true if this username is already taken.
  Future<bool> isUsernameTaken(String displayName) async {
    final key = _normalizeUsername(displayName);
    if (key.isEmpty) return true;
    final doc = await _usernameLookup.doc(key).get();
    return doc.exists;
  }

  /// Create or update user document and username lookup. Called after register.
  /// Throws [UsernameTakenException] if this username is already taken.
  Future<void> createOrUpdateUser(
    String uid,
    String displayName, {
    String? email,
  }) async {
    final key = _normalizeUsername(displayName);
    if (key.isEmpty) throw ArgumentError('displayName is empty');
    if (email == null) {
      await _users.doc(uid).set({
        'displayName': displayName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await _firestore.runTransaction((tx) async {
      final lookup = await tx.get(_usernameLookup.doc(key));
      if (lookup.exists) throw UsernameTakenException();

      tx.set(_users.doc(uid), {
        'displayName': displayName.trim(),
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(_usernameLookup.doc(key), {'email': email, 'uid': uid});
    });
  }

  /// Ensure minimal user profile exists after sign-in.
  Future<void> ensureUserProfile(
    String uid, {
    String? displayName,
    String? email,
  }) async {
    await _users.doc(uid).set({
      'displayName': (displayName == null || displayName.trim().isEmpty)
          ? 'Anonim'
          : displayName.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save user achievements and progress to Firestore.
  Future<void> saveUserAchievements(
    String uid,
    Map<String, dynamic> achievementData,
  ) async {
    await _users.doc(uid).set({
      'achievements': achievementData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get stored email for login by username. Returns null if not found.
  /// Uses usernameLookup so unauthenticated users can log in.
  Future<String?> getEmailByUsername(String username) async {
    final key = _normalizeUsername(username);
    if (key.isEmpty) return null;
    final doc = await _usernameLookup.doc(key).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data()!['email'] as String?;
  }

  /// Update this user's leaderboard entry. The points are split into
  /// listening and badge points so the security rules can validate them.
  Future<void> updateLeaderboardEntry(
    String uid, {
    required String displayName,
    required int listeningPoints,
    required int badgePoints,
    required int badgeCount,
  }) async {
    await _leaderboard.doc(uid).set({
      'displayName': displayName,
      'points': listeningPoints + badgePoints,
      'listeningPoints': listeningPoints,
      'badgePoints': badgePoints,
      'badgeCount': badgeCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Top [limit] users by points descending.
  Future<List<LeaderboardEntry>> getLeaderboardTop({int limit = 3}) async {
    final query = await _leaderboard
        .orderBy('points', descending: true)
        .limit(limit)
        .get();
    return [
      for (final (index, doc) in query.docs.indexed)
        LeaderboardEntry.fromFirestore(doc.id, doc.data(), rank: index + 1),
    ];
  }

  /// All-time rank of the current user (1-based), based on total points.
  /// Uses an aggregate count so it does not download the whole leaderboard.
  Future<int?> getMyRank(int myPoints) async {
    final agg = await _leaderboard
        .where('points', isGreaterThan: myPoints)
        .count()
        .get();
    return (agg.count ?? 0) + 1;
  }

  /// Load user achievements from Firestore. Returns null if no document.
  Future<Map<String, dynamic>?> loadUserAchievements(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    final achievements = data['achievements'];
    if (achievements is Map<String, dynamic>) return achievements;
    if (achievements is Map) return Map<String, dynamic>.from(achievements);
    return null;
  }

  /// Deletes everything stored about this user (profile, progress,
  /// leaderboard entry and username). Used when the account is deleted.
  Future<void> deleteUserData(String uid, {String? displayName}) async {
    await _leaderboard.doc(uid).delete();
    if (displayName != null) {
      final key = _normalizeUsername(displayName);
      if (key.isNotEmpty) {
        try {
          await _usernameLookup.doc(key).delete();
        } catch (_) {
          // Not this user's username entry; nothing to delete.
        }
      }
    }
    await _users.doc(uid).delete();
  }

  /// Optional email the user chooses to display (not the login email). Null if not set.
  Future<String?> getUserDisplayEmail(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final email = doc.data()!['displayEmail'] as String?;
    return (email != null && email.trim().isNotEmpty) ? email.trim() : null;
  }

  /// Set or clear the optional display email. Pass null or empty to hide.
  Future<void> setUserDisplayEmail(String uid, String? displayEmail) async {
    final value = displayEmail != null && displayEmail.trim().isNotEmpty
        ? displayEmail.trim()
        : null;
    await _users.doc(uid).set({
      'displayEmail': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
