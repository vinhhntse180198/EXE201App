import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/leaderboard_entry.dart';

/// Danh sách BXH — medal, tên, JLPT, điểm/EXP.
class PlayLeaderboardList extends StatelessWidget {
  const PlayLeaderboardList({
    super.key,
    required this.gameRows,
    required this.expRows,
    required this.kind,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final List<GameLeaderboardEntry> gameRows;
  final List<ExpLeaderboardEntry> expRows;
  final PlayLeaderboardKind kind;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  int? get _myUserId => AppSession.instance.user?.user.id;

  @override
  Widget build(BuildContext context) {
    if (loading && gameRows.isEmpty && expRows.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: YumeColors.primary));
    }
    if (error != null && gameRows.isEmpty && expRows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB91C1C))),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRefresh, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final isExp = kind == PlayLeaderboardKind.exp;
    final rowCount = isExp ? expRows.length : gameRows.length;

    if (rowCount == 0) {
      return RefreshIndicator(
        color: YumeColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 48),
            Icon(Icons.emoji_events_outlined, size: 48, color: YumeColors.muted),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Chưa có dữ liệu BXH.\nChơi game để ghi điểm tuần/tháng, hoặc tích EXP để lên bảng EXP tổng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: YumeColors.muted, height: 1.45, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: rowCount,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (isExp) {
            final r = expRows[index];
            return _LeaderboardTile(
              rank: r.rank > 0 ? r.rank : index + 1,
              name: r.displayName,
              levelCode: r.levelCode,
              scoreLabel: '${_formatInt(r.exp)} XP',
              subtitle: r.levelCode != null ? 'JLPT ${r.levelCode}' : null,
              isMe: _myUserId != null && r.userId == _myUserId,
            );
          }
          final r = gameRows[index];
          return _LeaderboardTile(
            rank: r.rank > 0 ? r.rank : index + 1,
            name: r.displayName,
            levelCode: r.levelCode,
            scoreLabel: '${_formatInt(r.score)} điểm',
            subtitle: '${r.accuracyAvg.toStringAsFixed(1)}% · ${r.gamesPlayed} trận',
            isMe: _myUserId != null && r.userId == _myUserId,
          );
        },
      ),
    );
  }

  String _formatInt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

enum PlayLeaderboardKind { game, exp }

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.scoreLabel,
    this.levelCode,
    this.subtitle,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final String scoreLabel;
  final String? levelCode;
  final String? subtitle;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '$rank';

    return Material(
      color: isMe ? YumeColors.pinkLight.withValues(alpha: 0.65) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe ? YumeColors.primary.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.06),
          ),
          boxShadow: [
            if (!isMe)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                medal,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rank <= 3 ? 22 : 15,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3 ? YumeColors.primary : YumeColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: YumeColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: YumeColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Bạn', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: YumeColors.muted)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              scoreLabel,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: YumeColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
