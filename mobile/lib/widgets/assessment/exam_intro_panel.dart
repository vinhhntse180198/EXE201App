import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../config/yume_decorations.dart';
import '../yume/yume_brand_mark.dart';
import '../yume/yume_sakura_background.dart';

/// Màn giới thiệu trước khi làm bài — khớp web `phd-hero` / placement intro.
class ExamIntroPanel extends StatelessWidget {
  const ExamIntroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rules,
    required this.onStart,
    this.description,
    this.badgeLabel,
    this.onBack,
    this.primaryLabel = 'Bắt đầu làm bài',
  });

  final String title;
  final String subtitle;
  final String? description;
  final String? badgeLabel;
  final List<String> rules;
  final String primaryLabel;
  final VoidCallback onStart;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YumeSakuraBackground(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: YumeDecorations.dashboardGradient),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded, color: YumeColors.ink),
                        )
                      else
                        const SizedBox(width: 8),
                      const Expanded(child: YumeBrandMark(size: 36)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _HeroBanner(title: title, subtitle: subtitle, badgeLabel: badgeLabel),
                      const SizedBox(height: 16),
                      YumeGlassCard(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (description != null && description!.trim().isNotEmpty) ...[
                              Text(
                                description!,
                                style: const TextStyle(color: YumeColors.text, height: 1.45, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const Text(
                              'Quy định bài thi',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: YumeColors.ink),
                            ),
                            const SizedBox(height: 12),
                            ...rules.map(
                              (rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: YumeDecorations.playHeroGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(rule, style: const TextStyle(color: YumeColors.text, height: 1.4, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _StartButton(label: primaryLabel, onPressed: onStart),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.title, required this.subtitle, this.badgeLabel});

  final String title;
  final String subtitle;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              YumeColors.primary,
              YumeColors.sakura.withValues(alpha: 0.92),
            ],
          ),
          boxShadow: [
            BoxShadow(color: YumeColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badgeLabel != null && badgeLabel!.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              Text(
                title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: YumeDecorations.playHeroGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: YumeColors.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
