import '../../models/auth_response.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

/// Trạng thái đăng nhập toàn app — đọc từ mọi màn qua `AppSession.instance`.
class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  final ApiClient api = ApiClient();
  late final AuthService auth = AuthService(api);

  AuthResponse? user;

  bool get isLoggedIn => user != null && user!.accessToken.isNotEmpty;

  void applyAuth(AuthResponse authResponse) {
    user = authResponse;
    api.setToken(authResponse.accessToken);
  }

  void clear() {
    user = null;
    api.setToken(null);
  }
}
