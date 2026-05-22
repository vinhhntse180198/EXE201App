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
      levelId: json['levelId'] as int? ?? 0,
      levelCode: json['levelCode'] as String? ?? '',
      levelName: json['levelName'] as String? ?? '',
      totalPublishedLessons: json['totalPublishedLessons'] as int? ?? 0,
      completedLessons: json['completedLessons'] as int? ?? 0,
      completionPercent: (json['completionPercent'] as num?)?.toDouble() ?? 0,
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
    final levels = json['byLevel'];
    return ProgressSummary(
      exp: json['exp'] as int? ?? 0,
      xu: json['xu'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      byLevel: levels is List
          ? levels
              .whereType<Map<String, dynamic>>()
              .map(LevelCompletion.fromJson)
              .toList()
          : [],
    );
  }
}
