import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../config/yume_decorations.dart';
import '../yume/yume_sakura_background.dart';

const premiumGold = Color(0xFFB45309);
const premiumGoldLight = Color(0xFFFFF7ED);
const premiumGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
);

const freeFeatures = [
  'Bài học cơ bản theo cấp độ',
  'Game giới hạn lượt',
  'Chat công khai',
  'Xem bảng xếp hạng',
];

const premiumFeatures = [
  'Không giới hạn lượt chơi',
  'Tất cả bài học (kể cả nâng cao)',
  'Không quảng cáo',
  'Vật phẩm game mỗi ngày',
  'Nhóm chat riêng & PvP',
  'Huy hiệu Premium',
];

const comparisonRows = <(String label, bool free, bool premium)>[
  ('Bài học cơ bản theo cấp độ', true, true),
  ('Bài học nâng cao', false, true),
  ('Không giới hạn lượt chơi', false, true),
  ('Chat công khai', true, true),
  ('Nhóm chat riêng & PvP', false, true),
  ('Không quảng cáo', false, true),
  ('Vật phẩm game mỗi ngày', false, true),
  ('Xem bảng xếp hạng', true, true),
  ('Huy hiệu Premium', false, true),
];

class PremiumHeroBanner extends StatelessWidget {
  const PremiumHeroBanner({super.key, required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isPremium ? premiumGradient : YumeDecorations.playHeroGradient,
          boxShadow: [
            BoxShadow(
              color: (isPremium ? premiumGold : YumeColors.primary).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isPremium ? Icons.workspace_premium_rounded : Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Bạn đang dùng Premium' : 'Nâng cấp Premium',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremium
                              ? 'Tận hưởng đầy đủ tính năng YumeGo-ji.'
                              : 'Mở khóa học tập, game và cộng đồng không giới hạn.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({
    super.key,
    required this.title,
    required this.ribbon,
    required this.price,
    required this.priceSub,
    required this.features,
    required this.isPremiumStyle,
    required this.isCurrent,
    required this.buttonLabel,
    this.onPressed,
    this.recommended = false,
  });

  final String title;
  final String ribbon;
  final String price;
  final String priceSub;
  final List<String> features;
  final bool isPremiumStyle;
  final bool isCurrent;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final accent = isPremiumStyle ? premiumGold : YumeColors.primary;
    final accentBg = isPremiumStyle ? premiumGoldLight : YumeColors.pinkLight;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, recommended ? 24 : 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent
                  ? accent
                  : (recommended ? premiumGold.withValues(alpha: 0.45) : YumeColors.border),
              width: isCurrent || recommended ? 2 : 1,
            ),
            boxShadow: YumeDecorations.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ribbon,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent),
                    ),
                  ),
                  if (isCurrent) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Đang dùng',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isPremiumStyle ? premiumGold : YumeColors.ink,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: YumeColors.ink),
                  children: [
                    TextSpan(text: price),
                    TextSpan(
                      text: ' $priceSub',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: YumeColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...features.map((f) => _FeatureRow(text: f, accent: accent)),
              const SizedBox(height: 18),
              _PlanButton(
                label: buttonLabel,
                accent: accent,
                isPremiumStyle: isPremiumStyle,
                enabled: onPressed != null,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
        if (recommended)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: premiumGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: premiumGold.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Text(
                  'ĐỀ XUẤT',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PremiumComparisonTable extends StatelessWidget {
  const PremiumComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    return YumeGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bảng so sánh chi tiết',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: YumeColors.ink),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Tính năng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: YumeColors.muted)),
              ),
              Expanded(
                child: Text(
                  'Free',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: YumeColors.primary),
                ),
              ),
              Expanded(
                child: Text(
                  'Premium',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: premiumGold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...comparisonRows.map((row) => _ComparisonRow(label: row.$1, free: row.$2, premium: row.$3)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 14, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: YumeColors.text, height: 1.35, fontSize: 14))),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.free, required this.premium});

  final String label;
  final bool free;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 13, color: YumeColors.text, height: 1.3))),
          Expanded(child: Center(child: _TickCell(enabled: free, color: YumeColors.primary))),
          Expanded(child: Center(child: _TickCell(enabled: premium, color: premiumGold))),
        ],
      ),
    );
  }
}

class _TickCell extends StatelessWidget {
  const _TickCell({required this.enabled, required this.color});

  final bool enabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return Icon(Icons.check_circle_rounded, size: 20, color: color);
    }
    return Icon(Icons.remove_rounded, size: 20, color: YumeColors.muted.withValues(alpha: 0.45));
  }
}

class _PlanButton extends StatelessWidget {
  const _PlanButton({
    required this.label,
    required this.accent,
    required this.isPremiumStyle,
    required this.enabled,
    this.onPressed,
  });

  final String label;
  final Color accent;
  final bool isPremiumStyle;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: YumeColors.muted, fontSize: 14)),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isPremiumStyle ? premiumGradient : YumeDecorations.playHeroGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
