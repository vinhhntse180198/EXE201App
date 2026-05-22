import '../models/progress_summary.dart';
import 'api_client.dart';

class LearnService {
  LearnService(this._api);

  final ApiClient _api;

  Future<ProgressSummary> fetchProgressSummary() async {
    final data = await _api.get('/api/users/me/progress/summary');
    return ProgressSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<List<dynamic>> fetchMyProgress({String? status, int pageSize = 20}) async {
    final data = await _api.get(
      '/api/users/me/progress',
      query: {
        'page': '1',
        'pageSize': '$pageSize',
        ...? (status != null ? {'status': status} : null),
      },
    );
    if (data is Map && data['items'] is List) return data['items'] as List;
    if (data is List) return data;
    return [];
  }

  Future<List<dynamic>> fetchBookmarks({int pageSize = 50}) async {
    final data = await _api.get(
      '/api/users/me/bookmarks',
      query: {'page': '1', 'pageSize': '$pageSize'},
    );
    if (data is Map && data['items'] is List) return data['items'] as List;
    if (data is List) return data;
    return [];
  }

  Future<void> markLessonComplete(int lessonId) async {
    await _api.post(
      '/api/lessons/$lessonId/progress',
      body: {'progressPercent': 100, 'status': 'completed'},
    );
  }

  Set<int> completedLessonIds(List<dynamic> progressItems) {
    final ids = <int>{};
    for (final item in progressItems) {
      if (item is! Map<String, dynamic>) continue;
      final status = item['status'] as String? ?? '';
      final percent = item['progressPercent'] as int? ?? 0;
      final lessonId = item['lessonId'] as int? ?? item['id'] as int?;
      if (lessonId != null && (status == 'completed' || percent >= 100)) {
        ids.add(lessonId);
      }
    }
    return ids;
  }
}
