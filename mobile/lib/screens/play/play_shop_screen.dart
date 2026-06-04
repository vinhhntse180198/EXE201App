import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../core/session/session_auth_guard.dart';
import '../../data/play_shop_content.dart';
import '../../models/game_inventory.dart';
import '../../models/progress_summary.dart';
import '../../services/api_client.dart';
import '../../services/game_service.dart';
import '../../services/learn_service.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/play/play_shop_balance_card.dart';
import '../../widgets/play/play_shop_item_card.dart';
import '../upgrade/upgrade_screen.dart';

/// Cửa hàng vật phẩm — Sakura Learning, tối ưu mobile (mockup Play Hub).
class PlayShopScreen extends StatefulWidget {
  const PlayShopScreen({
    super.key,
    this.embedded = false,
    this.onBalanceChanged,
  });

  final bool embedded;
  final VoidCallback? onBalanceChanged;

  @override
  State<PlayShopScreen> createState() => _PlayShopScreenState();
}

class _PlayShopScreenState extends State<PlayShopScreen> {
  static const _shopCream = Color(0xFFF9F7F2);

  final _game = GameService(AppSession.instance.api);
  final _learn = LearnService(AppSession.instance.api);

  GameInventory? _inventory;
  int _xu = 0;
  bool _loading = false;
  String? _error;
  String? _msgOk;
  String? _msgErr;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    if (!designMode) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _msgErr = null;
    });
    try {
      final results = await Future.wait([
        _game.fetchInventory(),
        _learn.fetchProgressSummary(),
      ]);
      if (mounted) {
        setState(() {
          _inventory = results[0] as GameInventory;
          _xu = (results[1] as ProgressSummary).xu;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (await SessionAuthGuard.handleIfUnauthorized(context, e)) return;
      setState(() {
        _inventory = null;
        _error = SessionAuthGuard.friendlyMessage(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy(PowerUpItem item) async {
    final price = item.xuPrice;
    if (price == null || price < 1 || _busyId != null) return;
    if (_xu < price) {
      setState(() => _msgErr = 'Không đủ xu để mua ${PlayShopContent.displayName(item)}.');
      return;
    }
    setState(() {
      _busyId = item.id;
      _msgOk = null;
      _msgErr = null;
    });
    try {
      final res = await _game.purchasePowerUp(powerUpSlug: item.slug);
      if (mounted) {
        setState(() {
          _xu = res.xuBalance;
          _msgOk = 'Đã mua 1 ${PlayShopContent.displayName(item)}.';
        });
        widget.onBalanceChanged?.call();
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (await SessionAuthGuard.handleIfUnauthorized(context, e)) return;
      setState(() {
        _msgErr = e is ApiException ? e.message : SessionAuthGuard.friendlyMessage(e);
      });
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    final bg = widget.embedded ? Colors.white : _shopCream;

    if (widget.embedded) {
      return ColoredBox(color: bg, child: body);
    }
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Cửa hàng Xu'),
        backgroundColor: bg,
        foregroundColor: YumeColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (!designMode && _loading && _inventory == null) {
      return const LoadingView(message: 'Đang tải cửa hàng...');
    }
    if (!designMode && _error != null && _inventory == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final items = designMode ? _designItems : (_inventory?.items ?? []);

    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: designMode ? () async {} : _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(16, widget.embedded ? 10 : 12, 16, 28),
        children: [
          if (!widget.embedded) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: YumeColors.muted),
                label: const Text('Về Play Hub', style: TextStyle(color: YumeColors.muted, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cửa hàng Xu',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: YumeColors.primary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mua vật phẩm (power-up) để dùng trong game — giá và số dư từ server.',
              style: TextStyle(color: YumeColors.muted, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            PlayShopContent.earnXuHint,
            style: TextStyle(
              color: YumeColors.muted.withValues(alpha: 0.95),
              fontSize: widget.embedded ? 11.5 : 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          PlayShopBalanceCard(balance: _xu, formatInt: _formatIntVi),
          const SizedBox(height: 12),
          Text(
            PlayShopContent.useHint,
            style: const TextStyle(color: YumeColors.muted, fontSize: 13, height: 1.4),
          ),
          if (_msgOk != null) ...[
            const SizedBox(height: 10),
            _flash(_msgOk!, ok: true),
          ],
          if (_msgErr != null) ...[
            const SizedBox(height: 10),
            _flash(_msgErr!, ok: false),
          ],
          const SizedBox(height: 16),
          if (items.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Chưa có vật phẩm.', style: TextStyle(color: YumeColors.muted))),
            )
          else
            ...[
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                PlayShopItemCard(
                  item: items[i],
                  xuBalance: _xu,
                  busy: _busyId == items[i].id,
                  formatInt: _formatIntVi,
                  onBuy: designMode ? null : () => _buy(items[i]),
                ),
              ],
            ],
          if (!widget.embedded) ...[
            const SizedBox(height: 20),
            _promoSection(),
            const SizedBox(height: 16),
            const Center(
              child: Text('YumeGo-Ji · Sakura Learning', style: TextStyle(color: YumeColors.muted, fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }

  static const _designItems = [
    PowerUpItem(
      id: 1,
      slug: 'heart',
      name: 'Heart',
      description: 'Thêm 1 tim khi chơi game',
      xuPrice: 20,
      quantityOwned: 10,
    ),
    PowerUpItem(
      id: 2,
      slug: 'fifty-fifty',
      name: '50:50',
      description: 'Loại bỏ 2 đáp án sai',
      xuPrice: 15,
      quantityOwned: 12,
    ),
  ];

  Widget _flash(String text, {required bool ok}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ok ? const Color(0xFF86EFAC) : YumeColors.pinkLight),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: ok ? const Color(0xFF166534) : YumeColors.primaryHover,
        ),
      ),
    );
  }

  Widget _promoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            YumeColors.pinkLight,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YumeColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ƯU ĐÃI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: YumeColors.primary, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                const Text('Gói tăng tốc học tập', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: YumeColors.ink)),
                const SizedBox(height: 6),
                const Text(
                  'Mở Premium để học và chơi thoải mái hơn.',
                  style: TextStyle(fontSize: 13, color: YumeColors.muted, height: 1.4),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const UpgradeScreen()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: YumeColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Xem ngay', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Text('🌸', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }

  String _formatIntVi(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return n < 0 ? '-${buf.toString()}' : buf.toString();
  }
}
