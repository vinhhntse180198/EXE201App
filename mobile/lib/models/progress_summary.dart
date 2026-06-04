import '../utils/json_field.dart';

class LevelCompletion {
  const LevelCompletion({
    required this.levelId,
    required this.levelCode,
    required this.levelName,
    required this.totalPublishedLessons,
    required this.completedLessons,
    required this.completionPercent,
  });

  final int levelId;
  final String levelCode;
  final String levelName;
  final int totalPublishedLessons;
  final int completedLessons;
  final double completionPercent;

  factory LevelCompletion.fromJson(Map<String, dynamic> json) {
    return LevelCompletion(
      levelId: jsonInt(json, 'levelId') ?? 0,
      levelCode: jsonStr(json, 'levelCode') ?? '',
      levelName: jsonStr(json, 'levelName') ?? '',
      totalPublishedLessons: jsonInt(json, 'totalPublishedLessons') ?? 0,
      completedLessons: jsonInt(json, 'completedLessons') ?? 0,
      completionPercent: (jsonField(json, 'completionPercent') as num?)?.toDouble() ?? 0,
    );
  }
}

class ProgressSummary {
  const ProgressSummary({
    required this.exp,
    required this.xu,
    required this.streakDays,
    required this.byLevel,
  });

  final int exp;
  final int xu;
  final int streakDays;
  final List<LevelCompletion> byLevel;

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    final levels = jsonField(json, 'byLevel');
    return ProgressSummary(
      exp: jsonInt(json, 'exp') ?? 0,
      xu: jsonInt(json, 'xu') ?? 0,
      streakDays: jsonInt(json, 'streakDays') ?? 0,
      byLevel: levels is List
          ? levels
              .whereType<Map<String, dynamic>>()
              .map(LevelCompletion.fromJson)
              .where((l) => l.totalPublishedLessons > 0)
              .toList()
          : [],
    );
  }
}
