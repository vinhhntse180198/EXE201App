import 'api_client.dart';

/// API Moderator — khớp web ModeratorDashboard.
class ModerationService {
  ModerationService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> fetchStaffOverview() async {
    final data = await _api.get('/api/Moderation/staff/overview');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listStaffLessonsPaged({
    int? levelId,
    int? categoryId,
    String? search,
    bool? isPublished,
    int page = 1,
    int pageSize = 50,
  }) async {
    final qs = <String, String>{
      if (levelId != null) 'levelId': '$levelId',
      if (categoryId != null) 'categoryId': '$categoryId',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (isPublished != null) 'isPublished': isPublished ? 'true' : 'false',
      'page': '${page < 1 ? 1 : page}',
      'pageSize': '${pageSize.clamp(1, 200)}',
    };
    final data = await _api.get('/api/moderator/lessons', query: qs);
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List) return items;
    }
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> fetchStaffLessonFull(int lessonId) async {
    final data = await _api.get('/api/moderator/lessons/$lessonId');
    return data as Map<String, dynamic>;
  }

  Future<void> deleteStaffLesson(int lessonId) async {
    await _api.delete('/api/moderator/lessons/$lessonId');
  }

  Future<List<dynamic>> listReports({
    String? type,
    int? severity,
    String? status,
    int limit = 80,
  }) async {
    final qs = <String, String>{
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      if (severity != null) 'severity': '$severity',
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      'limit': '$limit',
    };
    final data = await _api.get('/api/Moderation/staff/reports', query: qs);
    return data is List ? data : [];
  }

  Future<void> resolveReport(
    int reportId, {
    String status = 'resolved',
    String? resolutionNote,
  }) async {
    await _api.patch(
      '/api/Moderation/staff/reports/$reportId/resolve',
      body: {
        'status': status,
        if (resolutionNote != null) 'resolutionNote': resolutionNote,
      },
    );
  }

  Future<void> escalateLockRequest(int reportId, {String? resolutionNote}) async {
    await _api.post(
      '/api/Moderation/staff/reports/$reportId/escalate-lock',
      body: {
        'status': 'pending_admin_lock',
        if (resolutionNote != null) 'resolutionNote': resolutionNote,
      },
    );
  }

  Future<void> issueWarning({
    required int userId,
    required String reason,
    int? reportId,
  }) async {
    await _api.post(
      '/api/Moderation/staff/warnings',
      body: {
        'userId': userId,
        'reason': reason,
        if (reportId != null) 'reportId': reportId,
      },
    );
  }

  Future<List<dynamic>> listWarningsForUser(int userId, {int limit = 50}) async {
    final data = await _api.get(
      '/api/Moderation/staff/users/$userId/warnings',
      query: {'limit': '$limit'},
    );
    return data is List ? data : [];
  }

  Future<List<dynamic>> listLearners() async {
    final data = await _api.get('/api/Moderation/staff/learners');
    return data is List ? data : [];
  }

  Future<void> setLearnerLevel(int userId, int? levelId) async {
    await _api.patch(
      '/api/Moderation/staff/learners/$userId/level',
      body: {'levelId': levelId},
    );
  }

  Future<List<dynamic>> listStaffLessons() async {
    final data = await _api.get('/api/moderator/lessons');
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List) return items;
    }
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> uploadLessonDocument({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _api.postMultipart(
      '/api/moderator/lessons/import/upload-document',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> extractLessonText({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _api.postMultipart(
      '/api/moderator/lessons/import/extract-text',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateLessonDraft({
    List<int>? bytes,
    String? filename,
    String? text,
    String? lessonKind,
  }) async {
    final fields = <String, String>{
      if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      if (lessonKind != null && lessonKind.trim().isNotEmpty) 'lessonKind': lessonKind.trim(),
    };
    final data = (bytes != null && filename != null && filename.trim().isNotEmpty)
        ? await _api.postMultipart(
            '/api/moderator/lessons/import/generate-draft',
            fieldName: 'file',
            bytes: bytes,
            filename: filename,
            fields: fields.isEmpty ? null : fields,
          )
        : await _api.postMultipart(
            '/api/moderator/lessons/import/generate-draft',
            fieldName: 'file',
            bytes: const <int>[],
            filename: 'empty.txt',
            fields: fields.isEmpty ? null : fields,
          );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createLessonFromDraft(Map<String, dynamic> body) async {
    final data = await _api.post('/api/moderator/lessons/import/create-from-draft', body: body);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLessonContentFromDraft(int lessonId, Map<String, dynamic> body) async {
    final data = await _api.put('/api/moderator/lessons/$lessonId/content-from-draft', body: body);
    return data as Map<String, dynamic>;
  }
}
