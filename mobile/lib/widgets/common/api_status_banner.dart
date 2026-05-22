import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../config/app_build.dart';
import '../../config/app_flags.dart';
import '../../core/session/app_session.dart';

/// Banner xanh = đang dùng API thật (mặc định).
class ApiStatusBanner extends StatelessWidget {
  const ApiStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (designMode) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFFFF3CD),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: const Text(
          '⚠ DESIGN_MODE — dữ liệu mẫu design_user. Chạy: flutter run -d emulator-5554 (KHÔNG thêm DESIGN_MODE)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
        ),
      );
    }
    final name = AppSession.instance.user?.user.username ?? '';
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Text(
        name.isEmpty
            ? '✓ $appBuildLabel · $apiBaseUrl · Đăng nhập'
            : '✓ $appBuildLabel · $name · $apiBaseUrl',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade900),
      ),
    );
  }
}
