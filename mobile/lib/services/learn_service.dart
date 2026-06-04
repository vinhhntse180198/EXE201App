import '../models/progress_summary.dart';
import '../utils/json_field.dart';
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
    return jsonApiMapList(data is Map ? jsonField(data as Map<String, dynamic>, 'items') ?? data : data);
  }

  Future<List<dynamic>> fetchBookmarks({int pageSize = 50}) async {
    final data = await _api.get(
      '/api/users/me/bookmarks',
      query: {'page': '1', 'pageSize': '$pageSize'},
    );
    return jsonApiMapList(data is Map ? jsonField(data as Map<String, dynamic>, 'items') ?? data : data);
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
      final status = (jsonStr(item, 'status') ?? '').toLowerCase();
      final percent = jsonInt(item, 'progressPercent') ?? 0;
      final lessonId = jsonInt(item, 'lessonId') ?? jsonInt(item, 'id');
      if (lessonId != null && (status == 'completed' || percent >= 100)) {
        ids.add(lessonId);
      }
    }
    return ids;
  }
}
