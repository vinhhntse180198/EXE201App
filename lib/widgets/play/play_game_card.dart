import 'package:flutter/material.dart';

import '../../models/game_item.dart';
import '../../utils/play_game_art.dart';

/// Thẻ game Play Hub — nút PLAY NOW luôn sát đáy khi [fillHeight] (cặp trong Row).
class PlayGameCard extends StatelessWidget {
  const PlayGameCard({
    super.key,
    required this.game,
    required this.onPlay,
    this.fillHeight = false,
  });

  final GameItem game;
  final VoidCallback onPlay;

  /// true khi thẻ nằm trong hàng 2 cột — căn nút xuống đáy, không khoảng trống giữa mô tả và nút.
  final bool fillHeight;

  static const _artHeight = 72.0;
  static const _btnHeight = 34.0;

  @override
  Widget build(BuildContext context) {
    final art = playGameCardAsset(game.code);
    final accent = playGameCardAccent(game.code);
    final deco = playGameCardDecoration(game.code);
    final category = (game.skillType?.isNotEmpty == true ? game.skillType! : 'Luyện tập').toUpperCase();
    final desc = game.description?.isNotEmpty == true ? game.description! : game.code;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _artBlock(art, accent),
        const SizedBox(height: 6),
        Text(
          game.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF0F172A),
            height: 1.15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          category,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
            color: accent.withValues(alpha: 0.9),
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (fillHeight) const Spacer() else const SizedBox(height: 10),
        _playNowButton(accent),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: deco,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _artBlock(String art, Color accent) {
    return SizedBox(
      height: _artHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.14), Colors.transparent],
                ),
              ),
              child: Image.asset(
                art,
                fit: BoxFit.contain,
                errorBuilder: (_, e, s) => Icon(Icons.sports_esports, size: 40, color: accent),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _badge('N5', const Color(0xFFFBBF24), const Color(0xFF92400E)),
                if (game.isPvp) ...[
                  const SizedBox(width: 4),
                  _badge('PvP', const Color(0xFF3B82F6), Colors.white),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withValues(alpha: 0.45)),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg)),
    );
  }

  Widget _playNowButton(Color accent) {
    return SizedBox(
      height: _btnHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
          color: accent.withValues(alpha: 0.12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPlay,
            borderRadius: BorderRadius.circular(9),
            child: Center(
              child: Text(
                'PLAY NOW',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.08,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
