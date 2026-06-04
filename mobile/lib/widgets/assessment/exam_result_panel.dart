import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../config/yume_decorations.dart';
import '../yume/yume_brand_mark.dart';
import 'exam_shell.dart';

/// Màn kết quả bài thi — khớp web placement / level-up result.
class ExamResultPanel extends StatelessWidget {
  const ExamResultPanel({
    super.key,
    required this.title,
    required this.headline,
    required this.score,
    required this.maxScore,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.badgeLabel,
    this.isPassed,
    this.detailLines = const [],
    this.onBack,
  });

  final String title;
  final String headline;
  final String? subtitle;
  final String? badgeLabel;
  final int score;
  final int maxScore;
  final bool? isPassed;
  final List<String> detailLines;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final pct = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);
    final passed = isPassed ?? true;
    final accent = passed ? const Color(0xFF059669) : YumeColors.primary;

    return ExamShell(
      appBar: examAppBar(title: title, onBack: onBack),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: passed
                                ? [const Color(0xFF059669), const Color(0xFF34D399)]
                                : [YumeColors.primary, YumeColors.sakura],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                          child: Column(
                            children: [
                              const YumeBrandMark(size: 44, showTitle: true),
                              const SizedBox(height: 18),
                              Icon(
                                passed ? Icons.emoji_events_rounded : Icons.highlight_off_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                headline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              if (badgeLabel != null && badgeLabel!.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    badgeLabel!,
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ],
                              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  subtitle!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), height: 1.35),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: YumeColors.primary.withValues(alpha: 0.1)),
                        boxShadow: YumeDecorations.glassShadow,
                      ),
                      child: Column(
                        children: [
                          _ScoreRing(percent: pct, accent: accent, passed: passed),
                          const SizedBox(height: 16),
                          Text(
                            '$score / $maxScore câu đúng',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: YumeColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(pct * 100).round()}% hoàn thành',
                            style: const TextStyle(color: YumeColors.muted, fontSize: 13),
                          ),
                          if (detailLines.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            ...detailLines.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 16, color: accent.withValues(alpha: 0.85)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(line, style: const TextStyle(color: YumeColors.text, height: 1.35, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GradientButton(label: primaryLabel, onPressed: onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.percent, required this.accent, required this.passed});

  final double percent;
  final Color accent;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: CustomPaint(
        painter: _RingPainter(percent: percent, color: accent),
        child: Center(
          child: Text(
            '${(percent * 100).round()}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: passed ? accent : YumeColors.primaryHover),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final bg = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: YumeDecorations.playHeroGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: YumeColors.primary.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
