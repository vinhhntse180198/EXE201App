import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../services/api_client.dart';
import '../../services/profile_service.dart';
import 'app_session.dart';

/// Xử lý 401 — token hết hạn hoặc không hợp lệ.
class SessionAuthGuard {
  static const sessionExpiredMessage =
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất và đăng nhập lại.';

  static bool isUnauthorized(Object error) {
    if (error is ApiException) return error.statusCode == 401;
    final s = error.toString();
    return s.contains('401') || s.contains('Unauthorized');
  }

  static String friendlyMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) return sessionExpiredMessage;
      return error.message;
    }
    if (isUnauthorized(error)) return sessionExpiredMessage;
    return error.toString();
  }

  /// Kiểm tra token còn dùng được (gọi API profile nhẹ).
  static Future<bool> validateSession() async {
    if (!AppSession.instance.isLoggedIn) return false;
    try {
      await ProfileService(AppSession.instance.api).fetchMyProfile();
      return true;
    } catch (e) {
      if (isUnauthorized(e)) return false;
      rethrow;
    }
  }

  /// Đăng xuất và mở lại màn Login.
  static Future<void> forceReLogin(BuildContext context, {String? snackMessage}) async {
    await AppSession.instance.auth.logout();
    AppSession.instance.clear();
    if (!context.mounted) return;
    if (snackMessage != null && snackMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackMessage)));
    }
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static Future<bool> handleIfUnauthorized(BuildContext context, Object error) async {
    if (!isUnauthorized(error)) return false;
    await forceReLogin(context, snackMessage: sessionExpiredMessage);
    return true;
  }
}
