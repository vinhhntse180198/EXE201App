import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../config/yume_decorations.dart';
import '../yume/yume_sakura_background.dart';

/// Khung nền chung cho màn thi — sakura + gradient giống web layout.
class ExamShell extends StatelessWidget {
  const ExamShell({
    super.key,
    required this.body,
    this.appBar,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: appBar != null,
      appBar: appBar,
      body: YumeSakuraBackground(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: YumeDecorations.dashboardGradient),
          child: body,
        ),
      ),
    );
  }
}

/// AppBar trong suốt cho màn thi / kết quả.
PreferredSizeWidget examAppBar({
  required String title,
  VoidCallback? onBack,
}) {
  return AppBar(
    backgroundColor: Colors.white.withValues(alpha: 0.72),
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: onBack != null
        ? IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: YumeColors.ink),
          )
        : null,
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: YumeColors.ink),
    ),
  );
}
