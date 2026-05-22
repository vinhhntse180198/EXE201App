import 'dart:async';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../core/session/session_auth_guard.dart';
import '../../models/game_inventory.dart';
import '../../models/game_item.dart';
import '../../models/game_question.dart';
import '../../services/api_client.dart';
import '../../services/game_service.dart';
import '../../utils/json_field.dart';
import '../../widgets/play/kana_combat_effects.dart';
import '../../widgets/play/arcade_answer_button.dart';
import '../../widgets/play/kana_ninja_arena.dart';
import '../../core/catalog/game_catalog.dart';
import '../../data/play_setup_content.dart';
import '../../widgets/play/play_answer_burst.dart';
import '../../widgets/play/play_arcade_grid.dart';
import '../../widgets/play/play_game_setup_view.dart';
import 'play_shop_screen.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({
    super.key,
    required this.game,
    this.sessionMode = 'solo',
    this.pvpRoomCode,
  });

  final GameItem game;
  final String sessionMode;
  final String? pvpRoomCode;

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  final _gameService = GameService(AppSession.instance.api);

  GameSessionStart? _session;
  GameInventory? _inventory;
  int _qIndex = 0;
  int _hearts = 3;
  int _score = 0;
  bool _loading = false;
  String? _error;
  bool _answered = false;
  int? _selected;
  bool? _lastCorrect;
  int? _lastCorrectIdx;
  GameSessionSummary? _summary;
  Set<int> _hiddenOptions = {};
  bool _pendingDouble = false;
  bool _powerUpBusy = false;
  int _secondsLeft = 8;
  int _enemyHp = 100;
  int _kanaCombatScore = 0;
  KanaCombatEffects _combatFx = KanaCombatEffects.idle;
  int _fxGeneration = 0;
  Timer? _countdown;
  int _floatSeq = 0;
  int _questionCount = 10;
  bool _submitInFlight = false;

  String get _slug => widget.game.code.isNotEmpty ? widget.game.code : 'hiragana-match';

  bool get _isKanaGame {
    final s = _slug.toLowerCase();
    return s == 'hiragana-match' || s == 'katakana-match';
  }

  int _qty(String slug) {
    final items = _inventory?.items ?? [];
    for (final i in items) {
      if (i.slug.toLowerCase() == slug.toLowerCase()) return i.quantityOwned;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    if (!designMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSessionAlive());
    }
  }

  Future<void> _ensureSessionAlive() async {
    try {
      final ok = await SessionAuthGuard.validateSession();
      if (!ok && mounted) {
        await SessionAuthGuard.forceReLogin(
          context,
          snackMessage: SessionAuthGuard.sessionExpiredMessage,
        );
      }
    } catch (_) {
      // Mạng/backend — để _start hiển thị lỗi cụ thể.
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _resetCountdown() {
    _countdown?.cancel();
    if (!_isKanaGame || _answered || _session == null) return;
    _secondsLeft = 8;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_answered) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 99));
      if (_secondsLeft <= 0) {
        t.cancel();
        _submit(chosenIndex: null);
      }
    });
  }

  Future<void> _loadInventory() async {
    try {
      final inv = await _gameService.fetchInventory();
      if (mounted) setState(() => _inventory = inv);
    } catch (_) {}
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
      _summary = null;
      _hiddenOptions = {};
      _pendingDouble = false;
    });
    try {
      await _loadInventory();
      final session = await _gameService.startSession(
        gameSlug: _slug,
        questionCount: _questionCount,
        mode: widget.sessionMode,
      );
      if (mounted) {
        final got = session.questions.length;
        if (got < _questionCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Chỉ lấy được $got/${_questionCount} câu. '
                'Chạy SQL patch_sentence_builder_rounds.sql (sp @question_count) và seed 46 ký tự Hiragana.',
              ),
            ),
          );
        }
        setState(() {
          _session = session;
          _hearts = session.maxHearts;
          _qIndex = 0;
          _score = 0;
          _enemyHp = 100;
          _kanaCombatScore = 0;
          _combatFx = KanaCombatEffects.idle;
          _fxGeneration = 0;
          _answered = false;
          _selected = null;
        });
        _resetCountdown();
      }
    } catch (e) {
      if (!mounted) return;
      if (await SessionAuthGuard.handleIfUnauthorized(context, e)) return;
      setState(() => _error = SessionAuthGuard.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _usePowerUp(String slug) async {
    if (_session == null || _powerUpBusy || _answered) return;
    if (_qty(slug) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có vật phẩm trong túi.')));
      return;
    }
    setState(() => _powerUpBusy = true);
    try {
      if (slug == 'skip') {
        await _submit(chosenIndex: null, powerUpUsed: 'skip');
        return;
      }
      if (slug == 'double-points') {
        setState(() => _pendingDouble = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Câu tiếp theo x2 điểm.')));
        return;
      }
      final res = await _gameService.usePowerUp(
        sessionId: _session!.sessionId,
        powerUpSlug: slug,
        questionId: slug == 'fifty-fifty' ? _session!.questions[_qIndex].id : null,
      );
      if (slug == 'fifty-fifty') {
        setState(() => _hiddenOptions = res.hiddenOptionIndices.toSet());
      }
      if (slug == 'heart') {
        setState(() => _hearts = (_hearts + 1).clamp(0, 8));
      }
      await _loadInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _powerUpBusy = false);
    }
  }

  Future<void> _pick(int index) async {
    if (_answered || _session == null || designMode) return;
    if (_hiddenOptions.contains(index)) return;
    _countdown?.cancel();
    await _submit(chosenIndex: index);
  }

  Future<void> _submit({int? chosenIndex, String? powerUpUsed}) async {
    if (_session == null || _submitInFlight) return;
    _submitInFlight = true;
    final q = _session!.questions[_qIndex];
    var power = powerUpUsed;
    if (power == null && _pendingDouble && chosenIndex != null) {
      power = 'double-points';
      _pendingDouble = false;
    }
    setState(() {
      if (chosenIndex != null) _selected = chosenIndex;
      _answered = true;
    });
    try {
      final res = await _gameService.submitAnswer(
        sessionId: _session!.sessionId,
        questionId: q.id,
        questionOrder: _qIndex + 1,
        chosenIndex: chosenIndex,
        powerUpUsed: power,
      );
      final correct = jsonBool(res, 'isCorrect');
      final correctIdx = jsonInt(res, 'correctAnswerIndex');
      if (mounted) {
        setState(() {
          _lastCorrect = correct;
          _lastCorrectIdx = correctIdx;
          _score = jsonInt(res, 'totalScoreSoFar') ?? _score;
          final hearts = jsonInt(res, 'heartsRemaining');
          if (hearts != null) _hearts = hearts;
          if (_isKanaGame && power != 'skip') {
            _applyKanaCombatFx(correct);
          }
        });
        if (!correct && chosenIndex != null && correctIdx != null && mounted) {
          final picked = q.options[chosenIndex];
          final right = correctIdx >= 0 && correctIdx < q.options.length ? q.options[correctIdx] : '?';
          if (picked == right) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Server báo sai nhưng đáp án khớp — kiểm tra correct_index trong DB.')),
            );
          }
        }
      }
      await Future<void>.delayed(Duration(milliseconds: _isKanaGame ? 1650 : 1100));
      if (!mounted) return;
      if (_qIndex + 1 >= _session!.questions.length) {
        await _finish();
      } else {
        setState(() {
          _qIndex++;
          _answered = false;
          _selected = null;
          _lastCorrect = null;
          _lastCorrectIdx = null;
          _hiddenOptions = {};
          _combatFx = KanaCombatEffects.idle;
          _fxGeneration = 0;
        });
        _resetCountdown();
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 401) {
          await SessionAuthGuard.handleIfUnauthorized(context, e);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
          setState(() => _answered = false);
          _resetCountdown();
        }
      }
    } finally {
      _submitInFlight = false;
    }
  }

  void _pushCombatFloat(String text, KanaFloatTone tone) {
    final id = 'f-${_floatSeq++}';
    final list = [..._combatFx.floats, KanaCombatFloat(id: id, text: text, tone: tone)];
    _combatFx = KanaCombatEffects(
      anim: _combatFx.anim,
      slashFx: _combatFx.slashFx,
      orbFx: _combatFx.orbFx,
      screenFlash: _combatFx.screenFlash,
      floats: list,
    );
    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      setState(() {
        _combatFx = KanaCombatEffects(
          anim: _combatFx.anim,
          slashFx: _combatFx.slashFx,
          orbFx: _combatFx.orbFx,
          screenFlash: _combatFx.screenFlash,
          floats: _combatFx.floats.where((x) => x.id != id).toList(),
        );
      });
    });
  }

  String _feedbackLine(GameQuestion q, bool correct) {
    if (correct) return 'Chính xác!';
    final idx = _lastCorrectIdx;
    if (idx != null && idx >= 0 && idx < q.options.length) {
      return 'Chưa đúng — đáp án: ${q.options[idx]} (mất 1 ❤)';
    }
    return 'Chưa đúng — mất 1 ❤';
  }

  void _applyKanaCombatFx(bool correct) {
    _fxGeneration++;
    if (correct) {
      final nh = (_enemyHp - kanaCombatDmg).clamp(0, 100);
      final killed = nh == 0;
      _enemyHp = killed ? 100 : nh;
      _kanaCombatScore = (_kanaCombatScore + 5).clamp(0, kanaCombatWinScore);
      if (killed) _kanaCombatScore = (_kanaCombatScore + kanaCombatKillBonus).clamp(0, kanaCombatWinScore);
      _pushCombatFloat('-$kanaCombatDmg', KanaFloatTone.dmg);
      if (killed) _pushCombatFloat('+$kanaCombatKillBonus', KanaFloatTone.bonus);
      _combatFx = KanaCombatEffects(
        anim: KanaBattleAnim.player,
        slashFx: true,
        screenFlash: KanaScreenFlash.whiteHit,
        floats: _combatFx.floats,
      );
      Future<void>.delayed(const Duration(milliseconds: 620), () {
        if (!mounted) return;
        setState(() {
          _combatFx = KanaCombatEffects(
            anim: KanaBattleAnim.idle,
            floats: _combatFx.floats,
          );
        });
      });
    } else {
      _combatFx = KanaCombatEffects(
        anim: KanaBattleAnim.enemy,
        orbFx: true,
        screenFlash: KanaScreenFlash.redHit,
        floats: _combatFx.floats,
      );
      Future<void>.delayed(const Duration(milliseconds: 580), () {
        if (!mounted) return;
        setState(() {
          _combatFx = KanaCombatEffects(
            anim: KanaBattleAnim.idle,
            floats: _combatFx.floats,
          );
        });
      });
    }
  }

  Future<void> _finish() async {
    _countdown?.cancel();
    if (_session == null) return;
    try {
      final summary = await _gameService.endSession(_session!.sessionId);
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _session != null && _summary == null;
    return Scaffold(
      backgroundColor: playing ? const Color(0xFFF8FAFC) : const Color(0xFFFFFAFB),
      appBar: null,
      body: _summary != null
          ? _summaryView(_summary!)
          : _session == null
              ? _setupView()
              : _arcadePlayView(),
    );
  }

  void _switchKanaSlug(String slug) {
    if (slug == _slug) return;
    GameItem? item;
    for (final g in GameCatalog.defaults) {
      if (g.code == slug) {
        item = g;
        break;
      }
    }
    if (item == null) return;
    final game = item;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GamePlayScreen(game: game)),
    );
  }

  List<int> get _questionChoices =>
      _isKanaGame ? PlaySetupContent.kanaQuestionChoices : PlaySetupContent.defaultQuestionChoices;

  Widget _setupView() {
    return PlayGameSetupView(
      slug: _slug,
      gameName: widget.game.name,
      questionCount: _questionCount,
      questionChoices: _questionChoices,
      onQuestionCountChanged: (n) => setState(() => _questionCount = n),
      onBack: () => Navigator.of(context).pop(),
      onStart: designMode
          ? () {
              setState(() {
                _session = GameSessionStart(
                  sessionId: 0,
                  maxHearts: 3,
                  questions: [
                    GameQuestion(
                      id: 1,
                      questionText: 'あ',
                      options: ['a', 'i', 'u', 'e'],
                    ),
                  ],
                );
              });
              _resetCountdown();
            }
          : _start,
      loading: _loading,
      error: _error,
      activeKanaSlug: _slug,
      onSwitchKana: _isKanaGame ? _switchKanaSlug : null,
      onOpenShop: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PlayShopScreen()),
      ),
    );
  }

  Widget _arcadePlayView() {
    final session = _session!;
    final q = session.questions[_qIndex];
    final maxH = session.maxHearts;
    final total = session.questions.length;
    final displayScore = _isKanaGame ? _kanaCombatScore.clamp(0, kanaCombatWinScore) : _score.clamp(0, 100);
    final progressPct = _isKanaGame
        ? (displayScore / kanaCombatWinScore).clamp(0.0, 1.0)
        : ((_qIndex + 1) / total).clamp(0.0, 1.0);
    // Samurai HP = combat (luôn đầy); mạng ♥ ở header — tránh tưởng bị trúng khi mất tim.
    final playerHpPct = _isKanaGame ? 100 : (maxH > 0 ? ((_hearts / maxH) * 100).round() : 100);
    final kanaChar = q.questionText.trim().isNotEmpty ? q.questionText.trim().characters.first : '？';

    return PlayArcadeGridBackground(
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _arcadeHeader(maxH, displayScore, total),
                  const SizedBox(height: 8),
                  _arcadeProgressBar(progressPct),
                  _arcadeProgressMeta(total),
                  if (_isKanaGame && !_answered) _arcadeTimerHero(),
                  const SizedBox(height: 10),
                  _arcadePowerBar(),
                  if (_isKanaGame) ...[
                    const SizedBox(height: 12),
                    KanaNinjaArena(
                      key: ValueKey('arena-$_fxGeneration'),
                      kanaChar: kanaChar,
                      playerHpPct: playerHpPct,
                      enemyHpPct: _enemyHp,
                      effects: _combatFx,
                      fxGeneration: _fxGeneration,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _isKanaGame ? 'Chọn romaji đúng với ký tự:' : 'Chọn đáp án đúng:',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                  if (!_isKanaGame) ...[
                    const SizedBox(height: 12),
                    _questionCard(q),
                  ],
                  const SizedBox(height: 12),
                  _arcadeOptionsGrid(q),
                  if (_answered && _lastCorrect != null && !_isKanaGame)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        _feedbackLine(q, _lastCorrect!),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _lastCorrect! ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                ],
                  ),
                ),
              ),
            ),
            if (_answered && _lastCorrect != null && !_isKanaGame)
              PlayAnswerBurst(
                key: ValueKey('burst-$_qIndex-$_lastCorrect'),
                correct: _lastCorrect!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _arcadeHeader(int maxH, int displayScore, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              color: const Color(0xFFA78BFA),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (_isKanaGame)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF472B6).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.42)),
                ),
                child: const Text('⚔️ VS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFBE185D))),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.game.name.toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.06, color: Color(0xFF0F172A)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.storefront_outlined, size: 22),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PlayShopScreen()),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                Text(
                  ' $displayScore',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                ),
                const Text('/100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(width: 12),
            ...List.generate(maxH, (i) {
              final on = i < _hearts;
              return Text(on ? '♥' : '♡', style: TextStyle(fontSize: 16, color: on ? const Color(0xFFF87171) : const Color(0xFFF87171).withValues(alpha: 0.25)));
            }),
            const SizedBox(width: 12),
            Text(
              '${_qIndex + 1}/$total',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _arcadeProgressBar(double progressPct) {
    return Container(
      height: _isKanaGame ? 8 : 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
        border: _isKanaGame ? Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.1)) : null,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progressPct,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: _isKanaGame
                  ? [const Color(0xFF22C55E), const Color(0xFFF472B6), const Color(0xFFA78BFA)]
                  : [const Color(0xFF6366F1), const Color(0xFFA78BFA)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _arcadeProgressMeta(int total) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${_qIndex + 1}/$total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(width: 12),
          Text(
            _answered ? '—' : '⏱ ${_secondsLeft}s',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF5B21B6)),
          ),
        ],
      ),
    );
  }

  Widget _arcadeTimerHero() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          children: [
            const TextSpan(text: 'Còn '),
            TextSpan(
              text: '$_secondsLeft',
              style: const TextStyle(color: Color(0xFF6D28D9), fontSize: 20),
            ),
            const TextSpan(text: ' giây'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _arcadePowerBar() {
    final items = [
      ('fifty-fifty', 'assets/images/play/powerup-5050.png'),
      ('heart', 'assets/images/play/powerup-heart.png'),
      ('double-points', 'assets/images/play/powerup-double.png'),
      ('skip', 'assets/images/play/powerup-skip.png'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VẬT PHẨM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.06, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(
            children: items.map((e) {
              final qty = _qty(e.$1);
              final disabled = _powerUpBusy || qty <= 0 || _answered;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Opacity(
                  opacity: disabled ? 0.35 : 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: disabled ? null : () => _usePowerUp(e.$1),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset(e.$2, width: 44, height: 44, errorBuilder: (_, __, ___) => const Icon(Icons.extension, size: 40)),
                          Positioned(
                            right: -4,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(GameQuestion q) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.12)),
      ),
      child: Text(
        q.questionText,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.15),
      ),
    );
  }

  Widget _arcadeOptionsGrid(GameQuestion q) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: q.options.length,
          itemBuilder: (context, i) {
            if (_hiddenOptions.contains(i)) return const SizedBox.shrink();
            final selected = _selected == i;
            final label = GameQuestion.displayLabel(q.options[i]);
            return ArcadeAnswerButton(
              label: label,
              selected: selected,
              answered: _answered,
              correct: selected ? _lastCorrect : null,
              disabled: _answered,
              onTap: () => _pick(i),
            );
          },
        );
      },
    );
  }

  Widget _summaryView(GameSessionSummary s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: YumeColors.primary),
            const SizedBox(height: 16),
            Text(s.result.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Điểm: ${s.finalScore}', style: const TextStyle(fontSize: 18)),
            Text('Đúng ${s.correctCount}/${s.totalQuestions}'),
            Text(
              '+${s.expEarned} EXP · +${s.xuEarned} Xu',
              style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Về Play Hub'),
            ),
          ],
        ),
      ),
    );
  }
}
