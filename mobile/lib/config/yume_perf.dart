import 'dart:io';

import 'package:flutter/foundation.dart';

/// UI nhẹ — tắt blur/glass, font mạng, nền phức tạp.
///
/// Mặc định **bật trên Android** (kể cả release/emulator) để tránh đơ.
/// UI đầy đủ: `flutter run --release --dart-define=FULL_UI=true`
const bool _liteUiFromDefine = bool.fromEnvironment('LITE_UI');
const bool _fullUiFromDefine = bool.fromEnvironment('FULL_UI');

bool get yumeLiteUi {
  if (_fullUiFromDefine) return false;
  if (_liteUiFromDefine || kDebugMode) return true;
  if (!kIsWeb && Platform.isAndroid) return true;
  return false;
}
