import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import 'yume_sakura_background.dart';

/// Rank Bronze → Platinum — khớp web `RANK_TIERS` trên Dashboard.
class RankProgressCard extends StatelessWidget {
  const RankProgressCard({super.key, required this.exp});

  final int exp;

  static const _tiers = [
    (label: 'Bronze', min: 0),
    (label: 'Silver', min: 5000),
    (label: 'Gold', min: 15000),
    (label: 'Platinum', min: 30000),
  ];

  ({String current, String? next, int barPct, String foot}) _calc() {
    var idx = 0;
    for (var i = _tiers.length - 1; i >= 0; i--) {
      if (exp >= _tiers[i].min) {
        idx = i;
        break;
      }
    }
    final cur = _tiers[idx];
    if (idx >= _tiers.length - 1) {
      return (
        current: cur.label,
        next: null,
        barPct: 100,
        foot: 'Bạn đã đạt rank cao nhất hiện tại.',
      );
    }
    final next = _tiers[idx + 1];
    final span = next.min - cur.min;
    final inTier = span > 0 ? ((exp - cur.min) / span * 100).clamp(0, 100).round() : 0;
    return (
      current: cur.label,
      next: next.label,
      barPct: inTier,
      foot: '$inTier% đến ${next.label} (${_fmt(exp)} / ${_fmt(next.min)} XP)',
    );
  }

  static String _fmt(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final r = _calc();
    return YumeGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: YumeColors.primary),
              const SizedBox(width: 8),
              Text('Rank ${r.current}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          if (r.next != null) ...[
            const SizedBox(height: 8),
            Text('Tiếp theo: ${r.next}', style: const TextStyle(color: YumeColors.muted, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: r.barPct / 100,
              minHeight: 10,
              backgroundColor: YumeColors.pinkLight,
              color: YumeColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(r.foot, style: const TextStyle(fontSize: 11, color: YumeColors.muted)),
        ],
      ),
    );
  }
}
