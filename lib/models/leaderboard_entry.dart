import 'package:flutter/foundation.dart' show immutable;

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.points,
    required this.achievementCount,
    required this.rank,
  });

  factory LeaderboardEntry.fromFirestore(
    String uid,
    Map<String, dynamic> data, {
    required int rank,
  }) {
    return LeaderboardEntry(
      uid: uid,
      name: data['displayName'] as String? ?? 'Anonim',
      points: (data['points'] as num?)?.toInt() ?? 0,
      achievementCount: (data['badgeCount'] as num?)?.toInt() ?? 0,
      rank: rank,
    );
  }

  final String uid;
  final String name;
  final int points;
  final int achievementCount;

  final int rank;

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  String get shortName => name.trim().split(' ').first;
}
