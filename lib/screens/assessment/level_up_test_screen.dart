import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';
import '../../services/assessment_service.dart';
import '../../widgets/assessment/exam_runner.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await _svc.fetchLevelUpTest(widget.toLevel);
      if (mounted) setState(() => _test = t);
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
      return Scaffold(
        appBar: AppBar(title: const Text('Kết quả thi lên level')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                r.isPassed ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: r.isPassed ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                r.isPassed ? 'ĐẠT — lên ${r.toLevel}' : 'Chưa đạt',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text('Điểm: ${r.score}/${r.maxScore}'),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(r.isPassed),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) return const Scaffold(body: LoadingView(message: 'Đang tải đề thi...'));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Thi lên ${widget.toLevel}')),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final t = _test!;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: ExamRunner(
        title: t.title,
        subtitle: '${t.fromLevel} → ${t.toLevel} · Đạt ${t.passScore}/${t.totalPoints} điểm',
        questions: t.questions,
        timeLimitSeconds: t.timeLimitSeconds,
        onSubmit: _submit,
      ),
    );
  }
}
