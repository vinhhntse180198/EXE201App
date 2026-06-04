import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../core/session/app_session.dart';
import '../../models/auth_response.dart';
import '../../services/assessment_service.dart';
import '../../utils/jlpt_levels.dart';
import '../../utils/post_login_nav.dart';
import '../../widgets/assessment/exam_intro_panel.dart';
import '../../widgets/assessment/exam_result_panel.dart';
import '../../widgets/assessment/exam_runner.dart';
import '../../widgets/assessment/exam_shell.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

/// Bài kiểm tra đầu vào 40 câu — khớp web `/placement-test`.
class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  final _svc = AssessmentService(AppSession.instance.api);

  bool _loading = true;
  String? _error;
  dynamic _test;
  dynamic _result;
  bool _started = false;

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
      final t = await _svc.fetchPlacementTest();
      if (mounted) setState(() => _test = t);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit(Map<int, String> answers) async {
    try {
      final r = await _svc.submitPlacement(answers);
      await AppSession.instance.auth.setNeedsPlacementTest(false);
      final session = AppSession.instance.user;
      if (session != null) {
        final newLevelId = levelIdFromCode(r.levelLabel) ?? session.user.levelId;
        final updated = session.user.copyWith(levelId: newLevelId);
        AppSession.instance.applyAuth(AuthResponse(
          accessToken: session.accessToken,
          user: updated,
          needsPlacementTest: false,
        ));
        await AppSession.instance.auth.updateCachedUser(updated, needsPlacementTest: false);
      }
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _goApp() {
    final session = AppSession.instance.user;
    if (session == null) return;
    navigatePostLogin(context, session.copyWith(needsPlacementTest: false));
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      final r = _result;
      return ExamResultPanel(
        title: 'Kết quả Placement',
        headline: 'Trình độ: ${r.levelLabel}',
        subtitle: 'Dựa trên kết quả bài kiểm tra đầu vào của bạn.',
        badgeLabel: 'JLPT ${r.levelLabel}',
        score: r.correctCount,
        maxScore: r.totalCount,
        detailLines: [
          'Hoàn thành bài placement test.',
          'Level ${r.levelLabel} sẽ được dùng để gợi ý lộ trình học.',
        ],
        primaryLabel: 'Vào ứng dụng',
        onPrimary: _goApp,
        onBack: _goApp,
      );
    }

    if (_loading) {
      return const ExamShell(body: LoadingView(message: 'Đang tải bài test...'));
    }
    if (_error != null) {
      return ExamShell(
        appBar: examAppBar(title: 'Placement Test', onBack: () => Navigator.of(context).maybePop()),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final t = _test!;
    if (!_started) {
      return ExamIntroPanel(
        title: 'Bài kiểm tra đầu vào',
        subtitle: '${t.totalQuestions} câu · ${t.timeLimitSeconds ~/ 60} phút',
        badgeLabel: 'Placement Test',
        description: 'Làm bài trắc nghiệm để hệ thống gợi ý level JLPT phù hợp (N5 → N3).',
        rules: const [
          'Thời gian làm bài: 20 phút. Hết giờ sẽ tự nộp bài.',
          '≤ 15 câu đúng → N5 · 16–30 câu → N4 · ≥ 31 câu → N3.',
          'Chọn đáp án trước khi chuyển câu hoặc nộp bài.',
          'Có thể lưu tạm và tiếp tục sau.',
        ],
        onBack: () => Navigator.of(context).maybePop(),
        onStart: () => setState(() => _started = true),
      );
    }

    return ExamRunner(
      title: 'Placement Test',
      subtitle: '${t.totalQuestions} câu · ${t.timeLimitSeconds ~/ 60} phút',
      questions: t.questions,
      timeLimitSeconds: t.timeLimitSeconds,
      draftKey: 'yumegoji_placement_draft_v1',
      onSubmit: _submit,
      onExit: () => Navigator.of(context).maybePop(),
    );
  }
}
