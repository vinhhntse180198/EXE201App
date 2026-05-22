import '../models/lesson_detail.dart';
import '../models/lesson_item.dart';
import 'api_client.dart';

class LessonService {
  LessonService(this._api);

  final ApiClient _api;

  Future<List<LessonItem>> fetchLessons({int page = 1, int pageSize = 50}) async {
    final data = await _api.get(
      '/api/lessons',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    );
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(LessonItem.fromJson)
          .toList();
    }
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(LessonItem.fromJson).toList();
    }
    return [];
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
