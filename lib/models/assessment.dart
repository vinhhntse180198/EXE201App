class ExamOption {
  const ExamOption({required this.key, required this.text});

  final String key;
  final String text;

  factory ExamOption.fromJson(Map<String, dynamic> json) {
    return ExamOption(
      key: json['key'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.points = 1,
  });

  final int id;
  final String text;
  final List<ExamOption> options;
  final int points;

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    final opts = json['options'];
    return ExamQuestion(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      points: json['points'] as int? ?? 1,
      options: opts is List
          ? opts.whereType<Map<String, dynamic>>().map(ExamOption.fromJson).toList()
          : [],
    );
  }
}

class PlacementTestDefinition {
  const PlacementTestDefinition({
    required this.totalQuestions,
    required this.timeLimitSeconds,
    required this.questions,
  });

  final int totalQuestions;
  final int timeLimitSeconds;
  final List<ExamQuestion> questions;

  factory PlacementTestDefinition.fromJson(Map<String, dynamic> json) {
    final qs = json['questions'];
    return PlacementTestDefinition(
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 1200,
      questions: qs is List
          ? qs.whereType<Map<String, dynamic>>().map(ExamQuestion.fromJson).toList()
          : [],
    );
  }
}

class PlacementTestResult {
  const PlacementTestResult({
    required this.correctCount,
    required this.totalCount,
    required this.levelLabel,
  });

  final int correctCount;
  final int totalCount;
  final String levelLabel;

  factory PlacementTestResult.fromJson(Map<String, dynamic> json) {
    return PlacementTestResult(
      correctCount: json['correctCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      levelLabel: json['levelLabel'] as String? ?? '',
    );
  }
}

class LevelUpTestDefinition {
  const LevelUpTestDefinition({
    required this.testId,
    required this.fromLevel,
    required this.toLevel,
    required this.title,
    required this.passScore,
    required this.totalPoints,
    required this.timeLimitSeconds,
    required this.questions,
    this.description,
  });

  final int testId;
  final String fromLevel;
  final String toLevel;
  final String title;
  final String? description;
  final int passScore;
  final int totalPoints;
  final int timeLimitSeconds;
  final List<ExamQuestion> questions;

  factory LevelUpTestDefinition.fromJson(Map<String, dynamic> json) {
    final qs = json['questions'];
    return LevelUpTestDefinition(
      testId: json['testId'] as int? ?? 0,
      fromLevel: json['fromLevel'] as String? ?? '',
      toLevel: json['toLevel'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      passScore: json['passScore'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 1200,
      questions: qs is List
          ? qs.whereType<Map<String, dynamic>>().map(ExamQuestion.fromJson).toList()
          : [],
    );
  }
}

class LevelUpTestResult {
  const LevelUpTestResult({
    required this.testId,
    required this.fromLevel,
    required this.toLevel,
    required this.score,
    required this.maxScore,
    required this.isPassed,
  });

  final int testId;
  final String fromLevel;
  final String toLevel;
  final int score;
  final int maxScore;
  final bool isPassed;

  factory LevelUpTestResult.fromJson(Map<String, dynamic> json) {
    return LevelUpTestResult(
      testId: json['testId'] as int? ?? 0,
      fromLevel: json['fromLevel'] as String? ?? '',
      toLevel: json['toLevel'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      maxScore: json['maxScore'] as int? ?? 0,
      isPassed: json['isPassed'] as bool? ?? false,
    );
  }
}
