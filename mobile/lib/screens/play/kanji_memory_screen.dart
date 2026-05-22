import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../data/kanji_memory_pairs.dart';
import '../../models/game_item.dart';
import '../../models/game_inventory.dart';
import '../../services/game_service.dart';
import '../../widgets/play/play_setup_inspiration_banner.dart';
import '../../widgets/yume/yume_sakura_background.dart';

/// Kanji Memory — setup (lưới cặp + banner), chơi (sakura, tiến độ, gợi ý), API khi thắng.
class KanjiMemoryScreen extends StatefulWidget {
  const KanjiMemoryScreen({super.key, required this.game});

  final GameItem game;

  @override
  State<KanjiMemoryScreen> createState() => _KanjiMemoryScreenState();
}

enum _KanjiPhase { setup, playing, won }

const _kmAccentRose = Color(0xFFBE123C);
const _kmGradientStart = Color(0xFFBE123C);
const _kmGradientEnd = Color(0xFFE11D48);

class _KanjiMemoryScreenState extends State<KanjiMemoryScreen> {
  final _game = GameService(AppSession.instance.api);
  final _rng = Random();

  _KanjiPhase _phase = _KanjiPhase.setup;
  int _pairTarget = KanjiMemoryPool.defaultPairTarget;
  List<KanjiMemoryPair> _activePairs = [];
  List<_CardData> _cards = [];
  int? _firstIndex;
  int _matched = 0;
  bool _busy = false;
  int _hintsLeft = 1;
  KanjiMemoryResult? _result;

  int get _totalPairs => _activePairs.length;

  List<int> get _pairChoices => KanjiMemoryPool.pairCountChoices();

  double get _progress => _totalPairs == 0 ? 0 : _matched / _totalPairs;

  @override
  void initState() {
    super.initState();
    final choices = _pairChoices;
    if (!choices.contains(_pairTarget)) {
      _pairTarget = choices.isNotEmpty ? choices.last : KanjiMemoryPool.minPairs;
    }
  }

  void _startGame() {
    final max = KanjiMemoryPool.maxSelectablePairs;
    final want = _pairTarget.clamp(KanjiMemoryPool.minPairs, max);
    setState(() {
      _activePairs = KanjiMemoryPool.pickRandom(want, rng: _rng);
      _phase = _KanjiPhase.playing;
      _result = null;
      _hintsLeft = 1;
      _buildDeck();
    });
  }

  void _buildDeck() {
    final deck = <_CardData>[];
    for (var i = 0; i < _activePairs.length; i++) {
      final p = _activePairs[i];
      deck.add(_CardData(pairId: i, label: p.kanji, isKanjiFace: true));
      deck.add(_CardData(pairId: i, label: p.meaning, isKanjiFace: false));
    }
    deck.shuffle(_rng);
    _cards = deck;
    _firstIndex = null;
    _matched = 0;
    _busy = false;
  }

  void _backToSetup() {
    setState(() {
      _phase = _KanjiPhase.setup;
      _result = null;
      _activePairs = [];
      _cards = [];
      _firstIndex = null;
      _matched = 0;
      _busy = false;
      _hintsLeft = 1;
    });
  }

