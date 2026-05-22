import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_flags.dart';

/// Điểm vào app — chỉ gọi runApp.
/// Code màn hình nằm trong `lib/screens/`, API trong `lib/services/`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('Yume: designMode=$designMode (API thật khi false)');
  }
  runApp(const YumeApp());
}
