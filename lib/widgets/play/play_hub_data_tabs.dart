import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../core/session/session_auth_guard.dart';
import '../../models/game_item.dart';
import '../../models/game_play_meta.dart';
/// Tab Thành tựu — tách widget để lỗi không làm crash cả PlayScreen.
class PlayAchievementsTab extends StatefulWidget {
  const PlayAchievementsTab({super.key});

  @override
  State<PlayAchievementsTab> createState() => _PlayAchievementsTabState();
}

class _PlayAchievementsTabState extends State<PlayAchievementsTab> {
  List<GameAchievement> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!designMode) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppSession.instance.api.get('/api/game/achievements');
      if (!mounted) return;
      setState(() => _items = parseGameAchievementsList(data));
    } catch (e) {
      if (!mounted) return;
      if (await SessionAuthGuard.handleIfUnauthorized(context, e)) return;
      setState(() => _error = SessionAuthGuard.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: YumeColors.primary));
    }
    if (_error != null && _items.isEmpty) {
      return _errorView(_error!, _load);
    }
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }
    final earned = _items.where((a) => a.earned).length;
    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          Text(
            'Đã mở khóa $earned / ${_items.length}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: YumeColors.primary),
          ),
          const SizedBox(height: 10),
          for (final a in _items)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: a.earned ? YumeColors.pinkLight.withValues(alpha: 0.35) : null,
              child: ListTile(
                leading: Icon(
                  a.earned ? Icons.emoji_events : Icons.emoji_events_outlined,
                  color: a.earned ? const Color(0xFFFFB300) : YumeColors.muted,
                ),
                title: Text(a.name, style: TextStyle(fontWeight: a.earned ? FontWeight.w700 : FontWeight.w500)),
                subtitle: Text(
                  [
                    if (a.description != null && a.description!.isNotEmpty) a.description!,
                    if (a.rewardExp > 0 || a.rewardXu > 0) 'Thưởng: +${a.rewardExp} EXP · +${a.rewardXu} Xu',
                    a.earned ? 'Đã đạt' : 'Chưa đạt',
                  ].join('\n'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tab Lịch sử chơi.
class PlayHistoryTab extends StatefulWidget {
  const PlayHistoryTab({super.key});

  @override
  State<PlayHistoryTab> createState() => _PlayHistoryTabState();
}

class _PlayHistoryTabState extends State<PlayHistoryTab> {
  List<GameHistoryEntry> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!designMode) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppSession.instance.api.get(
        '/api/game/history',
        query: {'page': '1', 'pageSize': '20'},
      );
      if (!mounted) return;
      setState(() => _items = parseGameHistoryList(data));
    } catch (e) {
      if (!mounted) return;
      if (await SessionAuthGuard.handleIfUnauthorized(context, e)) return;
      setState(() => _error = SessionAuthGuard.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: YumeColors.primary));
    }
    if (_error != null && _items.isEmpty) {
      return _errorView(_error!, _load);
    }
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }
    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final h = _items[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.history, color: YumeColors.primary),
              title: Text(
                'Điểm ${h.finalScore} · ${h.correctCount}/${h.totalQuestions}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${h.accuracyPercent.toStringAsFixed(0)}% · +${h.expEarned} EXP · +${h.xuEarned} Xu · #${h.sessionId}',
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tab Thử thách hàng ngày.
class PlayDailyTab extends StatefulWidget {
  const PlayDailyTab({super.key, required this.games, required this.onPlayGame});

  final List<GameItem> games;
  final void Function(GameItem game) onPlayGame;

  @override
  State<PlayDailyTab> createState() => _PlayDailyTabState();
}

class _PlayDailyTabState extends State<PlayDailyTab> {
  DailyChallenge? _challenge;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!designMode) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppSession.instance.api.get('/api/game/daily-challenge');
      if (!mounted) return;
      setState(() => _challenge = parseDailyChallenge(data));
    } catch (e) {
      if (!mounted) return;
      if (await SessionAuthGuard.handleIfUnauthorized(context, e)) return;
      setState(() {
        _challenge = null;
        _error = SessionAuthGuard.friendlyMessage(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: YumeColors.primary));
    }
    if (_error != null) {
      return _errorView(_error!, _load);
    }
    final d = _challenge;
    if (d == null) {
      return const SizedBox.shrink();
    }
    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.today, size: 48, color: YumeColors.primary),
          const SizedBox(height: 12),
          Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18), textAlign: TextAlign.center),
          Text('Game: ${d.gameSlug}', style: const TextStyle(color: YumeColors.muted), textAlign: TextAlign.center),
          Text(
            'Thưởng: +${d.bonusExp} EXP · +${d.bonusXu} Xu',
            style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (d.bestScore != null)
            Text('Điểm cao nhất: ${d.bestScore}', style: const TextStyle(color: YumeColors.muted), textAlign: TextAlign.center),
          if (d.completedToday)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('✓ Đã hoàn thành hôm nay', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: () {
                  final match = widget.games.where((g) => g.code.toLowerCase() == d.gameSlug.toLowerCase());
                  if (match.isNotEmpty) {
                    widget.onPlayGame(match.first);
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không tìm thấy game thử thách trong danh sách.')),
                  );
                },
                child: const Text('Chơi thử thách'),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _errorView(String message, VoidCallback onRetry) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
