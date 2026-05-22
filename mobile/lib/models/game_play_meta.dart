import '../utils/json_field.dart';

class GameAchievement {
  const GameAchievement({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.earned,
    this.earnedAt,
    this.rewardExp = 0,
    this.rewardXu = 0,
  });

  final int id;
  final String slug;
  final String name;
  final String? description;
  final bool earned;
  final String? earnedAt;
  final int rewardExp;
  final int rewardXu;

  factory GameAchievement.fromJson(Map<String, dynamic> json) {
    return GameAchievement(
      id: jsonInt(json, 'id') ?? 0,
      slug: jsonStr(json, 'slug') ?? '',
      name: jsonStr(json, 'name') ?? 'Thành tựu',
      description: jsonStr(json, 'description'),
      earned: jsonBool(json, 'earned'),
      earnedAt: jsonStr(json, 'earnedAt'),
      rewardExp: jsonInt(json, 'rewardExp') ?? 0,
      rewardXu: jsonInt(json, 'rewardXu') ?? 0,
    );
  }
}

class GameHistoryEntry {
  const GameHistoryEntry({
    required this.sessionId,
    required this.finalScore,
    required this.correctCount,
    required this.totalQuestions,
    required this.accuracyPercent,
    required this.expEarned,
    required this.xuEarned,
    required this.result,
    this.maxCombo = 0,
    this.timeSpentSeconds = 0,
  });

  final int sessionId;
  final int finalScore;
  final int correctCount;
  final int totalQuestions;
  final double accuracyPercent;
  final int maxCombo;
  final int timeSpentSeconds;
  final int expEarned;
  final int xuEarned;
  final String result;

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    final acc = jsonField(json, 'accuracyPercent');
    return GameHistoryEntry(
      sessionId: jsonInt(json, 'sessionId') ?? 0,
      finalScore: jsonInt(json, 'finalScore') ?? 0,
      correctCount: jsonInt(json, 'correctCount') ?? 0,
      totalQuestions: jsonInt(json, 'totalQuestions') ?? 0,
      accuracyPercent: acc is num ? acc.toDouble() : double.tryParse('$acc') ?? 0,
      maxCombo: jsonInt(json, 'maxCombo') ?? 0,
      timeSpentSeconds: jsonInt(json, 'timeSpentSeconds') ?? 0,
      expEarned: jsonInt(json, 'expEarned') ?? 0,
      xuEarned: jsonInt(json, 'xuEarned') ?? 0,
      result: jsonStr(json, 'result') ?? 'completed',
    );
  }
}

class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.gameSlug,
    required this.title,
    required this.bonusExp,
    required this.bonusXu,
    required this.completedToday,
    this.bestScore,
  });

  final int id;
  final String gameSlug;
  final String title;
  final int bonusExp;
  final int bonusXu;
  final bool completedToday;
  final int? bestScore;

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: jsonInt(json, 'id') ?? 0,
      gameSlug: jsonStr(json, 'gameSlug') ?? '',
      title: jsonStr(json, 'title') ?? 'Thử thách hôm nay',
      bonusExp: jsonInt(json, 'bonusExp') ?? 0,
      bonusXu: jsonInt(json, 'bonusXu') ?? 0,
      completedToday: jsonBool(json, 'completedToday'),
      bestScore: jsonInt(json, 'bestScore'),
    );
  }
}

/// Parse tại top-level — tránh lỗi runtime `List<dynamic>` vs `List<T>` sau hot reload.
List<GameAchievement> parseGameAchievementsList(dynamic data) {
  final List<GameAchievement> list = [];
  for (final row in jsonApiMapList(data)) {
    list.add(GameAchievement.fromJson(row));
  }
  return list;
}

List<GameHistoryEntry> parseGameHistoryList(dynamic data) {
  final List<GameHistoryEntry> list = [];
  for (final row in jsonApiMapList(data)) {
    list.add(GameHistoryEntry.fromJson(row));
  }
  return list;
}

DailyChallenge? parseDailyChallenge(dynamic data) {
  final map = jsonApiMap(data);
  if (map == null) return null;
  return DailyChallenge.fromJson(map);
}
