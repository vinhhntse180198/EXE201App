import '../models/user_profile.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService(this._api);

  final ApiClient _api;

  Future<UserProfile> fetchMyProfile() async {
    final data = await _api.get('/api/users/me/profile');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateMyProfile({
    String? displayName,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    DateTime? dateOfBirth,
    String? theme,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (coverUrl != null) body['coverUrl'] = coverUrl;
    if (bio != null) body['bio'] = bio;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth.toIso8601String();
    if (theme != null) body['theme'] = theme;

    final data = await _api.put('/api/users/me/profile', body: body);
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<String> uploadImage(List<int> bytes, String filename) async {
    final data = await _api.postMultipart(
      '/api/uploads/image',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );
    if (data is Map<String, dynamic>) {
      final url = data['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }
    throw ApiException('Upload không trả về URL.');
  }
}
