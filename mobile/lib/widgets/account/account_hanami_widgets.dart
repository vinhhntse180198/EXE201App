import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../utils/account_format.dart';

const _memorySwatches = [
  [Color(0xFFFECDD3), Color(0xFFFDA4AF)],
  [Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
  [Color(0xFFE9D5FF), Color(0xFFC4B5FD)],
  [Color(0xFFFEF3C7), Color(0xFFFCD34D)],
];

class AccountSakuraCard extends StatelessWidget {
  const AccountSakuraCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YumeColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YumeColors.border),
        ),
        child: child,
      ),
    );
  }
}

/// Tiến độ học tập — vòng %, bài đã học, streak, EXP.
class AccountProgressCard extends StatelessWidget {
  const AccountProgressCard({
    super.key,
    required this.levelCode,
    required this.levelCompletionPct,
    required this.progressLoading,
    required this.journeyAgg,
    required this.streakDays,
    required this.accountExp,
  });

  final String levelCode;
  final int levelCompletionPct;
  final bool progressLoading;
  final ({int completed, int total, int pct}) journeyAgg;
  final int streakDays;
  final int accountExp;

  @override
  Widget build(BuildContext context) {
    return AccountSakuraCard(
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _RingPainter(
                    pct: progressLoading ? 0 : levelCompletionPct / 100,
                    color: YumeColors.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      progressLoading ? '…' : '$levelCompletionPct%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: YumeColors.primary,
                      ),
                    ),
                    Text(
                      'Lộ trình $levelCode',
                      style: const TextStyle(
                        fontSize: 11,
                        color: YumeColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progressLoading
                ? 'Đang tải tiến độ…'
                : journeyAgg.total > 0
                ? '${formatIntVi(journeyAgg.completed)} / ${formatIntVi(journeyAgg.total)} bài đã xuất bản'
                : 'Chưa có bài trên lộ trình — vào Học tập để bắt đầu.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: YumeColors.text,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _metaRow('🔥', 'Streak: ${formatIntVi(streakDays)} ngày'),
          const SizedBox(height: 6),
          _metaRow('✨', 'EXP: ${formatIntVi(accountExp)}'),
        ],
      ),
    );
  }

  Widget _metaRow(String icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: YumeColors.text),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Lưới kỷ niệm học tập.
class AccountMemoryLane extends StatelessWidget {
  const AccountMemoryLane({
    super.key,
    required this.memoryCells,
    required this.loadingPosts,
    this.onScrollToFeed,
  });

  final List<MemoryLaneCell> memoryCells;
  final bool loadingPosts;
  final VoidCallback? onScrollToFeed;

  @override
  Widget build(BuildContext context) {
    return AccountSakuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kỷ niệm học tập',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: YumeColors.ink,
                  ),
                ),
              ),
              if (onScrollToFeed != null)
                TextButton(
                  onPressed: onScrollToFeed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (_, i) {
              if (i < memoryCells.length) {
                final c = memoryCells[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(c.imageUrl, fit: BoxFit.cover),
                );
              }
              final sw = _memorySwatches[i];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: sw,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          if (memoryCells.isEmpty && !loadingPosts)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Đăng bài kèm ảnh hoặc thêm ảnh bìa — ảnh sẽ hiện ở đây.',
                style: TextStyle(fontSize: 12, color: YumeColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.pct, required this.color});

  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = const Color(0x140F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      6.28318 * pct,
      false,
      fg,
    );
    final inner = Paint()..color = YumeColors.card;
    canvas.drawCircle(center, radius - 14, inner);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.pct != pct;
}

