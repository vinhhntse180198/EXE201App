class LessonItem {
  const LessonItem({
    required this.id,
    required this.title,
    this.slug,
    this.levelId,
    this.categoryName,
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
  final bool isPublished;
  final bool isPremium;
  final int estimatedMinutes;
  final String? description;
  final bool isCompleted;

  factory LessonItem.fromJson(Map<String, dynamic> json, {bool completed = false}) {
    return LessonItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Bài học',
      slug: json['slug'] as String?,
      levelId: json['levelId'] as int?,
      categoryName: json['categoryName'] as String?,
      isPublished: json['isPublished'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      description: json['description'] as String?,
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
      isPublished: isPublished,
      isPremium: isPremium,
      estimatedMinutes: estimatedMinutes,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
