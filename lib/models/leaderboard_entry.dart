import 'package:flutter/foundation.dart' show immutable;

/// One row of the leaderboard.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.points,
    required this.achievementCount,
    required this.rank,
  });

  /// Builds an entry from a `leaderboard/{uid}` document.
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

  /// 1-based position on the leaderboard.
  final int rank;

  /// First letter of the name, used as the avatar.
  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  /// First word of the name (shown under the podium).
  String get shortName => name.trim().split(' ').first;
}