class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    super.key,
    required this.coverUrl,
    required this.avatarUrl,
    required this.avatarInitial,
    required this.displayName,
    required this.levelTitle,
    required this.isPremium,
    required this.profileTab,
    required this.onTabChanged,
    required this.levelCode,
    required this.levelCompletionPct,
    required this.progressLoading,
    required this.postsCount,
    required this.loadingPosts,
    required this.friendsCount,
    required this.onFriendsTap,
    required this.email,
    required this.username,
    required this.uploadingCover,
    required this.onPickCover,
    required this.onRemoveCover,
    required this.hasCover,
    required this.uploadingAvatar,
    required this.onPickAvatar,
    required this.onEditProfile,
    required this.designMode,
  });

  final String coverUrl;
  final String avatarUrl;
  final String avatarInitial;
  final String displayName;
  final String levelTitle;
  final bool isPremium;
  final String profileTab;
  final ValueChanged<String> onTabChanged;
  final String levelCode;
  final int levelCompletionPct;
  final bool progressLoading;
  final int postsCount;
  final bool loadingPosts;
  final int? friendsCount;
  final VoidCallback onFriendsTap;
  final String email;
  final String username;
  final bool uploadingCover;
  final VoidCallback? onPickCover;
  final VoidCallback? onRemoveCover;
  final bool hasCover;
  final bool uploadingAvatar;
  final VoidCallback? onPickAvatar;
  final VoidCallback? onEditProfile;
  final bool designMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    YumeColors.pinkLight,
                    YumeColors.sakura,
                    YumeColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: coverUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            if (!designMode)
              Positioned(
                right: 12,
                bottom: 12,
                child: Wrap(
                  spacing: 6,
                  children: [
                    _coverBtn(
                      uploadingCover
                          ? 'Đang tải…'
                          : (hasCover ? 'Đổi ảnh bìa' : 'Thêm ảnh bìa'),
                      uploadingCover ? null : onPickCover,
                    ),
                    if (hasCover)
                      _coverBtn('Nền mặc định', onRemoveCover, ghost: true),
                  ],
                ),
              ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPremium
                              ? const Color(0xFFFBBF24)
                              : YumeColors.primary,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: YumeColors.pinkLight,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                avatarInitial,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: YumeColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (isPremium)
                      const Positioned(
                        right: 4,
                        bottom: 4,
                        child: Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFFBBF24),
                          size: 22,
                        ),
                      ),
                  ],
                ),
                if (!designMode)
                  TextButton(
                    onPressed: uploadingAvatar ? null : onPickAvatar,
                    child: Text(
                      uploadingAvatar ? 'Đang tải…' : 'Đổi ảnh đại diện',
                    ),
                  ),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: YumeColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isPremium) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: YumeColors.pinkLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$levelTitle${isPremium ? ' — Gói Premium' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: YumeColors.primary,
                    ),
                  ),
                ),
                if (!designMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Chỉnh sửa',
                      onPressed: onEditProfile,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _tabBtn('Thông tin tài khoản', 'info')),
                    Expanded(child: _tabBtn('Cài đặt', 'settings')),
                  ],
                ),
                const SizedBox(height: 16),
                if (profileTab == 'info') _statsGrid(context),
                if (profileTab == 'settings') _settingsPanel(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabBtn(String label, String id) {
    final active = profileTab == id;
    return Material(
      color: active
          ? YumeColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onTabChanged(id),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? YumeColors.primary : YumeColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.emoji_events_outlined,
            label: 'Cấp độ',
            value: levelCode,
            hint: progressLoading
                ? 'Đang tải…'
                : '$levelCompletionPct% tiến độ',
            progress: levelCompletionPct / 100,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            icon: Icons.article_outlined,
            label: 'Bài viết',
            value: loadingPosts ? '…' : '$postsCount',
            hint: 'Bài đăng của bạn',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onFriendsTap,
            borderRadius: BorderRadius.circular(14),
            child: _statCard(
              icon: Icons.people_outline,
              label: 'Bạn bè',
              value: friendsCount == null ? '…' : '$friendsCount',
              hint: 'Danh sách kết bạn',
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String hint,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: YumeColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YumeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: YumeColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: YumeColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: YumeColors.ink,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: YumeColors.pinkLight,
                color: YumeColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(fontSize: 10, color: YumeColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _settingsPanel() {
    return Material(
      color: YumeColors.card,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: YumeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đăng nhập',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _dlRow('Email', email.isEmpty ? '—' : email),
            _dlRow('Tên đăng nhập', username.isEmpty ? '—' : username),
            _dlRow('Cấp độ JLPT', levelCode),
          ],
        ),
      ),
    );
  }

  Widget _dlRow(String dt, String dd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dt,
            style: const TextStyle(
              fontSize: 11,
              color: YumeColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dd,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: YumeColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverBtn(String label, VoidCallback? onTap, {bool ghost = false}) {
    return Material(
      color: ghost ? Colors.white24 : Colors.black45,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
