import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kana_combat_effects.dart';
import 'kana_slash_fx.dart';

/// Chiến trường + hiệu ứng chiêu — khớp web `KanaNinjaYureiArena` + CSS combat.
class KanaNinjaArena extends StatefulWidget {
  const KanaNinjaArena({
    super.key,
    required this.kanaChar,
    required this.playerHpPct,
    required this.enemyHpPct,
    required this.effects,
    required this.fxGeneration,
    this.backdropAsset = 'assets/images/play/scene_1.png',
    this.ninjaAsset = 'assets/images/play/ninja_part_1.png',
    this.ghostAsset = 'assets/images/play/ghost_part_1.png',
  });

  final String kanaChar;
  final int playerHpPct;
  final int enemyHpPct;
  final KanaCombatEffects effects;
  final int fxGeneration;
  final String backdropAsset;
  final String ninjaAsset;
  final String ghostAsset;

  @override
  State<KanaNinjaArena> createState() => _KanaNinjaArenaState();
}

class _KanaNinjaArenaState extends State<KanaNinjaArena> with TickerProviderStateMixin {
  AnimationController? _strikeCtrl;

  @override
  void initState() {
    super.initState();
    _playStrikeAnim();
  }

  @override
  void didUpdateWidget(KanaNinjaArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fxGeneration != oldWidget.fxGeneration ||
        widget.effects.anim != oldWidget.effects.anim ||
        widget.effects.slashFx != oldWidget.effects.slashFx ||
        widget.effects.orbFx != oldWidget.effects.orbFx) {
      _playStrikeAnim();
    }
  }

  void _playStrikeAnim() {
    _strikeCtrl?.dispose();
    _strikeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 560))..forward();
  }

  @override
  void dispose() {
    _strikeCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fx = widget.effects;
    final strike = _strikeCtrl;
    final t = strike?.value ?? 0.0;
    final playerAttack = fx.anim == KanaBattleAnim.player;
    final enemyAttack = fx.anim == KanaBattleAnim.enemy;
    final shaking = fx.slashFx || fx.orbFx;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 228,
        child: AnimatedBuilder(
          animation: strike ?? const AlwaysStoppedAnimation(0),
          builder: (context, child) {
            final shakeX = shaking ? 6 * math.sin(t * math.pi * 10) * (1 - t * 0.4) : 0.0;
            final shakeY = shaking ? 3 * math.cos(t * math.pi * 8) * (1 - t * 0.5) : 0.0;
            return Transform.translate(offset: Offset(shakeX, shakeY), child: child);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _backdrop(),
              _screenFlashOverlay(fx.screenFlash),
              if (fx.slashFx) ...[
                KanaSlashFxLayer(progress: t),
                _hitLabel('CHÍ MẠNG!', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              ],
              if (fx.orbFx) ...[
                KanaOrbFxLayer(progress: t),
                _hitLabel('TRƯỢT!', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
              ],
              ...fx.floats.map(_floatChip),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  children: [
                    _hpRow('Samurai Hiro', widget.playerHpPct, const Color(0xFF22C55E), const Color(0xFF67E8F9)),
                    const SizedBox(height: 4),
                    _hpRow('Moku Spirit', widget.enemyHpPct, const Color(0xFFF97316), const Color(0xFFFACC15)),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _ninjaActor(playerAttack, enemyAttack, t)),
                  _kanaBubble(playerAttack),
                  Expanded(child: _ghostActor(playerAttack, enemyAttack, t)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backdrop() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.12), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.backdropAsset, fit: BoxFit.cover, errorBuilder: (_, e, s) => _gradientFallback()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, const Color(0xFF0F172A).withValues(alpha: 0.5)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenFlashOverlay(KanaScreenFlash flash) {
    if (flash == KanaScreenFlash.none) return const SizedBox.shrink();
    final color = flash == KanaScreenFlash.whiteHit
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFFEF4444).withValues(alpha: 0.62);
    return TweenAnimationBuilder<double>(
      key: ValueKey('flash-${widget.fxGeneration}-$flash'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      builder: (context, v, child) {
        return Opacity(opacity: v < 0.35 ? v / 0.35 : (1 - v) * 1.4, child: child);
      },
      child: ColoredBox(color: color),
    );
  }

  Widget _hitLabel(String text, Color color, Color bg) {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${widget.fxGeneration}-$text'),
        tween: Tween(begin: 0.65, end: 1.0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
              const BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
                shadows: const [Shadow(color: Colors.white, blurRadius: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _floatChip(KanaCombatFloat f) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(f.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOut,
      builder: (context, t, _) {
        final color = switch (f.tone) {
          KanaFloatTone.dmg => const Color(0xFFEF4444),
          KanaFloatTone.bonus => const Color(0xFFEAB308),
          KanaFloatTone.miss => const Color(0xFF94A3B8),
        };
        return Positioned(
          left: f.tone == KanaFloatTone.dmg ? 72 : null,
          right: f.tone == KanaFloatTone.miss ? 48 : (f.tone == KanaFloatTone.bonus ? 40 : null),
          top: 64 - 48 * t,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Text(
              f.text,
              style: TextStyle(
                fontSize: f.tone == KanaFloatTone.bonus ? 20 : 26,
                fontWeight: FontWeight.w900,
                color: color,
                shadows: const [
                  Shadow(color: Colors.white, blurRadius: 0),
                  Shadow(color: Color(0x99000000), blurRadius: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ninjaActor(bool playerAttack, bool enemyAttack, double t) {
    return AnimatedBuilder(
      animation: _strikeCtrl ?? const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        double dx = 0;
        double rot = 0;
        double scale = 1.0;
        if (playerAttack) {
          final e = Curves.easeOut.transform(t);
          dx = 42 * e;
          scale = 1.0 + 0.14 * math.sin(t * math.pi);
          rot = -0.06 * e;
        } else if (enemyAttack) {
          dx = -8 * math.sin(t * math.pi * 5);
          rot = -0.1 * math.sin(t * math.pi * 5);
        } else {
          dx = 2 * math.sin(t * math.pi * 2);
        }
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (playerAttack && t > 0.12 && t < 0.55)
                Positioned(
                  right: -8,
                  top: 24,
                  child: Opacity(
                    opacity: (1 - ((t - 0.12) / 0.43).abs()).clamp(0.0, 1.0),
                    child: Container(
                      width: 36,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(colors: [Color(0xFFFECACA), Color(0xFFDC2626)]),
                        boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.8), blurRadius: 12)],
                      ),
                    ),
                  ),
                ),
              Image.asset(
                widget.ninjaAsset,
                height: 118,
                fit: BoxFit.contain,
                errorBuilder: (_, e, s) => const Text('🥷', style: TextStyle(fontSize: 52)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ghostActor(bool playerAttack, bool enemyAttack, double t) {
    return AnimatedBuilder(
      animation: _strikeCtrl ?? const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        double dx = 0;
        double rot = 0;
        if (enemyAttack) {
          dx = -38 * Curves.easeOut.transform(t);
          rot = 0.14 * math.sin(t * math.pi * 4);
        } else if (playerAttack) {
          dx = 10 * math.sin(t * math.pi * 5);
          rot = 0.16 * math.sin(t * math.pi * 5);
        }
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(angle: rot, child: child),
        );
      },
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 2, bottom: 2),
          child: Image.asset(
            widget.ghostAsset,
            height: 118,
            fit: BoxFit.contain,
            errorBuilder: (_, e, s) => const Text('👻', style: TextStyle(fontSize: 52)),
          ),
        ),
      ),
    );
  }

  Widget _kanaBubble(bool playerAttack) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: playerAttack ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.55), width: 2),
              boxShadow: [
                BoxShadow(color: const Color(0xFFA78BFA).withValues(alpha: 0.4), blurRadius: 14),
                if (playerAttack)
                  BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.25), blurRadius: 18, spreadRadius: 2),
              ],
            ),
            child: Text(
              widget.kanaChar.isNotEmpty ? widget.kanaChar : '？',
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, height: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95), Color(0xFF9F1239)]),
      ),
    );
  }

  Widget _hpRow(String label, int pct, Color c1, Color c2) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 9,
              color: Colors.white.withValues(alpha: 0.14),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c1, c2]),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$pct%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70)),
      ],
    );
  }
}
