import '../utils/json_field.dart';

/// Hàng BXH điểm game — `/api/game/leaderboard`.
class GameLeaderboardEntry {
  const GameLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.accuracyAvg,
    required this.gamesPlayed,
    required this.bestCombo,
    this.avgDurationMs,
    this.levelCode,
  });

  final int rank;
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final double accuracyAvg;
  final int gamesPlayed;
  final int bestCombo;
  final int? avgDurationMs;
  final String? levelCode;

  factory GameLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final acc = jsonField(json, 'accuracyAvg');
    return GameLeaderboardEntry(
      rank: jsonInt(json, 'rank') ?? 0,
      userId: jsonInt(json, 'userId') ?? 0,
      displayName: jsonStr(json, 'displayName') ?? jsonStr(json, 'username') ?? '—',
      avatarUrl: jsonStr(json, 'avatarUrl'),
      score: jsonInt(json, 'score') ?? 0,
      accuracyAvg: acc is num ? acc.toDouble() : double.tryParse('$acc') ?? 0,
      gamesPlayed: jsonInt(json, 'gamesPlayed') ?? 0,
      bestCombo: jsonInt(json, 'bestCombo') ?? 0,
      avgDurationMs: jsonInt(json, 'avgDurationMs'),
      levelCode: jsonStr(json, 'levelCode'),
    );
  }
}

/// Hàng BXH EXP tổng — `/api/game/exp-leaderboard`.
class ExpLeaderboardEntry {
  const ExpLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.exp,
    this.levelCode,
  });

  final int rank;
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final int exp;
  final String? levelCode;

  factory ExpLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ExpLeaderboardEntry(
      rank: jsonInt(json, 'rank') ?? 0,
      userId: jsonInt(json, 'userId') ?? 0,
      displayName: jsonStr(json, 'displayName') ?? jsonStr(json, 'username') ?? '—',
      avatarUrl: jsonStr(json, 'avatarUrl'),
      exp: jsonInt(json, 'exp') ?? jsonInt(json, 'totalExp') ?? 0,
      levelCode: jsonStr(json, 'levelCode'),
    );
  }
}
