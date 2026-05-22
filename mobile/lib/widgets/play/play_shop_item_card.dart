import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../data/play_shop_content.dart';
import '../../models/game_inventory.dart';
import 'play_powerup_art.dart';

/// Thẻ vật phẩm cửa hàng — layout mockup mobile (icon, badge, giá ★, nút Mua).
class PlayShopItemCard extends StatelessWidget {
  const PlayShopItemCard({
    super.key,
    required this.item,
    required this.xuBalance,
    required this.busy,
    required this.onBuy,
    required this.formatInt,
  });

  final PowerUpItem item;
  final int xuBalance;
  final bool busy;
  final VoidCallback? onBuy;
  final String Function(int) formatInt;

  @override
  Widget build(BuildContext context) {
    final price = item.xuPrice;
    final canBuy = price != null && price > 0 && xuBalance >= price;
    final art = PlayPowerupArt.assetForSlug(item.slug);
    final title = PlayShopContent.displayName(item);
    final desc = PlayShopContent.displayDescription(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconBox(art),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: YumeColors.ink,
                    height: 1.2,
                  ),
                ),
                if (item.isPremium) ...[
                  const SizedBox(height: 4),
                  _premiumChip(),
                ],
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13, color: YumeColors.muted, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đang có: ${formatInt(item.quantityOwned)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: YumeColors.text),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (price != null && price > 0) ...[
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        formatInt(price),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: YumeColors.ink),
                      ),
                    ] else
                      const Text('Chưa bán bằng xu', style: TextStyle(color: YumeColors.muted, fontSize: 12)),
                    const Spacer(),
                    _buyButton(canBuy: canBuy, busy: busy),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: _qtyBadge(formatInt(item.quantityOwned)),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(String art) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: YumeColors.pinkLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YumeColors.primary.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        art,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.extension, color: YumeColors.primary),
      ),
    );
  }

  Widget _qtyBadge(String qty) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YumeColors.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: YumeColors.primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        qty,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _premiumChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)]),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('PREMIUM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
    );
  }

  Widget _buyButton({required bool canBuy, required bool busy}) {
    final label = busy ? 'Đang mua…' : (canBuy ? 'Mua' : 'Không đủ xu');
    return FilledButton(
      onPressed: busy || !canBuy ? null : onBuy,
      style: FilledButton.styleFrom(
        backgroundColor: YumeColors.primary,
        disabledBackgroundColor: const Color(0xFFFECDD3),
        disabledForegroundColor: const Color(0xFFFDA4AF),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
