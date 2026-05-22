import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import 'learn_ai_widget.dart';

/// Banner AI Sensei — khớp web `learn-ai-promo`.
class LearnAiPromoBanner extends StatelessWidget {
  const LearnAiPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YumeColors.pinkLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => LearnWithAi.openAi(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [YumeColors.primary, YumeColors.sakura]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yumegoji AI Sensei',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: YumeColors.ink),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hỏi bài, phân tích ảnh & tài liệu — Ollama trên server.',
                        style: TextStyle(fontSize: 12, color: YumeColors.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: YumeColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
