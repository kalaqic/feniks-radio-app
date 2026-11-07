import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/achievement.dart';
import '../models/achievements.dart';
import '../models/progress_rules.dart';

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class AdminUser {
  const AdminUser({
    required this.uid,
    required this.name,
    required this.contactEmail,
    required this.createdAt,
    required this.totalMinutes,
    required this.savedStreak,
    required this.lastListeningDay,
    required this.listeningDays,
    required this.sessionCount,
    required this.achievements,
    required this.favorites,
    required this.dailyMinutes,
  });

  factory AdminUser.fromFirestore(String uid, Map<String, dynamic> data) {
    final progress = data['achievements'] is Map
        ? Map<String, dynamic>.from(data['achievements'] as Map)
        : <String, dynamic>{};

    final achievements = <EarnedAchievement>[];
    for (final item in progress['earnedBadges'] as List<dynamic>? ?? const []) {
      if (item is! Map) continue;
      final achievement = Achievements.byId(item['id']?.toString() ?? '');
      if (achievement == null) continue;
      final earnedAt = _toDate(item['earnedDate']) ?? DateTime(2000);
      achievements.add(EarnedAchievement(achievement, earnedAt));
    }

    final totalSeconds = (progress['totalListeningSeconds'] as num?)?.toInt();
    final totalMinutes =
        totalSeconds != null
            ? totalSeconds ~/ 60
            : (progress['totalListeningMinutes'] as num?)?.toInt() ?? 0;

    final daily = <String, int>{};
    final rawDaily = progress['dailyMinutes'];
    if (rawDaily is Map) {
      rawDaily.forEach((day, minutes) {
        if (minutes is num) daily[day.toString()] = minutes.toInt();
      });
    }

    final contact = data['displayEmail'] as String?;
    return AdminUser(
      uid: uid,
      name: (data['displayName'] as String?)?.trim().isNotEmpty == true
          ? (data['displayName'] as String).trim()
          : 'Anonim',
      contactEmail: contact != null && contact.isNotEmpty ? contact : null,
      createdAt: _toDate(data['createdAt']),
      totalMinutes: totalMinutes,
      savedStreak: (progress['consecutiveDays'] as num?)?.toInt() ?? 0,
      lastListeningDay: _toDate(progress['lastListeningDate']),
      listeningDays: (progress['totalListeningDays'] as num?)?.toInt() ?? 0,
      sessionCount: (progress['sessionCount'] as num?)?.toInt() ?? 0,
      achievements: achievements,
      favorites: (progress['favoriteSongs'] as List<dynamic>? ?? const [])
          .map((song) => song.toString())
          .toList(),
      dailyMinutes: daily,
    );
  }

  final String uid;
  final String name;
  final String? contactEmail;
  final DateTime? createdAt;
  final int totalMinutes;
  final int savedStreak;
  final DateTime? lastListeningDay;
  final int listeningDays;
  final int sessionCount;
  final List<EarnedAchievement> achievements;
  final List<String> favorites;
  final Map<String, int> dailyMinutes;

  int get achievementPoints =>
      achievements.fold<int>(0, (total, e) => total + e.achievement.points);

  int get points =>
      totalMinutes * ProgressRules.pointsPerMinute + achievementPoints;

  int minutesOn(DateTime day) => dailyMinutes[dayKey(day)] ?? 0;

  int streakOn(DateTime now) {
    final last = lastListeningDay;
    if (last == null) return 0;
    final days = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(last.year, last.month, last.day))
        .inDays;
    return days <= 1 ? savedStreak : 0;
  }

  DateTime? get lastListenedAt {
    if (dailyMinutes.isEmpty) return lastListeningDay;
    final latest = dailyMinutes.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    return DateTime.tryParse(latest);
  }
}

class PresenceEntry {
  const PresenceEntry({
    required this.uid,
    required this.listening,
    required this.active,
    required this.platform,
    required this.lastSeen,
  });

  factory PresenceEntry.fromFirestore(String uid, Map<String, dynamic> data) {
    return PresenceEntry(
      uid: uid,
      listening: data['listening'] == true,
      active: data['active'] == true,
      platform: data['platform']?.toString() ?? '',
      lastSeen: _toDate(data['lastSeen']),
    );
  }

  static const Duration freshFor = Duration(minutes: 4);

  final String uid;
  final bool listening;
  final bool active;
  final String platform;
  final DateTime? lastSeen;

  bool isFresh(DateTime now) {
    final seen = lastSeen;
    return seen != null && now.difference(seen) <= freshFor;
  }
}

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection('admins').doc(uid).get();
    return doc.exists;
  }

  Future<List<AdminUser>> loadUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return [
      for (final doc in snapshot.docs) AdminUser.fromFirestore(doc.id, doc.data()),
    ];
  }

  Stream<List<PresenceEntry>> watchPresence() {
    return _firestore.collection('presence').snapshots().map(
      (snapshot) => [
        for (final doc in snapshot.docs)
          PresenceEntry.fromFirestore(doc.id, doc.data()),
      ],
    );
  }
}
