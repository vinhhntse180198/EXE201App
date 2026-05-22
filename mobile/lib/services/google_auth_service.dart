import 'package:google_sign_in/google_sign_in.dart';

import '../config/api_config.dart';

/// Đăng nhập Google → idToken gửi POST /api/Auth/google.
/// Cần: OAuth Android client + Web client ID trong --dart-define=GOOGLE_SERVER_CLIENT_ID.
class GoogleAuthService {
  GoogleSignIn? get _signIn {
    if (!isGoogleSignInConfigured) return null;
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: googleServerClientId,
    );
  }

  Future<String?> signInAndGetIdToken() async {
    final signIn = _signIn;
    if (signIn == null) {
      throw StateError(
        'Chưa cấu hình GOOGLE_SERVER_CLIENT_ID. Xem lib/config/api_config.dart',
      );
    }

    final account = await signIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() async {
    await _signIn?.signOut();
  }
}
