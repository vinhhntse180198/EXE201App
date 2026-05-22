import 'package:flutter/material.dart';

import '../../data/homepage_content.dart';

/// Khối "Tính năng nổi bật" — Học tập, Trò chuyện, Trò chơi.
class HomeFeaturesSection extends StatelessWidget {
  const HomeFeaturesSection({super.key, required this.onFeatureTap});

  final void Function(int index) onFeatureTap;

  static const _linkColor = Color(0xFFB00020);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          const Text(
            HomepageContent.featuresTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            HomepageContent.featuresSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 20),
          ...List.generate(HomepageContent.features.length, (i) {
            final f = HomepageContent.features[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < HomepageContent.features.length - 1 ? 12 : 0),
              child: _FeatureTile(feature: f, onTap: () => onFeatureTap(i)),
            );
          }),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature, required this.onTap});

  final HomepageFeatureCard feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: feature.iconColor.withValues(alpha: 0.12),
                ),
                child: Icon(feature.icon, color: feature.iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                feature.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                feature.description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A), height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                feature.linkLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HomeFeaturesSection._linkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
