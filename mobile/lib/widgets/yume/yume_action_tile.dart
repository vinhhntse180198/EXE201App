import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import 'yume_sakura_background.dart';

class YumeActionTile extends StatelessWidget {
  const YumeActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return YumeGlassCard(
      onTap: onTap,
      radius: 18,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: YumeColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: YumeColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: YumeColors.muted),
        ],
      ),
    );
  }
}
