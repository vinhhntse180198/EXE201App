import 'dart:io';

import 'package:flutter/foundation.dart';

/// URL API backend EXE201.
/// Chạy: `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5056`
const String _apiFromDefine = String.fromEnvironment('API_BASE_URL');

/// Web Client ID (Google Cloud) — dùng làm serverClientId để lấy idToken gửi backend.
/// Chạy: `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

String get apiBaseUrl {
  if (_apiFromDefine.isNotEmpty) {
    return _apiFromDefine.replaceAll(RegExp(r'/$'), '');
  }
  if (kIsWeb) return 'http://localhost:5056';
  if (Platform.isAndroid) return 'http://10.0.2.2:5056';
  return 'http://localhost:5056';
}

String get chatHubUrl => '${apiBaseUrl.replaceAll(RegExp(r'/$'), '')}/hubs/chat';

bool get isGoogleSignInConfigured => googleServerClientId.isNotEmpty;
