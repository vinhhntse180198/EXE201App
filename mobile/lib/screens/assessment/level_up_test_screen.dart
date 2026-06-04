import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';
import '../../services/api_client.dart';
import '../../services/assessment_service.dart';
import '../../utils/jlpt_levels.dart';
import '../../models/auth_response.dart';
import '../../widgets/assessment/exam_intro_panel.dart';
import '../../widgets/assessment/exam_result_panel.dart';
import '../../widgets/assessment/exam_runner.dart';
import '../../widgets/assessment/exam_shell.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

/// Thi lên level — khớp web `/level-up-test/:toLevel`.
class LevelUpTestScreen extends StatefulWidget {
  const LevelUpTestScreen({super.key, required this.toLevel});

  final String toLevel;

  @override
  State<LevelUpTestScreen> createState() => _LevelUpTestScreenState();
}

class _LevelUpTestScreenState extends State<LevelUpTestScreen> {
  final _svc = AssessmentService(AppSession.instance.api);

  bool _loading = true;
  String? _error;
  dynamic _test;
  dynamic _result;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _friendlyLevelUpError(ApiException e) {
    if (e.statusCode == 403) {
      return 'Tài khoản Moderator/Admin không làm bài thi nâng level.\nĐăng nhập tài khoản học viên (vd. member2@gmail.com).';
    }
    if (e.statusCode == 404) {
      final levelId = AppSession.instance.user?.user.levelId;
      if (levelId == null) {
        return 'Tài khoản chưa có level JLPT.\nLàm Placement Test trước (Dashboard → Bài kiểm tra đầu vào), rồi thi lên ${widget.toLevel}.';
      }
      return 'Chưa có đề phù hợp từ ${levelCodeFromId(levelId)} → ${widget.toLevel}.\nKiểm tra level hiện tại hoặc liên hệ moderator.';
    }
    return e.message;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await _svc.fetchLevelUpTest(widget.toLevel);
      if (mounted) setState(() => _test = t);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _friendlyLevelUpError(e));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit(Map<int, String> answers) async {
    try {
      final t = _test!;
      final r = await _svc.submitLevelUp(testId: t.testId, answers: answers);
      if (r.isPassed) {
        final session = AppSession.instance.user;
        if (session != null) {
          final newLevelId = levelIdFromCode(r.toLevel) ?? session.user.levelId;
          final updated = session.user.copyWith(levelId: newLevelId);
          AppSession.instance.applyAuth(AuthResponse(
            accessToken: session.accessToken,
            user: updated,
            needsPlacementTest: session.needsPlacementTest,
          ));
          await AppSession.instance.auth.updateCachedUser(updated);
        }
      }
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      final r = _result;
      return ExamResultPanel(
        title: 'Kết quả thi lên level',
        headline: r.isPassed ? 'Chúc mừng — đạt ${r.toLevel}!' : 'Chưa đạt lần này',
        subtitle: r.isPassed
            ? 'Level của bạn đã được cập nhật trên hệ thống.'
            : 'Chưa đủ điểm để lên ${r.toLevel}. Ôn thêm và thử lại nhé.',
        badgeLabel: r.isPassed ? '${r.fromLevel} → ${r.toLevel}' : null,
        score: r.score,
        maxScore: r.maxScore,
        isPassed: r.isPassed,
        detailLines: r.isPassed
            ? ['Mở khóa nội dung và phòng chat level mới.', 'Tiếp tục học trên Dashboard.']
            : ['Xem lại bài học level hiện tại.', 'Làm lại khi đã sẵn sàng.'],
        primaryLabel: 'Quay lại',
        onPrimary: () => Navigator.of(context).pop(r.isPassed),
        onBack: () => Navigator.of(context).pop(r.isPassed),
      );
    }

    if (_loading) {
      return ExamShell(body: LoadingView(message: 'Đang tải đề thi...'));
    }
    if (_error != null) {
      return ExamShell(
        appBar: examAppBar(title: 'Thi lên ${widget.toLevel}', onBack: () => Navigator.of(context).maybePop()),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final t = _test!;
    if (!_started) {
      return ExamIntroPanel(
        title: t.title.isNotEmpty ? t.title : 'Thi lên ${widget.toLevel}',
        subtitle: '${t.fromLevel} → ${t.toLevel} · ${t.timeLimitSeconds ~/ 60} phút',
        badgeLabel: '${t.fromLevel} → ${t.toLevel}',
        description: t.description ?? 'Bài thi nâng trình độ JLPT. Đạt điểm yêu cầu để mở khóa level mới.',
        rules: [
          'Điểm đạt: ${t.passScore}/${t.totalPoints} (${((t.passScore / t.totalPoints) * 100).round()}%).',
          'Thời gian: ${t.timeLimitSeconds ~/ 60} phút. Hết giờ tự nộp bài.',
          'Chọn đáp án A/B/C/D trước khi nộp.',
          'Đậu sẽ cập nhật level trên tài khoản ngay.',
        ],
        onBack: () => Navigator.of(context).maybePop(),
        onStart: () => setState(() => _started = true),
      );
    }

    return ExamRunner(
      title: t.title,
      subtitle: '${t.fromLevel} → ${t.toLevel} · Đạt ${t.passScore}/${t.totalPoints} điểm',
      questions: t.questions,
      timeLimitSeconds: t.timeLimitSeconds,
      draftKey: 'yumegoji_level_up_draft_${t.testId}',
      onSubmit: _submit,
      onExit: () => Navigator.of(context).maybePop(),
    );
  }
}
