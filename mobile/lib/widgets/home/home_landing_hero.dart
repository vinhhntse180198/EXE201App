import 'package:flutter/material.dart';

import '../../data/homepage_content.dart';

/// Hero full-bleed — mẫu landing (ảnh nền + chữ trắng + CTA hồng).
class HomeLandingHero extends StatelessWidget {
  const HomeLandingHero({
    super.key,
    required this.ctaLabel,
    required this.onCta,
    this.welcomeLine,
  });

  final String ctaLabel;
  final VoidCallback onCta;
  final String? welcomeLine;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hero-japan.png',
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(color: const Color(0xFFFCE7F3)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (welcomeLine != null) ...[
                    Text(
                      welcomeLine!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(text: '${HomepageContent.heroTitle}\n'),
                        const TextSpan(
                          text: HomepageContent.heroHighlight,
                          style: TextStyle(color: Color(0xFFFFB4C8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    HomepageContent.heroDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onCta,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD81B60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(ctaLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
