import 'package:flutter/material.dart';

/// Nút đáp án arcade — khớp web `.play-arcade__options` (ô trắng, viền, hover tím).
class ArcadeAnswerButton extends StatefulWidget {
  const ArcadeAnswerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.answered = false,
    this.correct,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool answered;
  final bool? correct;
  final bool disabled;

  @override
  State<ArcadeAnswerButton> createState() => _ArcadeAnswerButtonState();
}

class _ArcadeAnswerButtonState extends State<ArcadeAnswerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(ArcadeAnswerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.answered && widget.selected && !oldWidget.answered) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var border = const Color(0xFF0F172A).withValues(alpha: 0.14);
    var bg = Colors.white;
    var fg = const Color(0xFF0F172A);
    var glow = Colors.transparent;

    if (widget.answered && widget.selected) {
      final ok = widget.correct == true;
      border = ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      bg = ok ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
      fg = ok ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
      glow = (ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.45);
    } else if (widget.selected) {
      border = const Color(0xFFA78BFA);
      bg = const Color(0xFFF5F3FF);
      fg = const Color(0xFF6D28D9);
    }

    final scale = widget.answered && widget.selected ? 1.0 + 0.06 * Curves.elasticOut.transform(_pulse.value) : 1.0;

    return Transform.scale(
      scale: scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.disabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: border,
                  width: widget.selected || (widget.answered && widget.selected) ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: widget.disabled ? 0.02 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  if (glow != Colors.transparent)
                    BoxShadow(color: glow, blurRadius: 18, spreadRadius: 1),
                ],
              ),
              child: child,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: 0.02,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
