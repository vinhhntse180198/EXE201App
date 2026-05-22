import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';

/// Nền sakura chấm + gradient — khớp `body` trong `theme.css`.
class YumeSakuraBackground extends StatelessWidget {
  const YumeSakuraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x0FE11D48),
                Colors.transparent,
              ],
              stops: [0, 0.3],
            ),
          ),
        ),
        CustomPaint(painter: _SakuraDotsPainter()),
        child,
      ],
    );
  }
}

class _SakuraDotsPainter extends CustomPainter {
  static const _dots = [
    (0.12, 0.22, 14.0, 0.12),
    (0.20, 0.70, 12.0, 0.10),
    (0.78, 0.18, 10.0, 0.10),
    (0.88, 0.62, 16.0, 0.12),
    (0.62, 0.82, 10.0, 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      final paint = Paint()
        ..color = YumeColors.primary.withValues(alpha: d.$4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width * d.$1, size.height * d.$2), d.$3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Thẻ kính mờ — `yume-mock-stat` / `phd-hero` trên web.
class YumeGlassCard extends StatelessWidget {
  const YumeGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: YumeColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (margin != null) card = Padding(padding: margin!, child: card);
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: card),
      );
    }
    return card;
  }
}
