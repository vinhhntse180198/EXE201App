import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_client.dart';

const _tokenKey = 'access_token';
const _userJsonKey = 'user_json';
const _needsPlacementKey = 'needs_placement_test';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    String? levelCode,
  }) async {
    final data = await _api.post(
      '/api/Auth/register',
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        if (levelCode != null && levelCode.isNotEmpty) 'levelCode': levelCode,
      },
    );
    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  Future<AuthResponse> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final data = await _api.post(
      '/api/Auth/login',
      body: {
        'usernameOrEmail': usernameOrEmail.trim(),
        'password': password,
      },
    );
    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  Future<AuthResponse> loginWithGoogleIdToken(String idToken) async {
    final data = await _api.post(
      '/api/Auth/google',
      body: {'idToken': idToken},
    );
    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/api/Auth/forgot-password', body: {'email': email.trim()});
  }

  Future<Map<String, dynamic>> forgotPasswordWithDevLink(String email) async {
    final data = await _api.post('/api/Auth/forgot-password', body: {'email': email.trim()});
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _api.post(
      '/api/Auth/reset-password',
      body: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> setNeedsPlacementTest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_needsPlacementKey, value);
  }

  Future<void> _persist(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, auth.accessToken);
    await prefs.setString(
      _userJsonKey,
      '${auth.user.id}|${auth.user.username}|${auth.user.email}|${auth.user.role}|${auth.user.exp}|${auth.user.xu}|${auth.user.isPremium}',
    );
    await prefs.setBool(_needsPlacementKey, auth.needsPlacementTest);
  }

  Future<AuthResponse?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    // Token giả từ design mode — bỏ qua, bắt đăng nhập lại.
    if (token == 'design-token') {
      await logout();
      return null;
    }

    _api.setToken(token);
    final raw = prefs.getString(_userJsonKey);
    if (raw != null && raw.contains('design_user')) {
      await logout();
      return null;
    }
    if (raw == null) {
      return AuthResponse(
        accessToken: token,
        user: const User(id: 0, username: '', email: '', role: 'Learner'),
      );
    }
    final parts = raw.split('|');
    final needsPlacement = prefs.getBool(_needsPlacementKey) ?? false;
    return AuthResponse(
      accessToken: token,
      user: User(
        id: int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
        username: parts.length > 1 ? parts[1] : '',
        email: parts.length > 2 ? parts[2] : '',
        role: parts.length > 3 ? parts[3] : 'Learner',
        exp: parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0,
        xu: parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0,
        isPremium: parts.length > 6 && parts[6] == 'true',
      ),
      needsPlacementTest: needsPlacement,
    );
  }

  Future<void> logout() async {
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userJsonKey);
    await prefs.remove(_needsPlacementKey);
  }
}
