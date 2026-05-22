import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nền Play Hub — khớp web `.phd-glass-layer` + sakura nhẹ.
class PlayHubBackground extends StatelessWidget {
  const PlayHubBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF5F8),
                Color(0xFFF8FAFC),
                Color(0xFFFFF1F5),
              ],
            ),
          ),
        ),
        CustomPaint(painter: _HubGlowPainter()),
        const _SakuraLayer(),
        child,
      ],
    );
  }
}

class _HubGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pink = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFE4EB).withValues(alpha: 0.55), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.9, size.height * 0.45));
    canvas.drawRect(Offset.zero & size, pink);

    final blue = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        colors: [const Color(0xFFE0E7FF).withValues(alpha: 0.45), Colors.transparent],
      ).createShader(Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.6, size.height * 0.4));
    canvas.drawRect(Offset.zero & size, blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SakuraLayer extends StatelessWidget {
  const _SakuraLayer();

  static const _petals = [
    Offset(0.08, 0.12),
    Offset(0.82, 0.08),
    Offset(0.65, 0.22),
    Offset(0.22, 0.35),
    Offset(0.92, 0.38),
    Offset(0.12, 0.55),
    Offset(0.48, 0.62),
    Offset(0.75, 0.72),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              for (var i = 0; i < _petals.length; i++)
                Positioned(
                  left: constraints.maxWidth * _petals[i].dx,
                  top: constraints.maxHeight * _petals[i].dy,
                  child: Transform.rotate(
                    angle: (i * 0.7) % math.pi,
                    child: Text(
                      '❀',
                      style: TextStyle(
                        fontSize: 10 + (i % 3) * 4.0,
                        color: const Color(0xFFFB7185).withValues(alpha: 0.22 + (i % 2) * 0.08),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
