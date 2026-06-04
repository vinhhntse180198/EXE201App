import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../models/game_item.dart';
import '../../models/leaderboard_entry.dart';
import '../../models/progress_summary.dart';
import '../../services/game_service.dart';
import '../../services/learn_service.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../config/yume_decorations.dart';
import 'game_play_screen.dart';
import 'kanji_memory_screen.dart';
import 'play_pvp_screen.dart';
import 'play_guide_screen.dart';
import 'play_shop_screen.dart';
import '../../widgets/play/play_game_card.dart';
import '../../widgets/play/play_hub_background.dart';
import '../../widgets/play/play_leaderboard_panel.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _game = GameService(AppSession.instance.api);
  final _learn = LearnService(AppSession.instance.api);

  List<GameItem> _games = [];
  List<GameLeaderboardEntry> _leaderboard = [];
  List<ExpLeaderboardEntry> _expLeaderboard = [];
  bool _lbLoading = false;
  String? _lbError;
  ProgressSummary? _summary;
  String _lbPeriod = 'weekly';

  bool _loading = false;
  String? _error;
  String? _gamesError;
  bool _gamesLoading = false;
  bool _gamesFromCatalog = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onMainTabChanged);
    if (!designMode) _loadAll();
  }

  void _onMainTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == 2) {
      _loadLeaderboards();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onMainTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.wait([
      _loadGames(),
      _loadSummary(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadGames() async {
    setState(() {
      _gamesLoading = true;
      _gamesError = null;
    });
    try {
      final result = await _game.fetchGames();
      if (mounted) {
        setState(() {
          _games = result.games;
          _gamesFromCatalog = result.usedCatalogFallback;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _gamesError = e.toString());
    } finally {
      if (mounted) setState(() => _gamesLoading = false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final s = await _learn.fetchProgressSummary();
      if (mounted) setState(() => _summary = s);
    } catch (_) {}
  }

  Future<void> _loadLeaderboards() async {
    if (designMode) return;
    setState(() {
      _lbLoading = true;
      _lbError = null;
    });
    try {
      final gameLb = await _game.fetchLeaderboard(period: _lbPeriod, sortBy: 'score');
      final expLb = await _game.fetchExpLeaderboard(limit: 50);
      if (mounted) {
        setState(() {
          _leaderboard = gameLb;
          _expLeaderboard = expLb;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _lbError = e.toString());
    } finally {
      if (mounted) setState(() => _lbLoading = false);
    }
  }

  void _openGame(GameItem g) {
    final slug = g.code.toLowerCase();
    if (slug == 'kanji-memory') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => KanjiMemoryScreen(game: g)),
      );
      return;
    }
    if (g.isPvp || slug.contains('pvp') || slug == 'flashcard-battle') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlayPvpScreen(gameSlug: g.code)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GamePlayScreen(game: g)),
    );
  }

  void _openShop() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PlayShopScreen()),
    );
  }

  void _openPvp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PlayPvpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!designMode && _loading && _games.isEmpty && _summary == null) {
      return const SizedBox.expand(child: LoadingView(message: 'Đang tải Play Hub...'));
    }
    if (!designMode && _error != null) {
      return SizedBox.expand(child: ErrorView(message: _error!, onRetry: _loadAll));
    }

    final games = designMode ? MockData.games : _games;
    final summary = designMode ? MockData.progressSummary : _summary;

    return PlayHubBackground(
      child: Column(
      children: [
        if (summary != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFECDD3).withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.35)),
                        ),
                        child: const Text(
                          'PLAY HUB',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFBE123C)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ShaderMask(
                        shaderCallback: (bounds) => YumeDecorations.playHeroGradient.createShader(bounds),
                        child: const Text(
                          'Trò chơi & XP',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
                        ),
                      ),
                      Text(
                        'EXP ${summary.exp} · Xu ${summary.xu} · Streak ${summary.streakDays}',
                        style: const TextStyle(color: YumeColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openShop,
                  icon: const Icon(Icons.storefront, color: YumeColors.primary),
                  tooltip: 'Cửa hàng xu',
                ),
                IconButton(
                  onPressed: _openPvp,
                  icon: const Icon(Icons.groups_outlined, color: YumeColors.primary),
                  tooltip: 'PvP',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PlayGuideScreen()),
                  ),
                  icon: const Icon(Icons.help_outline, color: YumeColors.primary),
                  tooltip: 'Hướng dẫn',
                ),
                const Icon(Icons.sports_esports, color: YumeColors.primary, size: 28),
              ],
            ),
          ),
        Material(
          color: Colors.white.withValues(alpha: 0.85),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: YumeColors.primary,
            tabs: [
              Tab(text: 'Game (${games.length})'),
              const Tab(text: 'Cửa hàng'),
              const Tab(text: 'BXH'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _gamesTab(games),
              PlayShopScreen(
                embedded: true,
                onBalanceChanged: _loadSummary,
              ),
              _leaderboardTab(),
            ],
          ),
        ),
      ],
    ),
    );
  }

  /// Hai thẻ một hàng — chiều cao theo nội dung, nút PLAY NOW căn đáy (không overflow / không cắt).
  Widget _gameCardRowsSliver(List<GameItem> games) {
    final rows = <Widget>[];
    for (var i = 0; i < games.length; i += 2) {
      final left = games[i];
      final right = i + 1 < games.length ? games[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < games.length ? 14 : 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PlayGameCard(
                    game: left,
                    fillHeight: true,
                    onPlay: () => _openGame(left),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: right == null
                      ? const SizedBox.shrink()
                      : PlayGameCard(
                          game: right,
                          fillHeight: true,
                          onPlay: () => _openGame(right),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverList(delegate: SliverChildListDelegate(rows));
  }

  Widget _gamesTab(List<GameItem> games) {
    if (_gamesLoading) {
      return const Center(child: LoadingView(message: 'Đang tải danh sách game...'));
    }
    if (_gamesError != null) {
      return ErrorView(
        message: 'Không tải game.\n$_gamesError\n\nAPI: $apiBaseUrl/api/game\nĐảm bảo backend đang chạy.',
        onRetry: _loadGames,
      );
    }

    final banner = _gamesFromCatalog
        ? Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: const Text(
              'API chưa có game trong DB — đang hiển thị danh sách mẫu. '
              'Chạy scripts/seed_games.sql trên YumegojiDB rồi bấm Tải lại.',
              style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF9A3412)),
            ),
          )
        : null;

    return RefreshIndicator(
      onRefresh: _loadGames,
      color: YumeColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Text('🎮', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trò chơi',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${games.length} game · Chọn để luyện tập',
                          style: const TextStyle(fontSize: 12, color: YumeColors.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabs.animateTo(2),
                    child: const Text('BXH →', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          if (banner != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(child: banner),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: _gameCardRowsSliver(games),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardTab() {
    if (!designMode && !_lbLoading && _lbError == null && _leaderboard.isEmpty && _expLeaderboard.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadLeaderboards();
      });
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tuần'),
                  selected: _lbPeriod == 'weekly',
                  onSelected: designMode
                      ? null
                      : (_) {
                          setState(() => _lbPeriod = 'weekly');
                          _loadLeaderboards();
                        },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Tháng'),
                  selected: _lbPeriod == 'monthly',
                  onSelected: designMode
                      ? null
                      : (_) {
                          setState(() => _lbPeriod = 'monthly');
                          _loadLeaderboards();
                        },
                ),
              ],
            ),
          ),
          const TabBar(
            labelColor: YumeColors.primary,
            unselectedLabelColor: YumeColors.muted,
            indicatorColor: YumeColors.primary,
            tabs: [Tab(text: 'Điểm game'), Tab(text: 'EXP tổng')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                PlayLeaderboardList(
                  kind: PlayLeaderboardKind.game,
                  gameRows: _leaderboard,
                  expRows: _expLeaderboard,
                  loading: _lbLoading,
                  error: _lbError,
                  onRefresh: _loadLeaderboards,
                ),
                PlayLeaderboardList(
                  kind: PlayLeaderboardKind.exp,
                  gameRows: _leaderboard,
                  expRows: _expLeaderboard,
                  loading: _lbLoading,
                  error: _lbError,
                  onRefresh: _loadLeaderboards,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
