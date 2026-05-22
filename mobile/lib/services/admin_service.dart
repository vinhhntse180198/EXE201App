import 'api_client.dart';

/// API Admin — khớp web AdminDashboard.
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> fetchOverview() async {
    final data = await _api.get('/api/Admin/overview');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listUsers() async {
    final data = await _api.get('/api/Auth/users');
    return data is List ? data : [];
  }

  Future<List<dynamic>> listGames() async {
    final data = await _api.get('/api/game/admin/games');
    return data is List ? data : [];
  }

  Future<List<dynamic>> listLockRequests() async {
    final data = await _api.get('/api/Moderation/admin/lock-requests');
    return data is List ? data : [];
  }

  Future<void> approveLockRequest(int reportId) async {
    await _api.post('/api/Moderation/admin/lock-requests/$reportId/approve', body: {});
  }

  Future<void> rejectLockRequest(int reportId) async {
    await _api.post('/api/Moderation/admin/lock-requests/$reportId/reject', body: {});
  }

  Future<Map<String, dynamic>> getPremiumConfig() async {
    final data = await _api.get('/api/Payment/admin/premium/config');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listPremiumRequests() async {
    final data = await _api.get('/api/Payment/admin/premium/requests');
    return data is List ? data : [];
  }

  Future<void> approvePremiumRequest(int id) async {
    await _api.post('/api/Payment/admin/premium/requests/$id/approve', body: {});
  }

  Future<void> rejectPremiumRequest(int id, {String? reason}) async {
    await _api.post(
      '/api/Payment/admin/premium/requests/$id/reject',
      body: {if (reason != null) 'reason': reason},
    );
  }

  Future<void> publishAnnouncement({
    required String title,
    required String content,
    String? type,
  }) async {
    await _api.post(
      '/api/Admin/system-announcements/publish',
      body: {
        'title': title,
        'content': content,
        if (type != null) 'type': type,
      },
    );
  }
}
