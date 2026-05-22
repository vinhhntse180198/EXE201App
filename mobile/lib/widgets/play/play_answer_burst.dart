import 'package:flutter/material.dart';

/// Flash xanh/đỏ khi trả lời — game arcade không có arena combat.
class PlayAnswerBurst extends StatefulWidget {
  const PlayAnswerBurst({super.key, required this.correct});

  final bool correct;

  @override
  State<PlayAnswerBurst> createState() => _PlayAnswerBurstState();
}

class _PlayAnswerBurstState extends State<PlayAnswerBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.correct ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final peak = t < 0.25 ? t / 0.25 : (1.0 - (t - 0.25) / 0.75);
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: peak * 0.42,
                  child: ColoredBox(color: color),
                ),
              ),
              Center(
                child: Transform.scale(
                  scale: 0.7 + peak * 0.35,
                  child: Opacity(
                    opacity: peak,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 24, spreadRadius: 2),
                        ],
                      ),
                      child: Text(
                        widget.correct ? 'Chính xác!' : 'Chưa đúng',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: widget.correct ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
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
