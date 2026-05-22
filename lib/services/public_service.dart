import '../models/system_announcement.dart';
import 'api_client.dart';

class PublicService {
  PublicService(this._api);

  final ApiClient _api;

  Future<SystemAnnouncement?> fetchLatestAnnouncement() async {
    try {
      final data = await _api.get('/api/Public/system-announcements/latest');
      if (data == null) return null;
      if (data is Map<String, dynamic>) return SystemAnnouncement.fromJson(data);
      return null;
    } catch (_) {
      return null;
    }
  }
}
