import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../config/yume_perf.dart';

/// Bottom nav — pill active giống `.learner-nav__link--active` (mobile adaptation).
class YumeBottomNav extends StatelessWidget {
  const YumeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = [
    (icon: Icons.home_rounded, label: 'Trang chủ'),
    (icon: Icons.insights_rounded, label: 'Tổng quan'),
    (icon: Icons.menu_book_rounded, label: 'Học'),
    (icon: Icons.forum_rounded, label: 'Chat'),
    (icon: Icons.sports_esports_rounded, label: 'Chơi'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: yumeLiteUi ? 1 : 0.94),
        border: Border(top: BorderSide(color: YumeColors.border.withValues(alpha: 0.4))),
        boxShadow: yumeLiteUi
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: yumeLiteUi ? 0 : 200),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: selected
                          ? BoxDecoration(
                              color: const Color(0xFFB72025).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFB72025).withValues(alpha: 0.30),
                              ),
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: selected ? const Color(0xFF7F1D1D) : YumeColors.text,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                              color: selected ? const Color(0xFF7F1D1D) : YumeColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );

    if (yumeLiteUi) return nav;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: nav,
      ),
    );
  }
}
