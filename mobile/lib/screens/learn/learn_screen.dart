import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../config/yume_decorations.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../models/lesson_item.dart';
import '../../models/progress_summary.dart';
import '../../services/learn_service.dart';
import '../../services/lesson_service.dart';
import '../../utils/jlpt_levels.dart';
import '../../utils/json_field.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/learn/learn_ai_promo.dart';
import '../../widgets/learn/learn_ai_widget.dart';
import '../../widgets/yume/yume_sakura_background.dart';
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
  int? _levelFilter;

  int? get _userLevelId => AppSession.instance.user?.user.levelId;

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
        _lessons.fetchLessons(pageSize: 200),
        _learn.fetchMyProgress(pageSize: 200),
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
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => LessonDetailScreen(lesson: lesson),
          ),
        )
        .then((_) {
      if (!designMode) _load();
    });
  }

  List<LessonItem> _visibleLessons(List<LessonItem> lessons) {
    if (_levelFilter == null) return lessons;
    return lessons.where((l) => l.levelId == _levelFilter).toList();
  }

  Map<int, List<LessonItem>> _groupByLevel(List<LessonItem> lessons) {
    final map = <int, List<LessonItem>>{};
    for (final l in lessons) {
      final lid = l.levelId ?? 1;
      map.putIfAbsent(lid, () => []).add(l);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.title.compareTo(b.title));
    }
    return map;
  }

  LevelCompletion? _levelStats(int levelId, ProgressSummary summary) {
    for (final lv in summary.byLevel) {
      if (lv.levelId == levelId) return lv;
    }
    return null;
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
    final allLessons = designMode
        ? [
            const LessonItem(id: 1, title: 'Bài mẫu N5', slug: 'demo-n5', levelId: 1, categoryType: 'vocabulary'),
            const LessonItem(id: 2, title: 'Bài mẫu N4', slug: 'demo-n4', levelId: 2, isPremium: true, categoryType: 'grammar'),
          ]
        : _lessonList;
    final lessons = _visibleLessons(allLessons);
    final grouped = _groupByLevel(lessons);
    final levelOrder = summary.byLevel.map((l) => l.levelId).where((id) => grouped.containsKey(id)).toList();
    for (final id in grouped.keys) {
      if (!levelOrder.contains(id)) levelOrder.add(id);
    }
    levelOrder.sort();

    final completedCount = allLessons.where((l) => l.isCompleted).length;
    final totalPublished = summary.byLevel.fold<int>(0, (s, l) => s + l.totalPublishedLessons);

    return LearnWithAi(
      child: SizedBox.expand(
        child: YumeSakuraBackground(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: YumeDecorations.dashboardGradient),
            child: SafeArea(
              child: lessons.isEmpty && !designMode
                  ? _buildHeader(summary, allLessons, completedCount, totalPublished)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        ..._buildHeaderChildren(summary, allLessons, completedCount, totalPublished),
                        if (lessons.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('Chưa có bài học cho level này.', style: TextStyle(color: YumeColors.muted)),
                            ),
                          )
                        else
                          for (final levelId in levelOrder) ...[
                            _LevelSectionHeader(
                              levelCode: levelCodeFromId(levelId),
                              stats: _levelStats(levelId, summary),
                              lessonCount: grouped[levelId]!.length,
                              completedInSection: grouped[levelId]!.where((l) => l.isCompleted).length,
                            ),
                            ...grouped[levelId]!.map((l) => _LessonCard(lesson: l, onTap: () => _openLesson(l))),
                            const SizedBox(height: 12),
                          ],
                        const SizedBox(height: 72),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeaderChildren(
    ProgressSummary summary,
    List<LessonItem> allLessons,
    int completedCount,
    int totalPublished,
  ) {
    return [
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
        '${summary.byLevel.length} level · $completedCount/${totalPublished > 0 ? totalPublished : allLessons.length} bài xong',
        style: const TextStyle(color: YumeColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 12),
      ...summary.byLevel.map(
        (lv) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(lv.levelCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (lv.completionPercent / 100).clamp(0, 1),
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
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _LevelChip(
              label: 'Tất cả',
              selected: _levelFilter == null,
              onTap: () => setState(() => _levelFilter = null),
            ),
            ...summary.byLevel.map(
              (lv) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _LevelChip(
                  label: lv.levelCode,
                  selected: _levelFilter == lv.levelId,
                  highlight: lv.levelId == _userLevelId,
                  onTap: () => setState(() => _levelFilter = lv.levelId),
                ),
              ),
            ),
          ],
        ),
      ),
      if (!designMode && _bookmarks.isNotEmpty) ...[
        const SizedBox(height: 16),
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
    ];
  }

  Widget _buildHeader(
    ProgressSummary summary,
    List<LessonItem> allLessons,
    int completedCount,
    int totalPublished,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildHeaderChildren(summary, allLessons, completedCount, totalPublished),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: selected ? Colors.white : YumeColors.ink,
      ),
      selectedColor: YumeColors.primary,
      backgroundColor: highlight ? YumeColors.pinkLight : Colors.white,
      side: BorderSide(color: selected ? YumeColors.primary : YumeColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _LevelSectionHeader extends StatelessWidget {
  const _LevelSectionHeader({
    required this.levelCode,
    required this.stats,
    required this.lessonCount,
    required this.completedInSection,
  });

  final String levelCode;
  final LevelCompletion? stats;
  final int lessonCount;
  final int completedInSection;

  @override
  Widget build(BuildContext context) {
    final total = stats?.totalPublishedLessons ?? lessonCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: YumeDecorations.playHeroGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(levelCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$lessonCount bài · $completedInSection/$total hoàn thành',
              style: const TextStyle(fontSize: 12, color: YumeColors.muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final LessonItem lesson;
  final VoidCallback onTap;

  IconData get _typeIcon {
    switch ((lesson.categoryType ?? '').toLowerCase()) {
      case 'grammar':
        return Icons.spellcheck_rounded;
      case 'kanji':
        return Icons.translate_rounded;
      case 'listening':
        return Icons.hearing_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: lesson.isCompleted ? Colors.green.shade200 : YumeColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lesson.isCompleted ? Colors.green.shade50 : YumeColors.pinkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  lesson.isCompleted ? Icons.check_circle_rounded : _typeIcon,
                  color: lesson.isCompleted ? Colors.green : YumeColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        lesson.levelCode,
                        lesson.categoryLabel,
                        if (lesson.estimatedMinutes > 0) '${lesson.estimatedMinutes} phút',
                        if (lesson.isPremium) 'Premium',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 11, color: YumeColors.muted),
                    ),
                  ],
                ),
              ),
              if (lesson.isCompleted)
                const Text('XONG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green))
              else
                const Icon(Icons.chevron_right_rounded, color: YumeColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
