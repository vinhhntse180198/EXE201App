import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lớp FX chém đỏ — khớp web `play-kana-battle__slash-*` + `kunai`.
class KanaSlashFxLayer extends StatelessWidget {
  const KanaSlashFxLayer({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w <= 0 || h <= 0) return const SizedBox.shrink();

        final sweepT = Curves.easeOut.transform((p / 0.55).clamp(0.0, 1.0));
        var sweepOpacity = 0.0;
        if (p < 0.18) {
          sweepOpacity = p / 0.18;
        } else if (p < 0.58) {
          sweepOpacity = 1.0;
        } else {
          sweepOpacity = (1.0 - (p - 0.58) / 0.42).clamp(0.0, 1.0);
        }

        final arcT = Curves.easeOut.transform(((p - 0.05) / 0.5).clamp(0.0, 1.0));
        var arcOpacity = 0.0;
        if (p > 0.08 && p < 0.72) arcOpacity = (p < 0.28 ? (p - 0.08) / 0.2 : 1.0) * (1.0 - ((p - 0.5) / 0.22).clamp(0.0, 1.0));

        final flashOpacity = p < 0.18
            ? p / 0.18
            : (p > 0.5 ? (1.0 - (p - 0.5) / 0.5).clamp(0.0, 1.0) : 1.0);

        final kunaiLeft = w * (0.12 + 0.58 * Curves.easeInOut.transform(p));
        final kunaiTop = h * (0.46 - 0.04 * math.sin(p * math.pi));
        final kunaiOpacity = p < 0.06
            ? p / 0.06
            : (p > 0.88 ? (1.0 - (p - 0.88) / 0.12).clamp(0.0, 1.0) : 1.0);

        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (flashOpacity > 0.02)
                Positioned.fill(
                  child: Opacity(
                    opacity: flashOpacity * 0.95,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.52, -0.15),
                          radius: 0.85,
                          colors: [
                            const Color(0xFFFECACA).withValues(alpha: 0.75),
                            const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                            const Color(0xFFDC2626).withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              if (sweepOpacity > 0.02)
                Positioned(
                  left: -w * 0.28,
                  top: h * 0.36,
                  child: Opacity(
                    opacity: sweepOpacity,
                    child: Transform.rotate(
                      angle: -0.38,
                      child: Transform.scale(
                        scaleX: 0.05 + sweepT * 1.02,
                        child: Container(
                          width: w * 1.55,
                          height: math.max(12.0, h * 0.16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x00000000),
                                Color(0x33450A0A),
                                Color(0xF27F1D1D),
                                Color(0xFADC2626),
                                Color(0xC0B91C1C),
                                Color(0x33450A0A),
                                Color(0x00000000),
                              ],
                              stops: [0.0, 0.12, 0.38, 0.5, 0.62, 0.78, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.75 * sweepOpacity),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: const Color(0xFF7F1D1D).withValues(alpha: 0.5 * sweepOpacity),
                                blurRadius: 36,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (arcOpacity > 0.02)
                Positioned(
                  left: w * 0.1,
                  top: h * 0.28,
                  child: Opacity(
                    opacity: arcOpacity,
                    child: Transform.rotate(
                      angle: -0.38 + arcT * 0.75,
                      child: Transform.scale(
                        scale: 0.42 + arcT * 0.78,
                        child: SizedBox(
                          width: w * 0.68,
                          height: h * 0.5,
                          child: CustomPaint(
                            painter: _SlashArcPainter(strokeWidth: 5.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (kunaiOpacity > 0.02)
                Positioned(
                  left: kunaiLeft,
                  top: kunaiTop,
                  child: Opacity(
                    opacity: kunaiOpacity,
                    child: Transform.rotate(
                      angle: -0.12 + p * 0.22,
                      child: Transform.scale(
                        scale: 0.5 + p * 0.65,
                        child: const _KunaiSprite(),
                      ),
                    ),
                  ),
                ),
              if (p > 0.2 && p < 0.65)
                Positioned(
                  left: w * 0.48,
                  top: h * 0.32,
                  child: Opacity(
                    opacity: ((p - 0.2) / 0.2).clamp(0.0, 1.0) * (1.0 - ((p - 0.45) / 0.2).clamp(0.0, 1.0)),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.92),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.9), blurRadius: 18, spreadRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KunaiSprite extends StatelessWidget {
  const _KunaiSprite();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(2), right: Radius.circular(10)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFECACA), Color(0xFF991B1B), Color(0xFF450A0A)],
                stops: [0.0, 0.45, 1.0],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.85), blurRadius: 14),
                const BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),
          Positioned(
            right: -6,
            top: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(12, 12),
              painter: _KunaiTipPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _KunaiTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFCA5A5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SlashArcPainter extends CustomPainter {
  _SlashArcPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = const Color(0xF0B91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawArc(rect, -2.4, 2.2, false, paint);
    final glow = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, -2.4, 2.2, false, glow);
  }

  @override
  bool shouldRepaint(covariant _SlashArcPainter oldDelegate) => oldDelegate.strokeWidth != strokeWidth;
}

/// Năng lượng tím khi trượt — khớp web `play-kana-orb-fly`.
class KanaOrbFxLayer extends StatelessWidget {
  const KanaOrbFxLayer({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeIn.transform(progress.clamp(0.0, 1.0));
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final size = 24.0 + 120 * p;
        final opacity = p < 0.12 ? p / 0.12 : (p > 0.75 ? (1 - p) / 0.25 : 1.0);
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                right: w * 0.18 - 40 * p,
                top: h * 0.34 + 20 * p,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFAE8FF),
                          const Color(0xFFA855F7).withValues(alpha: 0.95),
                          const Color(0xFF4C1D95).withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.85 * opacity),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: opacity * 0.35,
                  child: ColoredBox(color: const Color(0xFFDC2626).withValues(alpha: 0.22)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
