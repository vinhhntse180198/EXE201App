import '../utils/jlpt_levels.dart';
import '../utils/json_field.dart';

class LessonItem {
  const LessonItem({
    required this.id,
    required this.title,
    this.slug,
    this.levelId,
    this.categoryName,
    this.categoryType,
    this.isPublished = true,
    this.isPremium = false,
    this.estimatedMinutes = 0,
    this.description,
    this.isCompleted = false,
  });

  final int id;
  final String title;
  final String? slug;
  final int? levelId;
  final String? categoryName;
  final String? categoryType;
  final bool isPublished;
  final bool isPremium;
  final int estimatedMinutes;
  final String? description;
  final bool isCompleted;

  String get levelCode => levelCodeFromId(levelId);

  String get categoryLabel {
    switch ((categoryType ?? '').toLowerCase()) {
      case 'vocabulary':
        return 'Từ vựng';
      case 'grammar':
        return 'Ngữ pháp';
      case 'kanji':
        return 'Kanji';
      case 'listening':
        return 'Nghe';
      case 'reading':
        return 'Đọc';
      default:
        return categoryName ?? 'Bài học';
    }
  }

  factory LessonItem.fromJson(Map<String, dynamic> json, {bool completed = false}) {
    return LessonItem(
      id: jsonInt(json, 'id') ?? 0,
      title: jsonStr(json, 'title') ?? 'Bài học',
      slug: jsonStr(json, 'slug'),
      levelId: jsonInt(json, 'levelId'),
      categoryName: jsonStr(json, 'categoryName'),
      categoryType: jsonStr(json, 'categoryType'),
      isPublished: jsonBool(json, 'isPublished', defaultValue: true),
      isPremium: jsonBool(json, 'isPremium'),
      estimatedMinutes: jsonInt(json, 'estimatedMinutes') ?? 0,
      description: jsonStr(json, 'description'),
      isCompleted: completed,
    );
  }

  LessonItem copyWith({bool? isCompleted}) {
    return LessonItem(
      id: id,
      title: title,
      slug: slug,
      levelId: levelId,
      categoryName: categoryName,
      categoryType: categoryType,
      isPublished: isPublished,
      isPremium: isPremium,
      estimatedMinutes: estimatedMinutes,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class LessonPageResult {
  const LessonPageResult({required this.items, required this.totalCount});

  final List<LessonItem> items;
  final int totalCount;
}
