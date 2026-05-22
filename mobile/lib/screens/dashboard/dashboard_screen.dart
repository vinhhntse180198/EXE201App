import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../models/progress_summary.dart';
import '../../models/user.dart';
import '../../services/learn_service.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../utils/jlpt_levels.dart';
import '../assessment/level_up_test_screen.dart';
import '../assessment/placement_test_screen.dart';
import '../../widgets/yume/rank_progress_card.dart';
import '../../widgets/yume/yume_scaffold_body.dart';
import '../../widgets/yume/yume_sakura_background.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _learn = LearnService(AppSession.instance.api);

  ProgressSummary? _summary;
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
      final summary = await _learn.fetchProgressSummary();
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!designMode && _loading) {
      return const SizedBox.expand(child: LoadingView(message: 'Dashboard...'));
    }
    if (!designMode && _error != null) {
      return SizedBox.expand(child: ErrorView(message: _error!, onRetry: _load));
    }

    final user = designMode
        ? MockData.user
        : (AppSession.instance.user?.user ?? const User(id: 0, username: '—', email: '', role: 'Learner'));
    final s = designMode
        ? MockData.progressSummary
        : (_summary ?? const ProgressSummary(exp: 0, xu: 0, streakDays: 0, byLevel: []));

    return YumeScaffoldBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFECDD3).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.35)),
            ),
            child: const Text(
              'TỔNG QUAN HỌC TẬP',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFFBE123C)),
            ),
          ),
          _profileCard(user),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statChip('EXP', '${s.exp}')),
              const SizedBox(width: 8),
              Expanded(child: _statChip('Xu', '${s.xu}')),
              const SizedBox(width: 8),
              Expanded(child: _statChip('Streak', '${s.streakDays} ngày')),
            ],
          ),
          const SizedBox(height: 16),
          RankProgressCard(exp: s.exp),
          const SizedBox(height: 24),
          if (AppSession.instance.user?.needsPlacementTest == true)
            Card(
              color: YumeColors.pinkLight,
              child: ListTile(
                title: const Text('Chưa làm Placement Test'),
                subtitle: const Text('Kiểm tra trình độ để mở khóa học phù hợp'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PlacementTestScreen()),
                ),
              ),
            ),
          if (nextLevelCode(user.levelId) != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: YumeColors.primary),
                title: Text('Thi lên ${nextLevelCode(user.levelId)}'),
                subtitle: Text('Level hiện tại: ${levelCodeFromId(user.levelId)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final next = nextLevelCode(user.levelId)!;
                  Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => LevelUpTestScreen(toLevel: next),
                    ),
                  ).then((passed) {
                    if (passed == true) _load();
                  });
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Tiến độ theo level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: YumeColors.ink)),
          const SizedBox(height: 12),
          ...s.byLevel.map(_levelCard),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: YumeColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: YumeColors.border)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: YumeColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: YumeColors.primary)),
        ],
      ),
    );
  }

  Widget _profileCard(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [YumeColors.pink, YumeColors.pinkDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                const SizedBox(height: 6),
                Text('${user.role} · Level ${user.levelId ?? "-"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCard(LevelCompletion lv) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: YumeGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _levelCardInner(lv),
          ],
        ),
      ),
    );
  }

  Widget _levelCardInner(LevelCompletion lv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${lv.levelCode} — ${lv.levelName}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${lv.completionPercent.toInt()}%', style: const TextStyle(color: YumeColors.pink, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: lv.completionPercent / 100,
            minHeight: 8,
            backgroundColor: YumeColors.pinkLight,
            color: YumeColors.pink,
          ),
        ),
        const SizedBox(height: 6),
        Text('${lv.completedLessons}/${lv.totalPublishedLessons} bài', style: const TextStyle(fontSize: 12, color: YumeColors.muted)),
      ],
    );
  }
}
