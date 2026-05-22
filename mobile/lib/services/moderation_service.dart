import 'api_client.dart';

/// API Moderator — khớp web ModeratorDashboard.
class ModerationService {
  ModerationService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> fetchStaffOverview() async {
    final data = await _api.get('/api/Moderation/staff/overview');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listReports() async {
    final data = await _api.get('/api/Moderation/staff/reports');
    return data is List ? data : [];
  }

  Future<void> resolveReport(int reportId, {String? note}) async {
    await _api.patch(
      '/api/Moderation/staff/reports/$reportId/resolve',
      body: {if (note != null) 'note': note},
    );
  }

  Future<List<dynamic>> listLearners() async {
    final data = await _api.get('/api/Moderation/staff/learners');
    return data is List ? data : [];
  }

  Future<void> setLearnerLevel(int userId, String levelCode) async {
    await _api.patch(
      '/api/Moderation/staff/learners/$userId/level',
      body: {'levelCode': levelCode},
    );
  }

  Future<List<dynamic>> listStaffLessons() async {
    final data = await _api.get('/api/moderator/lessons');
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
}
