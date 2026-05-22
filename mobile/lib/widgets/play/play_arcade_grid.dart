import 'package:flutter/material.dart';

/// Nền lưới `play-arcade-shell--light` (web play-games.css).
class PlayArcadeGridBackground extends StatelessWidget {
  const PlayArcadeGridBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: CustomPaint(
        painter: _GridPainter(),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
