import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';

class DesignModeBanner extends StatelessWidget {
  const DesignModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (designMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: YumeColors.pinkLight,
        child: const Text(
          'DESIGN MODE · Dữ liệu mẫu (design_user). API thật: flutter run --dart-define=DESIGN_MODE=false',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: YumeColors.pinkDark, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFFE8F5E9),
      child: Text(
        'API thật · $apiBaseUrl · Cần đăng nhập + backend đang chạy',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.w600),
      ),
    );
  }
}
