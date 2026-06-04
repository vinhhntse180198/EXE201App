import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';

/// Logo + vòng sakura — khớp `.layout-header__sakura-ring` / learner-nav brand.
class YumeBrandMark extends StatelessWidget {
  const YumeBrandMark({
    super.key,
    this.size = 40,
    this.showTitle = true,
    this.title = 'YumeGo-Ji',
    this.assetPath = 'assets/images/yume-logo.png',
  });

  final double size;
  final bool showTitle;
  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF1F2), Color(0xFFFFFBEB)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: YumeColors.primary.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: YumeColors.primary.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(size * 0.22),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  'ゆ',
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFBD0039),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: size * 0.34,
              letterSpacing: -0.5,
              color: const Color(0xFFBD0039),
            ),
          ),
        ],
      ],
    );
  }
}
