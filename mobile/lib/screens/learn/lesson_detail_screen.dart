import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/lesson_detail.dart';
import '../../models/lesson_item.dart';
import '../../services/api_client.dart';
import '../../services/learn_service.dart';
import '../../services/lesson_service.dart';
import '../../utils/html_strip.dart';
import '../../utils/lesson_content_parser.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/learn/learn_ai_widget.dart';
import '../upgrade/upgrade_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lesson});

  final LessonItem lesson;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _lessons = LessonService(AppSession.instance.api);
  final _learn = LearnService(AppSession.instance.api);
  final _tts = FlutterTts();

  LessonDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _completing = false;
  bool _completed = false;
  bool _bookmarked = false;
  bool _bookmarkBusy = false;
  int? _selectedVocabId;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.lesson.isCompleted;
    _initTts();
    if (designMode) {
      _detail = LessonDetail(
        id: widget.lesson.id,
        title: widget.lesson.title,
        slug: widget.lesson.slug ?? 'demo',
        categoryName: widget.lesson.categoryName ?? 'Từ vựng',
        content: '<p>Nội dung mẫu (design mode).</p>',
        vocabulary: const [
          VocabularyItem(id: 1, wordJp: 'こんにちは', reading: 'konnichiwa', meaningVi: 'Xin chào'),
        ],
      );
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      if (mounted) setState(() => _ttsReady = true);
    } catch (_) {
      if (mounted) setState(() => _ttsReady = false);
    }
  }

  Future<void> _speakJa(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(t);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final slug = widget.lesson.slug;
      final detail = slug != null && slug.isNotEmpty
          ? await _lessons.fetchBySlug(slug)
          : await _lessons.fetchById(widget.lesson.id);
      if (mounted) setState(() => _detail = detail);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        if (e.statusCode == 403) _error = 'Bài Premium — cần nâng cấp gói.';
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _bookmarkBusy = true);
    try {
      if (_bookmarked) {
        await _lessons.removeBookmark(widget.lesson.id);
      } else {
        await _lessons.addBookmark(widget.lesson.id);
      }
      if (mounted) setState(() => _bookmarked = !_bookmarked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _markComplete() async {
    if (designMode || _detail == null) return;
    setState(() => _completing = true);
    try {
      await _learn.markLessonComplete(_detail!.id);
      if (mounted) {
        setState(() => _completed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hoàn thành bài học!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YumeColors.surface,
      appBar: AppBar(
        title: Text(widget.lesson.title, style: const TextStyle(fontSize: 16)),
        actions: [
          if (!designMode)
            IconButton(
              icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _bookmarkBusy ? null : _toggleBookmark,
            ),
        ],
      ),
      body: LearnWithAi(
        fabBottomOffset: 88,
        child: _loading
            ? const LoadingView(message: 'Đang tải bài học...')
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ErrorView(message: _error!, onRetry: _load),
                        if (_error!.contains('Premium'))
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const UpgradeScreen()),
                            ),
                            child: const Text('Nâng cấp Premium'),
                          ),
                      ],
                    ),
                  )
                : _buildBody(_detail!),
      ),
      bottomNavigationBar: _detail != null && !designMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _completed || _completing ? null : _markComplete,
                  child: _completing
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_completed ? 'Đã hoàn thành' : 'Hoàn thành bài học'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(LessonDetail d) {
    final plain = stripHtml(d.content);
    final isHiragana = _isHiraganaLesson(d, plain);
    final apiVocab = d.vocabulary;
    final parsedVocab = apiVocab.isEmpty ? parseVocabularyFromHtml(d.content) : const <VocabularyItem>[];
    final vocab = apiVocab.isNotEmpty ? apiVocab : parsedVocab;
    final shouldUseVocabGrid = _shouldUseFlashcardGrid(vocab);
    final rawParagraphs = isHiragana || shouldUseVocabGrid
        ? const <String>[]
        : contentParagraphsExcludingParsedVocab(d.content, parsedVocab);
    final contentParagraphs = meaningfulParagraphs(rawParagraphs);
    final hasStructuredContent = vocab.isNotEmpty || d.kanji.isNotEmpty || d.grammar.isNotEmpty;
    final isPlaceholder = isPlaceholderLessonContent(
      d.content,
      vocabCount: vocab.length,
      kanjiCount: d.kanji.length,
      grammarCount: d.grammar.length,
    );
    final hasReadableContent = !isPlaceholder && (contentParagraphs.isNotEmpty || hasStructuredContent);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isHiragana)
          _hiraganaHeaderCard(d)
        else ...[
          if (d.categoryName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: YumeColors.pinkLight, borderRadius: BorderRadius.circular(8)),
              child: Text(d.categoryName!, style: const TextStyle(color: YumeColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 8),
          Text(d.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YumeColors.ink)),
          // NOTE: Không hiển thị thời gian cho mẫu Hiragana theo yêu cầu.
          if (!isHiragana && d.estimatedMinutes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('~${d.estimatedMinutes} phút', style: const TextStyle(color: YumeColors.muted, fontSize: 12)),
            ),
        ],
        if (d.isPremium)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Chip(label: Text('Premium'), backgroundColor: YumeColors.pinkLight),
          ),
        if (isHiragana) ...[
          const SizedBox(height: 14),
          _hiraganaCardList(plain, html: d.content),
        ],
        if (!isHiragana && !shouldUseVocabGrid && contentParagraphs.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...contentParagraphs.map(_renderContentBlock),
        ] else if (!isHiragana && !shouldUseVocabGrid && plain.isNotEmpty && !isPlaceholder) ...[
          const SizedBox(height: 16),
          ...extractParagraphsFromHtml(d.content).map(_renderContentBlock),
        ],
        if (vocab.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('Từ vựng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              if (shouldUseVocabGrid)
                Text(
                  '${vocab.length}',
                  style: const TextStyle(color: YumeColors.muted, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (shouldUseVocabGrid)
            _vocabGrid(vocab)
          else
            ...vocab.map(_vocabCard),
        ],
        if (d.kanji.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Kanji', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...d.kanji.map(_kanjiCard),
        ],
        if (d.grammar.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Ngữ pháp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...d.grammar.map(_grammarCard),
        ],
        if (!hasReadableContent && !isHiragana) _emptyLessonHint(isPlaceholder: isPlaceholder),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _emptyLessonHint({required bool isPlaceholder}) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: YumeColors.pinkLight.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: YumeColors.primary.withValues(alpha: 0.9), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPlaceholder ? 'Bài học chưa có nội dung' : 'Chưa có nội dung bài học',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: YumeColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isPlaceholder
                  ? 'Bài này chỉ có marker slide (--- Slide 1 ---) trên server, chưa được moderator nhập nội dung, từ vựng hoặc kanji.\n\nHãy thử bài khác như "Chào hỏi cơ bản", "Số đếm 1-10" hoặc "Kanji cơ bản 1".'
                  : (designMode
                      ? 'Bài học này chưa có nội dung trên máy chủ.'
                      : 'Moderator cần bổ sung nội dung hoặc từ vựng cho bài này trên web.'),
              style: TextStyle(color: YumeColors.muted.withValues(alpha: 0.95), height: 1.45, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderContentBlock(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(trimmed);
    if (heading != null) {
      final level = heading.group(1)!.length;
      final body = heading.group(2)!;
      final size = level == 1 ? 20.0 : level == 2 ? 17.0 : 15.0;
      return Padding(
        padding: EdgeInsets.only(top: level == 1 ? 4 : 10, bottom: 6),
        child: Text(
          body,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: YumeColors.ink, height: 1.25),
        ),
      );
    }

    if (trimmed.startsWith('> ')) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            trimmed.substring(2),
            style: const TextStyle(fontStyle: FontStyle.italic, height: 1.45, color: YumeColors.text),
          ),
        ),
      );
    }

    if (trimmed.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: YumeColors.primary, fontWeight: FontWeight.w900)),
            Expanded(child: Text(trimmed.substring(2), style: const TextStyle(height: 1.4, color: YumeColors.text))),
          ],
        ),
      );
    }

    return _contentParagraphCard(trimmed);
  }

  Widget _contentParagraphCard(String text) {
    final isMarker = text.startsWith('---') && text.contains('Slide');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      color: isMarker ? YumeColors.pinkLight.withValues(alpha: 0.35) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            height: 1.45,
            color: YumeColors.text,
            fontWeight: isMarker ? FontWeight.w800 : FontWeight.w500,
            fontSize: isMarker ? 13 : 15,
          ),
        ),
      ),
    );
  }

  bool _isHiraganaLesson(LessonDetail d, String plain) {
    final title = d.title.trim().toLowerCase();
    final slug = d.slug.trim().toLowerCase();
    final cat = (d.categoryName ?? '').trim().toLowerCase();

    // Strict matching to avoid mis-classifying grammar/kanji lessons.
    if (title.contains('hiragana')) return true;
    if (slug.contains('hiragana')) return true;
    if (cat.contains('hiragana')) return true;
    return false;
  }

  Widget _hiraganaHeaderCard(LessonDetail d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFDCEFFD),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.categoryName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: YumeColors.pink, borderRadius: BorderRadius.circular(999)),
              child: Text(
                d.categoryName!,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            d.title.toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: YumeColors.primary),
          ),
        ],
      ),
    );
  }

  List<_KanaRow> _parseKanaRows(String plain) {
    // Extract kana tokens anywhere in content (not only line-by-line), so lessons
    // like "Bảng chữ hiragana" won't show missing data.
    final matches = RegExp(r'[\u3040-\u309F]{1,3}').allMatches(plain);
    final tokens = <String>[];
    for (final m in matches) {
      final t = m.group(0);
      if (t == null) continue;
      // Skip lone long mark / punctuation-ish chars.
      if (t.trim().isEmpty || t == 'ー') continue;
      tokens.add(t);
    }

    // Keep order, remove immediate duplicates.
    final compact = <String>[];
    for (final t in tokens) {
      if (compact.isEmpty || compact.last != t) compact.add(t);
    }

    return compact.map((k) => _KanaRow(kana: k, romaji: _kanaToRomaji(k))).toList(growable: false);
  }

  String _kanaToRomaji(String kana) {
    // Minimal Hepburn mapping (enough for hiragana lessons). Unknowns become ''.
    const base = <String, String>{
      'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
      'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
      'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
      'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
      'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
      'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
      'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
      'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
      'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
      'わ': 'wa', 'を': 'wo', 'ん': 'n',
      'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
      'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
      'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
      'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
      'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
      'ぁ': 'a', 'ぃ': 'i', 'ぅ': 'u', 'ぇ': 'e', 'ぉ': 'o',
      'ゃ': 'ya', 'ゅ': 'yu', 'ょ': 'yo',
    };

    const digraph = <String, String>{
      'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo',
      'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
      'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
      'じゃ': 'ja', 'じゅ': 'ju', 'じょ': 'jo',
      'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
      'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
      'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
      'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
      'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
      'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
      'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
    };

    String out = '';
    for (var i = 0; i < kana.length; i++) {
      final ch = kana[i];

      // small tsu: consonant gemination
      if (ch == 'っ' && i + 1 < kana.length) {
        // Need at least 2 chars after current index to take 2-char digraph.
        final next2 = (i + 2 < kana.length) ? kana.substring(i + 1, i + 3) : null;
        final next1 = kana.substring(i + 1, i + 2);
        final nextRoma = (next2 != null && digraph.containsKey(next2))
            ? digraph[next2]!
            : (base[next1] ?? '');
        if (nextRoma.isNotEmpty) out += nextRoma[0];
        continue;
      }

      // digraph (e.g., きゃ)
      if (i + 1 < kana.length) {
        final two = kana.substring(i, i + 2);
        final d = digraph[two];
        if (d != null) {
          out += d;
          i++;
          continue;
        }
      }

      out += base[ch] ?? '';
    }

    // Long vowel mark isn't typical in hiragana lessons, but handle anyway.
    out = out.replaceAll('ー', '');
    return out;
  }

  String _kanaGroup(String romaji) {
    const vowels = {'a', 'i', 'u', 'e', 'o'};
    if (vowels.contains(romaji)) return 'Nguyên âm';
    return '';
  }

  Widget _hiraganaCardList(String plain, {String? html}) {
    final rows = _parseKanaRows(plain);
    if (rows.isEmpty) {
      final fallback = extractParagraphsFromHtml(html);
      if (fallback.isNotEmpty) {
        return Column(children: fallback.map(_contentParagraphCard).toList());
      }
      if (plain.trim().isNotEmpty) {
        return _contentParagraphCard(plain);
      }
      return const Text('Chưa có dữ liệu Hiragana.', style: TextStyle(color: YumeColors.muted));
    }

    const palette = [
      Color(0xFFFDE68A), // amber
      Color(0xFFBFDBFE), // blue
      Color(0xFFBBF7D0), // green
      Color(0xFFFBCFE8), // pink
      Color(0xFFFED7AA), // orange
      Color(0xFFE9D5FF), // purple
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _hiraganaRowCard(rows[i], palette[i % palette.length]),
      ],
    );
  }

  Widget _hiraganaRowCard(_KanaRow row, Color accent) {
    final group = _kanaGroup(row.romaji);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.7)),
              ),
              alignment: Alignment.center,
              child: Text(
                row.kana,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: YumeColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.romaji.isEmpty ? '—' : row.romaji,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  if (group.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(group, style: const TextStyle(color: YumeColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_ttsReady)
                  IconButton(
                    tooltip: 'Nghe',
                    onPressed: () => _speakJa(row.kana),
                    icon: const Icon(Icons.volume_up_rounded, color: YumeColors.primary),
                  ),
                Text(
                  row.romaji.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldUseFlashcardGrid(List<VocabularyItem> vocabulary) {
    // Heuristic: flashcard grid works best for short vocab sets like numbers/colors/basic words.
    if (vocabulary.length < 4 || vocabulary.length > 40) return false;
    int ok = 0;
    for (final v in vocabulary) {
      final jp = v.wordJp.trim();
      final rd = (v.reading ?? '').trim();
      final vi = (v.meaningVi ?? '').trim();
      if (jp.isEmpty) continue;
      if (jp.length <= 6 && rd.length <= 14 && vi.length <= 18 && (v.exampleSentence ?? '').trim().isEmpty) ok++;
    }
    return ok >= (vocabulary.length * 0.7);
  }

  Widget _vocabGrid(List<VocabularyItem> items) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 560 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Match sample: tall cards with big kana.
        childAspectRatio: cols == 3 ? 0.98 : 0.92,
      ),
      itemBuilder: (_, i) => _vocabFlashcard(items[i]),
    );
  }

  Widget _vocabFlashcard(VocabularyItem v) {
    final selected = _selectedVocabId == v.id;
    final jp = v.wordJp.trim();
    final reading = (v.reading ?? '').trim();
    final meaning = (v.meaningVi ?? '').trim();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _selectedVocabId = selected ? null : v.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? YumeColors.primary : Colors.black.withValues(alpha: 0.10),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              jp,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 42,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: YumeColors.ink,
              ),
            ),
            if (reading.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                reading,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: YumeColors.muted, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                meaning.isEmpty ? '—' : meaning,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vocabCard(VocabularyItem v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(v.wordJp, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        subtitle: Text([v.reading, v.meaningVi, v.exampleSentence].whereType<String>().where((s) => s.isNotEmpty).join('\n')),
      ),
    );
  }

  Widget _kanjiCard(KanjiItem k) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(k.character, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        title: Text(k.meaningVi ?? ''),
        subtitle: Text([k.readingsOn, k.readingsKun].whereType<String>().join(' · ')),
      ),
    );
  }

  Widget _grammarCard(GrammarItem g) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.pattern, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (g.structure != null) Text(g.structure!, style: const TextStyle(color: YumeColors.muted)),
            if (g.meaningVi != null) Text(g.meaningVi!),
            if (g.exampleSentences != null) Text(g.exampleSentences!, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _KanaRow {
  const _KanaRow({required this.kana, required this.romaji});

  final String kana;
  final String romaji;
}
