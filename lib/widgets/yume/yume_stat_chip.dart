import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import 'yume_sakura_background.dart';

class YumeStatChip extends StatelessWidget {
  const YumeStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: YumeGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        radius: 16,
        child: Column(
          children: [
            Icon(icon, color: YumeColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: YumeColors.ink,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11, color: YumeColors.muted)),
          ],
        ),
      ),
    );
  }
}
