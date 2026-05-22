import 'package:flutter/material.dart';

import 'yume_colors.dart';

/// Shadow / gradient / radius — khớp `theme.css`, `yume-dashboard.css`, `play-hub`.
abstract final class YumeDecorations {
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;
  static const radiusXl = 22.0;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.10),
          blurRadius: 15,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: const Color(0xFFBE123C).withValues(alpha: 0.07),
          blurRadius: 36,
          offset: const Offset(0, 10),
        ),
      ];

  static const dashboardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFFAFC),
      Color(0xFFFFE4E9),
      Color(0xFFFFF5F8),
      Color(0xFFFDF2F8),
    ],
    stops: [0.0, 0.28, 0.52, 0.78, 1.0],
  );

  static const authHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xEBE11D48),
      Color(0xCCFB7185),
    ],
  );

  static const playHeroGradient = LinearGradient(
    colors: [YumeColors.primary, YumeColors.sakura],
  );

  static BoxDecoration glassCard({double radius = radiusLg}) => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
        boxShadow: glassShadow,
      );

  static BoxDecoration navActivePill = BoxDecoration(
    color: const Color(0xFFB72025).withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(radiusSm),
    border: Border.all(color: const Color(0xFFB72025).withValues(alpha: 0.30)),
  );
}
