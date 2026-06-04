import '../models/lesson_detail.dart';
import '../models/lesson_item.dart';
import '../utils/json_field.dart';
import 'api_client.dart';

class LessonService {
  LessonService(this._api);

  final ApiClient _api;

  Future<LessonPageResult> fetchLessonsPage({int page = 1, int pageSize = 100, int? levelId}) async {
    final data = await _api.get(
      '/api/lessons',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (levelId != null) 'levelId': '$levelId',
      },
    );
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final items = jsonApiMapList(map['items'] ?? data).map(LessonItem.fromJson).toList();
    final total = jsonInt(map, 'totalCount') ?? items.length;
    return LessonPageResult(items: items, totalCount: total);
  }

  /// Tải toàn bộ bài học (phân trang nếu server trả nhiều hơn pageSize).
  Future<List<LessonItem>> fetchLessons({int pageSize = 100}) async {
    final first = await fetchLessonsPage(page: 1, pageSize: pageSize);
    if (first.items.length >= first.totalCount) return first.items;

    final all = List<LessonItem>.from(first.items);
    var page = 2;
    while (all.length < first.totalCount) {
      final next = await fetchLessonsPage(page: page, pageSize: pageSize);
      if (next.items.isEmpty) break;
      all.addAll(next.items);
      page++;
    }
    return all;
  }

  Future<LessonDetail> fetchBySlug(String slug) async {
    final data = await _api.get('/api/lessons/slug/$slug');
    return LessonDetail.fromApiJson(data as Map<String, dynamic>);
  }

  Future<LessonDetail> fetchById(int id) async {
    final data = await _api.get('/api/lessons/$id');
    return LessonDetail.fromApiJson(data as Map<String, dynamic>);
  }

  Future<void> addBookmark(int lessonId) async {
    await _api.post('/api/lessons/$lessonId/bookmark');
  }

  Future<void> removeBookmark(int lessonId) async {
    await _api.delete('/api/lessons/$lessonId/bookmark');
  }
}
