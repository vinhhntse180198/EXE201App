import '../utils/json_field.dart';

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
      id: jsonInt(json, 'id') ?? 0,
      wordJp: jsonStr(json, 'wordJp') ?? '',
      reading: jsonStr(json, 'reading'),
      meaningVi: jsonStr(json, 'meaningVi'),
      exampleSentence: jsonStr(json, 'exampleSentence'),
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
      character: jsonStr(json, 'character') ?? jsonStr(json, 'kanjiChar') ?? '',
      meaningVi: jsonStr(json, 'meaningVi'),
      readingsOn: jsonStr(json, 'readingsOn'),
      readingsKun: jsonStr(json, 'readingsKun'),
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
      pattern: jsonStr(json, 'pattern') ?? '',
      meaningVi: jsonStr(json, 'meaningVi'),
      structure: jsonStr(json, 'structure'),
      exampleSentences: jsonStr(json, 'exampleSentences'),
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
    final lessonRaw = jsonField(json, 'lesson');
    final lesson = lessonRaw is Map<String, dynamic> ? lessonRaw : json;

    List<T> mapList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = jsonField(json, key);
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }

    return LessonDetail(
      id: jsonInt(lesson, 'id') ?? 0,
      title: jsonStr(lesson, 'title') ?? 'Bài học',
      slug: jsonStr(lesson, 'slug') ?? '',
      content: jsonStr(lesson, 'content'),
      categoryName: jsonStr(lesson, 'categoryName'),
      estimatedMinutes: jsonInt(lesson, 'estimatedMinutes') ?? 0,
      isPremium: jsonBool(lesson, 'isPremium'),
      vocabulary: mapList('vocabulary', VocabularyItem.fromJson),
      kanji: mapList('kanji', KanjiItem.fromJson),
      grammar: mapList('grammar', GrammarItem.fromJson),
    );
  }
}
