import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../data/homepage_content.dart';

/// Timeline Phương pháp Hanami — 2 giai đoạn, đường hồng giữa.
class HomeHanamiTimeline extends StatelessWidget {
  const HomeHanamiTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          const Text(
            HomepageContent.hanamiTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            HomepageContent.hanamiSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 24),
          ...List.generate(HomepageContent.hanamiStages.length, (i) {
            final stage = HomepageContent.hanamiStages[i];
            final isLast = i == HomepageContent.hanamiStages.length - 1;
            return _StageRow(stage: stage, showLineBelow: !isLast);
          }),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.showLineBelow});

  final HanamiStage stage;
  final bool showLineBelow;

  @override
  Widget build(BuildContext context) {
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        stage.imageOnRight ? 'assets/images/hero-japan.png' : 'assets/images/auth-register.png',
        width: 88,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => Container(
          width: 88,
          height: 64,
          color: const Color(0xFFFCE7F3),
          child: const Icon(Icons.eco_rounded, color: YumeColors.primary),
        ),
      ),
    );

    final textCol = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFD81B60)),
          ),
          Text(
            stage.subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          Text(
            stage.description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD81B60),
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
                if (showLineBelow)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFD81B60).withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: stage.imageOnRight
                    ? [textCol, const SizedBox(width: 10), thumb]
                    : [thumb, const SizedBox(width: 10), textCol],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
