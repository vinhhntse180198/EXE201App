import 'dart:convert';

class GameQuestion {
  const GameQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    this.hintText,
    this.questionOrder = 0,
  });

  final int id;
  final String questionText;
  final List<String> options;
  final String? hintText;
  final int questionOrder;

  /// Khớp web `optionCellLabel` + `parseOptions` — options_json dạng `[{"text":"a"},...]`.
  /// Hiển thị đáp án — kể cả chuỗi lỗi kiểu `{text: ke}` từ bản parse cũ.
  static String displayLabel(String raw) => optionCellLabel(raw);

  static String optionCellLabel(dynamic o) {
    if (o == null) return '';
    if (o is String) {
      final s = o.trim();
      final legacy = RegExp(r'^\{\s*text\s*:\s*(.+?)\s*\}$', caseSensitive: false).firstMatch(s);
      if (legacy != null) return legacy.group(1)!.trim();
      return s;
    }
    if (o is num) return o.toString();
    if (o is Map) {
      final m = Map<String, dynamic>.from(o);
      for (final key in [
        'text',
        'Text',
        'label',
        'Label',
        'value',
        'Value',
        'romaji',
        'Romaji',
        'answer',
        'Answer',
      ]) {
        final v = m[key];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
      if (m.length == 1) return '${m.values.first}'.trim();
    }
    return o.toString().trim();
  }

  static List<String> parseOptionsList(dynamic raw) {
    if (raw == null) return [];
    dynamic j = raw;
    if (j is String) {
      final t = j.trim();
      if (t.isEmpty) return [];
      try {
        j = jsonDecode(t);
        if (j is String) {
          try {
            j = jsonDecode(j);
          } catch (_) {
            return [j.trim()];
          }
        }
      } catch (_) {
        return [];
      }
    }
    if (j is Map) {
      final nested = j['options'] ?? j['Options'];
      if (nested is List) j = nested;
      else return [];
    }
    if (j is! List) return [];
    return j.map(optionCellLabel).where((s) => s.isNotEmpty).toList();
  }

  factory GameQuestion.fromJson(Map<String, dynamic> json, {int order = 0}) {
    final optionsRaw =
        json['optionsJson'] ?? json['OptionsJson'] ?? json['options'] ?? json['Options'];
    return GameQuestion(
      id: json['id'] as int? ?? json['Id'] as int? ?? 0,
      questionText: json['questionText'] as String? ??
          json['QuestionText'] as String? ??
          json['question'] as String? ??
          'Câu hỏi',
      options: parseOptionsList(optionsRaw),
      hintText: json['hintText'] as String? ?? json['HintText'] as String?,
      questionOrder: json['questionOrder'] as int? ??
          json['QuestionOrder'] as int? ??
          (order + 1),
    );
  }
}

class GameSessionStart {
  const GameSessionStart({
    required this.sessionId,
    required this.maxHearts,
    required this.questions,
  });

  final int sessionId;
  final int maxHearts;
  final List<GameQuestion> questions;

  factory GameSessionStart.fromJson(Map<String, dynamic> json) {
    final qs = json['questions'] ?? json['Questions'];
    final list = qs is List
        ? qs
            .whereType<Map<String, dynamic>>()
            .toList()
            .asMap()
            .entries
            .map((e) => GameQuestion.fromJson(e.value, order: e.key))
            .toList()
        : <GameQuestion>[];

    return GameSessionStart(
      sessionId: json['sessionId'] as int? ?? json['SessionId'] as int? ?? 0,
      maxHearts: json['maxHearts'] as int? ?? json['MaxHearts'] as int? ?? 3,
      questions: list,
    );
  }
}

class GameSessionSummary {
  const GameSessionSummary({
    required this.finalScore,
    required this.correctCount,
    required this.totalQuestions,
    required this.expEarned,
    required this.xuEarned,
    required this.result,
  });

  final int finalScore;
  final int correctCount;
  final int totalQuestions;
  final int expEarned;
  final int xuEarned;
  final String result;

  factory GameSessionSummary.fromJson(Map<String, dynamic> json) {
    return GameSessionSummary(
      finalScore: json['finalScore'] as int? ?? json['FinalScore'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? json['CorrectCount'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? json['TotalQuestions'] as int? ?? 0,
      expEarned: json['expEarned'] as int? ?? json['ExpEarned'] as int? ?? 0,
      xuEarned: json['xuEarned'] as int? ?? json['XuEarned'] as int? ?? 0,
      result: json['result'] as String? ?? json['Result'] as String? ?? 'done',
    );
  }
}
