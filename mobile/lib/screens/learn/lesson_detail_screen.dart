import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/lesson_detail.dart';
import '../../models/lesson_item.dart';
import '../../services/api_client.dart';
import '../../services/learn_service.dart';
import '../../services/lesson_service.dart';
import '../../utils/html_strip.dart';
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

  LessonDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _completing = false;
  bool _completed = false;
  bool _bookmarked = false;
  bool _bookmarkBusy = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.lesson.isCompleted;
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (d.categoryName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: YumeColors.pinkLight, borderRadius: BorderRadius.circular(8)),
            child: Text(d.categoryName!, style: const TextStyle(color: YumeColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 8),
        Text(d.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YumeColors.ink)),
        if (d.estimatedMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('~${d.estimatedMinutes} phút', style: const TextStyle(color: YumeColors.muted, fontSize: 12)),
          ),
        if (d.isPremium)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Chip(label: Text('Premium'), backgroundColor: YumeColors.pinkLight),
          ),
        if (plain.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(plain, style: const TextStyle(height: 1.5, color: YumeColors.text)),
        ],
        if (d.vocabulary.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Từ vựng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...d.vocabulary.map(_vocabCard),
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
        const SizedBox(height: 80),
      ],
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
