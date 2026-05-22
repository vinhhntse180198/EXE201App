import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../models/assessment.dart';

/// UI làm bài trắc nghiệm — dùng chung Placement & Level-up (khớp web).
class ExamRunner extends StatefulWidget {
  const ExamRunner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.questions,
    required this.timeLimitSeconds,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final List<ExamQuestion> questions;
  final int timeLimitSeconds;
  final Future<void> Function(Map<int, String> answers) onSubmit;

  @override
  State<ExamRunner> createState() => _ExamRunnerState();
}

class _ExamRunnerState extends State<ExamRunner> {
  final Map<int, String> _answers = {};
  int _index = 0;
  late int _timeLeft;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timeLimitSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft <= 0) {
        _timer?.cancel();
        _submit(auto: true);
        return;
      }
      setState(() => _timeLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    try {
      await widget.onSubmit(_answers);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(child: Text('Không có câu hỏi.'));
    }
    final q = widget.questions[_index];
    final answered = _answers.length;
    final total = widget.questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(widget.subtitle, style: const TextStyle(color: YumeColors.muted, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text('Câu ${_index + 1}/$total'),
                    backgroundColor: YumeColors.pinkLight,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Đã chọn: $answered'),
                    backgroundColor: YumeColors.card,
                  ),
                  const Spacer(),
                  Text(_formatTime(_timeLeft), style: const TextStyle(fontWeight: FontWeight.w700, color: YumeColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (_index + 1) / total, color: YumeColors.primary),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: 16),
                ...q.options.map((o) {
                  final selected = _answers[q.id] == o.key;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: selected ? YumeColors.pinkLight : YumeColors.card,
                    child: ListTile(
                      title: Text('${o.key.toUpperCase()}. ${o.text}'),
                      onTap: () => setState(() => _answers[q.id] = o.key),
                      trailing: selected ? const Icon(Icons.check_circle, color: YumeColors.primary) : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _index > 0 ? () => setState(() => _index--) : null,
                  child: const Text('Trước'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            if (_index < total - 1) {
                              setState(() => _index++);
                            } else {
                              _submit();
                            }
                          },
                    child: Text(_submitting ? 'Đang nộp...' : (_index < total - 1 ? 'Tiếp' : 'Nộp bài')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
