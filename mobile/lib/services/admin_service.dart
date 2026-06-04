import 'api_client.dart';

/// API Admin — khớp web AdminDashboard.
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> fetchOverview() async {
    final data = await _api.get('/api/Admin/overview');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listSensitiveKeywords() async {
    final data = await _api.get('/api/Admin/sensitive-keywords');
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> createSensitiveKeyword({
    required String keyword,
    int severity = 1,
  }) async {
    final data = await _api.post(
      '/api/Admin/sensitive-keywords',
      body: {
        'keyword': keyword,
        'severity': severity,
      },
    );
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<void> updateSensitiveKeyword(
    int id, {
    String? keyword,
    int? severity,
    bool? isActive,
  }) async {
    await _api.patch(
      '/api/Admin/sensitive-keywords/$id',
      body: {
        if (keyword != null) 'keyword': keyword,
        if (severity != null) 'severity': severity,
        if (isActive != null) 'isActive': isActive,
      },
    );
  }

  Future<void> deleteSensitiveKeyword(int id) async {
    await _api.delete('/api/Admin/sensitive-keywords/$id');
  }

  Future<List<dynamic>> listUsers() async {
    final data = await _api.get('/api/Auth/users');
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getUserById(int id) async {
    final data = await _api.get('/api/Auth/users/$id');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateUser(
    int id, {
    String? role,
    int? levelId,
    bool? isLocked,
    bool? isPremium,
  }) async {
    final data = await _api.put(
      '/api/Auth/users/$id',
      body: {
        if (role != null) 'role': role,
        if (levelId != null) 'levelId': levelId,
        if (isLocked != null) 'isLocked': isLocked,
        if (isPremium != null) 'isPremium': isPremium,
      },
    );
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<void> deleteUser(int id) async {
    await _api.delete('/api/Auth/users/$id');
  }

  Future<List<dynamic>> listGames() async {
    final data = await _api.get('/api/game/admin/games');
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> createGame({
    required String slug,
    required String name,
    String? description,
    String? skillType,
    int maxHearts = 3,
    int sortOrder = 0,
  }) async {
    final data = await _api.post(
      '/api/game/admin/games',
      body: {
        'slug': slug,
        'name': name,
        if (description != null) 'description': description,
        if (skillType != null) 'skillType': skillType,
        'maxHearts': maxHearts,
        'sortOrder': sortOrder,
      },
    );
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<void> deleteGame(int id) async {
    await _api.delete('/api/game/admin/games/$id');
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

  Future<Map<String, dynamic>> updatePremiumConfig({
    int? premiumPriceVnd,
    int? premiumDurationDays,
  }) async {
    final data = await _api.put(
      '/api/Payment/admin/premium/config',
      body: {
        if (premiumPriceVnd != null) 'premiumPriceVnd': premiumPriceVnd,
        if (premiumDurationDays != null) 'premiumDurationDays': premiumDurationDays,
      },
    );
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
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

  Future<Map<String, dynamic>> requestDataBackup() async {
    final data = await _api.post('/api/Admin/data-backup-request', body: {});
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
