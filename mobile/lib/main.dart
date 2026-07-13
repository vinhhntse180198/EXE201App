import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'config/app_flags.dart';
import 'config/app_theme.dart';

/// Điểm vào app — không chặn UI khi tải font (tránh màn hình trắng/đơ trên emulator).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('Yume: designMode=$designMode (API thật khi false)');
  }
  runApp(const YumeApp());

  if (AppTheme.useBundledSystemFonts) return;

  unawaited(
    GoogleFonts.pendingFonts([
      GoogleFonts.notoSans(),
      GoogleFonts.notoSans(fontWeight: FontWeight.w500),
      GoogleFonts.notoSans(fontWeight: FontWeight.w600),
      GoogleFonts.notoSans(fontWeight: FontWeight.w700),
      GoogleFonts.notoSans(fontWeight: FontWeight.w800),
    ]).timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        if (kDebugMode) {
          debugPrint('Yume: font preload timeout — dùng font hệ thống tạm thời.');
        }
        return <void>[];
      },
    ).then((_) => AppTheme.markFontsReady()),
  );
}
