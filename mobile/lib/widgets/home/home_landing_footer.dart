import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../data/homepage_content.dart';
import '../../utils/yume_links.dart';

/// Footer landing — logo, link, copyright.
class HomeLandingFooter extends StatelessWidget {
  const HomeLandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          const Text(
            HomepageContent.brandName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: YumeColors.primary),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: HomepageContent.footerLinks.map((link) {
              final isLink = link.url != null;
              final style = TextStyle(
                fontSize: 12,
                color: isLink ? YumeColors.primary : const Color(0xFF64748B),
                fontWeight: isLink ? FontWeight.w700 : FontWeight.w500,
                decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                decorationColor: YumeColors.primary.withValues(alpha: 0.5),
              );
              if (!isLink) {
                return Text(link.label, style: style);
              }
              return InkWell(
                onTap: () => openYumeFacebookPage(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.facebook, size: 14, color: YumeColors.primary),
                      const SizedBox(width: 4),
                      Text(link.label, style: style),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            HomepageContent.footerCopyright,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
