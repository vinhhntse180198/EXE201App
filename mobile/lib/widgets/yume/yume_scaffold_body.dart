import 'package:flutter/material.dart';

import '../../config/yume_decorations.dart';
import 'yume_sakura_background.dart';

/// Nền sakura + gradient dashboard — khớp `.yume-dashboard--crimson-sakura`.
class YumeScaffoldBody extends StatelessWidget {
  const YumeScaffoldBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.useDashboardGradient = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool useDashboardGradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: YumeSakuraBackground(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: useDashboardGradient ? YumeDecorations.dashboardGradient : null,
            color: useDashboardGradient ? null : const Color(0xFFFFFBFE),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
