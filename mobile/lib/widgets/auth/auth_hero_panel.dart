import 'package:flutter/material.dart';

import '../../config/yume_decorations.dart';

/// Panel trái auth — gradient sakura + copy (mobile: banner trên form).
class AuthHeroPanel extends StatelessWidget {
  const AuthHeroPanel({
    super.key,
    this.title = 'Học tiếng Nhật\ncùng Yume',
    this.subtitle = 'Bài học, game kana, chat cộng đồng — một hành trình duy nhất.',
    this.compact = false,
    this.imageAsset,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        gradient: YumeDecorations.authHeroGradient,
        borderRadius: BorderRadius.circular(compact ? 18 : 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageAsset != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(imageAsset!, height: compact ? 100 : 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 20),
            _miniSocialProof(),
          ],
        ],
      ),
    );
  }

  Widget _miniSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _avatarDot(0),
          _avatarDot(-8),
          _avatarDot(-8),
          const SizedBox(width: 12),
          Text(
            'Cộng đồng học viên Yume',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }

  Widget _avatarDot(double overlap) {
    return Transform.translate(
      offset: Offset(overlap, 0),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 2),
        ),
      ),
    );
  }
}
