import 'package:flutter/material.dart';

/// Ảnh thẻ game Play Hub — khớp web `coverForGame` / `assets/play/*.png`.
String playGameCardAsset(String slug) {
  final s = slug.toLowerCase().replaceAll('_', '-');
  if (s.contains('pvp') || s.contains('battle')) {
    return 'assets/images/play/pvp-samurai.png';
  }
  const map = <String, String>{
    'hiragana-match': 'assets/images/play/card-hiragana.png',
    'katakana-match': 'assets/images/play/card-katakana.png',
    'flashcard-vocabulary': 'assets/images/play/card-flashcard-vocab.png',
    'flashcard-battle': 'assets/images/play/card-flashcard-vocab.png',
    'multiple-choice': 'assets/images/play/card-multiple-choice.png',
    'kanji-memory': 'assets/images/play/kanji-memory-stones.png',
    'vocabulary-speed-quiz': 'assets/images/play/vocab-speed.png',
    'sentence-builder': 'assets/images/play/sentence-builder.png',
    'counter-quest': 'assets/images/play/kanji-puzzle.png',
    'boss-battle': 'assets/images/play/boss-battle.png',
    'daily-challenge': 'assets/images/play/daily-challenge.png',
    'fill-in-blank': 'assets/images/play/badge-cyan-holo.png',
    'listen-choose': 'assets/images/play/badge-neon-pink.png',
  };
  if (map.containsKey(s)) return map[s]!;
  if (s.contains('hiragana')) return map['hiragana-match']!;
  if (s.contains('katakana')) return map['katakana-match']!;
  if (s.contains('kanji')) return map['kanji-memory']!;
  if (s.contains('flashcard') || s.contains('vocab')) {
    return map['flashcard-vocabulary']!;
  }
  return 'assets/images/play/badge-cyan-holo.png';
}

/// Nền + viền thẻ — khớp `play-dash__gcard--*` web (light).
BoxDecoration playGameCardDecoration(String slug) {
  final accent = playGameCardAccent(slug);
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: accent.withValues(alpha: 0.38)),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.14),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// Màu viền thẻ — khớp `themeClass` web.
Color playGameCardAccent(String slug) {
  final s = slug.toLowerCase();
  if (s.contains('pvp')) return const Color(0xFF7C3AED);
  if (s.contains('hiragana')) return const Color(0xFFDB2777);
  if (s.contains('katakana')) return const Color(0xFF059669);
  if (s.contains('kanji')) return const Color(0xFFD97706);
  if (s.contains('vocab') || s.contains('flashcard')) return const Color(0xFF2563EB);
  return const Color(0xFF0EA5E9);
}
