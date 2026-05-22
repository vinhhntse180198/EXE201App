class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.wordJp,
    this.reading,
    this.meaningVi,
    this.exampleSentence,
  });

  final int id;
  final String wordJp;
  final String? reading;
  final String? meaningVi;
  final String? exampleSentence;

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as int? ?? 0,
      wordJp: json['wordJp'] as String? ?? '',
      reading: json['reading'] as String?,
      meaningVi: json['meaningVi'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
    );
  }
}

class KanjiItem {
  const KanjiItem({
    required this.character,
    this.meaningVi,
    this.readingsOn,
    this.readingsKun,
  });

  final String character;
  final String? meaningVi;
  final String? readingsOn;
  final String? readingsKun;

  factory KanjiItem.fromJson(Map<String, dynamic> json) {
    return KanjiItem(
      character: json['character'] as String? ?? '',
      meaningVi: json['meaningVi'] as String?,
      readingsOn: json['readingsOn'] as String?,
      readingsKun: json['readingsKun'] as String?,
    );
  }
}

class GrammarItem {
  const GrammarItem({
    required this.pattern,
    this.meaningVi,
    this.structure,
    this.exampleSentences,
  });

  final String pattern;
  final String? meaningVi;
  final String? structure;
  final String? exampleSentences;

  factory GrammarItem.fromJson(Map<String, dynamic> json) {
    return GrammarItem(
      pattern: json['pattern'] as String? ?? '',
      meaningVi: json['meaningVi'] as String?,
      structure: json['structure'] as String?,
      exampleSentences: json['exampleSentences'] as String?,
    );
  }
}

class LessonDetail {
  const LessonDetail({
    required this.id,
    required this.title,
    required this.slug,
    this.content,
    this.categoryName,
    this.estimatedMinutes = 0,
    this.isPremium = false,
    this.vocabulary = const [],
    this.kanji = const [],
    this.grammar = const [],
  });

  final int id;
  final String title;
  final String slug;
  final String? content;
  final String? categoryName;
  final int estimatedMinutes;
  final bool isPremium;
  final List<VocabularyItem> vocabulary;
  final List<KanjiItem> kanji;
  final List<GrammarItem> grammar;

  factory LessonDetail.fromApiJson(Map<String, dynamic> json) {
    final lesson = json['lesson'] as Map<String, dynamic>? ?? json;
    List<T> mapList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }

    return LessonDetail(
      id: lesson['id'] as int? ?? 0,
      title: lesson['title'] as String? ?? 'Bài học',
      slug: lesson['slug'] as String? ?? '',
      content: lesson['content'] as String?,
      categoryName: lesson['categoryName'] as String?,
      estimatedMinutes: lesson['estimatedMinutes'] as int? ?? 0,
      isPremium: lesson['isPremium'] as bool? ?? false,
      vocabulary: mapList('vocabulary', VocabularyItem.fromJson),
      kanji: mapList('kanji', KanjiItem.fromJson),
      grammar: mapList('grammar', GrammarItem.fromJson),
    );
  }
}
