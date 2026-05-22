import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../models/lesson_item.dart';
import '../../models/progress_summary.dart';
import '../../services/learn_service.dart';
import '../../services/lesson_service.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/learn/learn_ai_promo.dart';
import '../../widgets/learn/learn_ai_widget.dart';
import '../../utils/json_field.dart';
import '../../widgets/yume/yume_scaffold_body.dart';
import 'lesson_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _learn = LearnService(AppSession.instance.api);
  final _lessons = LessonService(AppSession.instance.api);

  ProgressSummary? _summary;
  List<LessonItem> _lessonList = [];
  List<dynamic> _bookmarks = [];
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
      final results = await Future.wait([
        _learn.fetchProgressSummary(),
        _lessons.fetchLessons(pageSize: 100),
        _learn.fetchMyProgress(pageSize: 100),
        _learn.fetchBookmarks(pageSize: 50),
      ]);
      final completed = _learn.completedLessonIds(results[2] as List<dynamic>);
      final lessons = (results[1] as List<LessonItem>)
          .map((l) => l.copyWith(isCompleted: completed.contains(l.id)))
          .toList();
      if (mounted) {
        setState(() {
          _summary = results[0] as ProgressSummary;
          _lessonList = lessons;
          _bookmarks = results[3] as List<dynamic>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openLesson(LessonItem lesson) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonDetailScreen(lesson: lesson),
      ),
    ).then((_) {
      if (!designMode) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!designMode && _loading) {
      return const SizedBox.expand(child: LoadingView(message: 'Đang tải bài học...'));
    }
    if (!designMode && _error != null) {
      return SizedBox.expand(child: ErrorView(message: _error!, onRetry: _load));
    }

    final summary = designMode
        ? MockData.progressSummary
        : (_summary ?? const ProgressSummary(exp: 0, xu: 0, streakDays: 0, byLevel: []));
    final lessons = designMode
        ? [
            const LessonItem(id: 1, title: 'Bài mẫu N5', slug: 'demo-n5', categoryName: 'Từ vựng'),
            const LessonItem(id: 2, title: 'Bài mẫu N4', slug: 'demo-n4', isPremium: true),
          ]
        : _lessonList;

    final completedCount = lessons.where((l) => l.isCompleted).length;

    return LearnWithAi(
      child: YumeScaffoldBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LearnAiPromoBanner(),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFECDD3).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.35)),
              ),
              child: const Text(
                'HỌC TẬP',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFBE123C)),
              ),
            ),
            const Text('Khóa học JLPT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YumeColors.ink)),
          const SizedBox(height: 4),
          Text(
            '${summary.byLevel.length} level · $completedCount/${lessons.length} bài xong',
            style: const TextStyle(color: YumeColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...summary.byLevel.map(
            (lv) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text('${lv.levelCode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: lv.completionPercent / 100,
                        minHeight: 6,
                        backgroundColor: YumeColors.pinkLight,
                        color: YumeColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${lv.completionPercent.toInt()}%', style: const TextStyle(fontSize: 11, color: YumeColors.muted)),
                ],
              ),
            ),
          ),
          if (!designMode && _bookmarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Đã lưu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._bookmarks.map((b) {
              if (b is! Map<String, dynamic>) return const SizedBox.shrink();
              final title = jsonStr(b, 'title') ?? jsonStr(b, 'lessonTitle') ?? 'Bài học';
              final slug = jsonStr(b, 'slug') ?? jsonStr(b, 'lessonSlug');
              final id = jsonInt(b, 'lessonId') ?? jsonInt(b, 'id') ?? 0;
              return ListTile(
                dense: true,
                leading: const Icon(Icons.bookmark, color: YumeColors.primary, size: 20),
                title: Text(title, style: const TextStyle(fontSize: 13)),
                onTap: () {
                  if (slug != null) {
                    _openLesson(LessonItem(id: id, title: title, slug: slug));
                  }
                },
              );
            }),
          ],
          const SizedBox(height: 16),
          if (lessons.isEmpty)
            const Text('Chưa có bài học trên server.')
          else
            ...lessons.map((l) => _lessonCard(l)),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  Widget _lessonCard(LessonItem l) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openLesson(l),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: l.isCompleted ? Colors.green.shade50 : YumeColors.pinkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  l.isCompleted ? Icons.check_circle : Icons.menu_book_rounded,
                  color: l.isCompleted ? Colors.green : YumeColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      [l.categoryName, l.estimatedMinutes > 0 ? '${l.estimatedMinutes} phút' : null, l.isPremium ? 'Premium' : null]
                          .whereType<String>()
                          .join(' · '),
                      style: const TextStyle(fontSize: 11, color: YumeColors.muted),
                    ),
                  ],
                ),
              ),
              if (l.isCompleted)
                const Text('XONG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green))
              else
                const Icon(Icons.chevron_right, color: YumeColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
