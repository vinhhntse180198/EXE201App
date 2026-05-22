import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../data/homepage_content.dart';

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
            children: HomepageContent.footerLinks
                .map(
                  (l) => Text(
                    l,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                )
                .toList(),
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