  Future<void> _onWin() async {
    setState(() => _busy = true);
    try {
      final res = await _game.completeKanjiMemory(
        totalPairs: _totalPairs,
        matchedPairs: _totalPairs,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _phase = _KanjiPhase.won;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi ghi nhận: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tap(int index) {
    if (_busy || _phase != _KanjiPhase.playing) return;
    final card = _cards[index];
    if (card.matched || card.faceUp) return;

    setState(() {
      _cards[index] = card.copyWith(faceUp: true);
      if (_firstIndex == null) {
        _firstIndex = index;
        return;
      }
    });

    if (_firstIndex == null || _firstIndex == index) return;

    final firstIdx = _firstIndex!;
    final first = _cards[firstIdx];
    final second = _cards[index];

    if (first.pairId == second.pairId && first.isKanjiFace != second.isKanjiFace) {
      setState(() => _busy = true);
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _cards[firstIdx] = first.copyWith(matched: true, faceUp: true);
          _cards[index] = second.copyWith(matched: true, faceUp: true);
          _firstIndex = null;
          _matched++;
          _busy = false;
        });
        if (_matched >= _totalPairs) _onWin();
      });
    } else {
      setState(() => _busy = true);
      Future<void>.delayed(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        setState(() {
          _cards[firstIdx] = _cards[firstIdx].copyWith(faceUp: false);
          _cards[index] = _cards[index].copyWith(faceUp: false);
          _firstIndex = null;
          _busy = false;
        });
      });
    }
  }

  Future<void> _useHint() async {
    if (_hintsLeft <= 0 || _busy || _phase != _KanjiPhase.playing) return;
    final unmatched = <int>[];
    for (var i = 0; i < _cards.length; i++) {
      if (!_cards[i].matched) unmatched.add(i);
    }
    if (unmatched.length < 2) return;

    final byPair = <int, List<int>>{};
    for (final i in unmatched) {
      byPair.putIfAbsent(_cards[i].pairId, () => []).add(i);
    }
    final pairEntry = byPair.entries.firstWhere((e) => e.value.length >= 2);
    final a = pairEntry.value[0];
    final b = pairEntry.value[1];

    setState(() {
      _hintsLeft--;
      _busy = true;
      _cards[a] = _cards[a].copyWith(faceUp: true);
      _cards[b] = _cards[b].copyWith(faceUp: true);
      _firstIndex = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      if (!_cards[a].matched) _cards[a] = _cards[a].copyWith(faceUp: false);
      if (!_cards[b].matched) _cards[b] = _cards[b].copyWith(faceUp: false);
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(widget.game.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: _phase == _KanjiPhase.playing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _busy ? null : _backToSetup,
              )
            : null,
      ),
      body: switch (_phase) {
        _KanjiPhase.setup => _setupView(),
        _KanjiPhase.playing => _board(),
        _KanjiPhase.won => _summary(),
      },
    );
  }

  Widget _setupView() {
    final choices = _pairChoices;
    final maxPairs = choices.isEmpty ? KanjiMemoryPool.minPairs : choices.last;
    final selected = choices.contains(_pairTarget) ? _pairTarget : maxPairs;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return YumeSakuraBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF9F1239),
                      ),
                      child: const Text('← Trò chơi', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.15),
                        children: [
                          TextSpan(text: 'Kanji ', style: TextStyle(fontWeight: FontWeight.w800)),
                          TextSpan(text: 'Memory', style: TextStyle(color: _kmAccentRose)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SetupCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Lật thẻ và ghép Kanji với nghĩa tiếng Việt từ khóa N5.',
                            style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                          ),
                          SizedBox(height: 10),
                          _SetupFeatureRow(
                            icon: '🎴',
                            title: 'Ghép cặp Kanji — nghĩa',
                            desc: 'Mỗi cặp gồm 2 thẻ; lật đúng hai thẻ cùng cặp để ghi điểm.',
                          ),
                          _SetupFeatureRow(
                            icon: '★',
                            title: 'EXP sau phiên',
                            desc: 'Hoàn thành vòng để ghi nhận phần thưởng lên server.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SetupCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('⚙', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text('Cấu hình lượt chơi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Số cặp (tối đa $maxPairs)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.35,
                            children: choices.map((n) {
                              final active = n == selected;
                              return Material(
                                color: active ? YumeColors.pinkLight.withValues(alpha: 0.65) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => setState(() => _pairTarget = n),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: active ? YumeColors.primary : YumeColors.border,
                                        width: active ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (active) ...[
                                          const Icon(Icons.check_circle, size: 18, color: YumeColors.primary),
                                          const SizedBox(width: 6),
                                        ],
                                        Flexible(
                                          child: Text(
                                            '$n cặp (${n * 2} thẻ)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                                              color: active ? YumeColors.primary : YumeColors.ink,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đang có ${KanjiMemoryPool.all.length} cặp trong bộ từ.',
                      style: const TextStyle(fontSize: 12, color: YumeColors.muted),
                    ),
                    const SizedBox(height: 12),
                    const PlaySetupInspirationBanner(),
                    SizedBox(height: 8 + bottomInset),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 8 + bottomInset),
              child: _StartButton(
                onPressed: choices.length < KanjiMemoryPool.minPairs ? null : _startGame,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    final r = _result;
    return YumeSakuraBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 64, color: YumeColors.primary),
              const SizedBox(height: 16),
              const Text('Hoàn thành!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              if (r != null) ...[
                Text('Điểm: ${r.finalScore}'),
                Text(
                  '+${r.expEarned} EXP · +${r.xuEarned} Xu',
                  style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
              Text('Đã ghép $_totalPairs cặp', style: const TextStyle(color: YumeColors.muted)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Về Play Hub')),
              TextButton(onPressed: _startGame, child: const Text('Chơi lại')),
              TextButton(onPressed: _backToSetup, child: const Text('Đổi số cặp')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _board() {
    final cols = _cards.length <= 12 ? 3 : 4;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return YumeSakuraBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ghép Kanji với nghĩa',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: YumeColors.border.withValues(alpha: 0.5),
                      color: YumeColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_matched/$_totalPairs cặp',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: YumeColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: cols == 4 ? 0.78 : 0.82,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, i) => _MemoryCard(
                  data: _cards[i],
                  onTap: _busy ? null : () => _tap(i),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8 + bottomInset),
              child: OutlinedButton.icon(
                onPressed: _hintsLeft > 0 && !_busy ? _useHint : null,
                icon: const Icon(Icons.lightbulb_outline, size: 20),
                label: Text(_hintsLeft > 0 ? 'Dùng gợi ý ($_hintsLeft)' : 'Đã dùng gợi ý'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YumeColors.primary,
                  side: const BorderSide(color: YumeColors.primary),
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onPressed == null
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : const [_kmGradientStart, _kmGradientEnd],
        ),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: _kmAccentRose.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bắt đầu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                SizedBox(width: 8),
                Text('▶', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.data, required this.onTap});

  final _CardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showFace = data.faceUp || data.matched;
    final picked = data.faceUp && !data.matched;

    Color bg = Colors.white;
    Color border = YumeColors.border;
    if (data.matched) {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFF10B981);
    } else if (picked) {
      bg = YumeColors.pinkLight.withValues(alpha: 0.55);
      border = YumeColors.primary;
    } else if (showFace) {
      bg = Colors.white;
      border = YumeColors.primary;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      elevation: picked ? 3 : 0,
      shadowColor: YumeColors.primary.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: picked || data.matched ? 2 : 1),
          ),
          child: showFace ? _faceContent() : _backContent(),
        ),
      ),
    );
  }

  Widget _backContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_florist_outlined, size: 22, color: YumeColors.primary.withValues(alpha: 0.45)),
        const SizedBox(height: 4),
        Text('?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YumeColors.muted.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _faceContent() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data.isKanjiFace)
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: YumeColors.ink, height: 1.1),
            )
          else ...[
            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155), height: 1.25),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            data.isKanjiFace ? 'Kanji' : 'Nghĩa',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: YumeColors.muted.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SetupFeatureRow extends StatelessWidget {
  const _SetupFeatureRow({required this.icon, required this.title, required this.desc});

  final String icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardData {
  const _CardData({
    required this.pairId,
    required this.label,
    required this.isKanjiFace,
    this.faceUp = false,
    this.matched = false,
  });

  final int pairId;
  final String label;
  final bool isKanjiFace;
  final bool faceUp;
  final bool matched;

  _CardData copyWith({bool? faceUp, bool? matched}) {
    return _CardData(
      pairId: pairId,
      label: label,
      isKanjiFace: isKanjiFace,
      faceUp: faceUp ?? this.faceUp,
      matched: matched ?? this.matched,
    );
  }
}
