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

  CollectionReference<Map<String, dynamic>> get _presence =>
      _firestore.collection('presence');

  CollectionReference<Map<String, dynamic>> get _leaderboard =>
      _firestore.collection('leaderboard');

  static String _normalizeUsername(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  Future<bool> isUsernameTaken(String displayName) async {
    final key = _normalizeUsername(displayName);
    if (key.isEmpty) return true;
    final doc = await _usernameLookup.doc(key).get();
    return doc.exists;
  }

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

  Future<void> ensureUserProfile(
    String uid, {
    String? displayName,
    String? email,
    DateTime? createdAt,
  }) async {
    await _users.doc(uid).set({
      'displayName': (displayName == null || displayName.trim().isEmpty)
          ? 'Anonim'
          : displayName.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePresence(
    String uid, {
    required bool listening,
    required bool active,
    required String platform,
  }) async {
    await _presence.doc(uid).set({
      'listening': listening,
      'active': active,
      'platform': platform,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveUserAchievements(
    String uid,
    Map<String, dynamic> achievementData,
  ) async {
    await _users.doc(uid).set({
      'achievements': achievementData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> getEmailByUsername(String username) async {
    final key = _normalizeUsername(username);
    if (key.isEmpty) return null;
    final doc = await _usernameLookup.doc(key).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data()!['email'] as String?;
  }

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

  Future<int?> getMyRank(int myPoints) async {
    final agg = await _leaderboard
        .where('points', isGreaterThan: myPoints)
        .count()
        .get();
    return (agg.count ?? 0) + 1;
  }

  Future<Map<String, dynamic>?> loadUserAchievements(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    final achievements = data['achievements'];
    if (achievements is Map<String, dynamic>) return achievements;
    if (achievements is Map) return Map<String, dynamic>.from(achievements);
    return null;
  }

  Future<void> deleteUserData(String uid, {String? displayName}) async {
    await _leaderboard.doc(uid).delete();
    if (displayName != null) {
      final key = _normalizeUsername(displayName);
      if (key.isNotEmpty) {
        try {
          await _usernameLookup.doc(key).delete();
        } catch (_) {
        }
      }
    }
    await _presence.doc(uid).delete();
    await _users.doc(uid).delete();
  }

  Future<String?> getUserDisplayEmail(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final email = doc.data()!['displayEmail'] as String?;
    return (email != null && email.trim().isNotEmpty) ? email.trim() : null;
  }

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
