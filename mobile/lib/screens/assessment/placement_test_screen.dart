import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/auth_response.dart';
import '../../services/assessment_service.dart';
import '../../utils/post_login_nav.dart';
import '../../widgets/assessment/exam_runner.dart';
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
        AppSession.instance.applyAuth(AuthResponse(
          accessToken: session.accessToken,
          user: session.user,
          needsPlacementTest: false,
        ));
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
      return Scaffold(
        appBar: AppBar(title: const Text('Kết quả Placement')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, size: 64, color: YumeColors.primary),
              const SizedBox(height: 16),
              Text(
                'Trình độ: ${r.levelLabel}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text('${r.correctCount}/${r.totalCount} câu đúng'),
              const Spacer(),
              FilledButton(onPressed: _goApp, child: const Text('Vào ứng dụng')),
            ],
          ),
        ),
      );
    }

    if (_loading) return const Scaffold(body: LoadingView(message: 'Đang tải bài test...'));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Placement Test')),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final t = _test!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra trình độ'),
        automaticallyImplyLeading: false,
      ),
      body: ExamRunner(
        title: 'Placement Test',
        subtitle: '${t.totalQuestions} câu · ${t.timeLimitSeconds ~/ 60} phút',
        questions: t.questions,
        timeLimitSeconds: t.timeLimitSeconds,
        onSubmit: _submit,
      ),
    );
  }
}
