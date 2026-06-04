import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/yume_colors.dart';
import '../../config/yume_decorations.dart';
import '../../models/assessment.dart';
import '../yume/yume_brand_mark.dart';
import 'exam_shell.dart';

/// UI làm bài trắc nghiệm — khớp web `/placement-test` & `/level-up-test`.
class ExamRunner extends StatefulWidget {
  const ExamRunner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.questions,
    required this.timeLimitSeconds,
    required this.onSubmit,
    this.draftKey,
    this.onExit,
  });

  final String title;
  final String subtitle;
  final List<ExamQuestion> questions;
  final int timeLimitSeconds;
  final Future<void> Function(Map<int, String> answers) onSubmit;
  final String? draftKey;
  final VoidCallback? onExit;

  @override
  State<ExamRunner> createState() => _ExamRunnerState();
}

class _ExamRunnerState extends State<ExamRunner> {
  final Map<int, String> _answers = {};
  int _index = 0;
  late int _timeLeft;
  Timer? _timer;
  bool _submitting = false;
  String? _draftSavedAt;
  bool _savingDraft = false;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timeLimitSeconds;
    _hydrateDraft();
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
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _hydrateDraft() async {
    final key = widget.draftKey;
    if (key == null || key.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final answersRaw = decoded['answers'];
      if (answersRaw is Map) {
        for (final e in answersRaw.entries) {
          final qid = int.tryParse(e.key.toString());
          final val = e.value?.toString() ?? '';
          if (qid != null && val.isNotEmpty) _answers[qid] = val;
        }
      }
      final savedAt = decoded['savedAt']?.toString();
      if (mounted) setState(() => _draftSavedAt = savedAt);
    } catch (_) {}
  }

  Future<void> _saveDraft({bool silent = false}) async {
    final key = widget.draftKey;
    if (key == null || key.trim().isEmpty) return;
    if (_savingDraft) return;
    setState(() => _savingDraft = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final savedAt =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await prefs.setString(
        key,
        jsonEncode({
          'answers': _answers.map((k, v) => MapEntry(k.toString(), v)),
          'savedAt': savedAt,
        }),
      );
      if (mounted) setState(() => _draftSavedAt = savedAt);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu tạm.')));
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không lưu được: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  void _scheduleAutosave() {
    if (widget.draftKey == null || widget.draftKey!.trim().isEmpty) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 550), () => _saveDraft(silent: true));
  }

  Future<void> _clearDraft() async {
    final key = widget.draftKey;
    if (key == null || key.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      if (mounted) setState(() => _draftSavedAt = null);
    } catch (_) {}
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmSubmitIfNeeded() async {
    final total = widget.questions.length;
    final answered = _answers.entries.where((e) => e.value.trim().isNotEmpty).length;
    final missing = total - answered;
    if (missing <= 0) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Bạn chưa làm hết'),
        content: Text('Bạn còn $missing/$total câu chưa chọn đáp án. Vẫn nộp bài?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Quay lại')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Nộp luôn')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitting) return;
    if (!auto) {
      final ok = await _confirmSubmitIfNeeded();
      if (!ok) return;
    }
    setState(() => _submitting = true);
    _timer?.cancel();
    try {
      await widget.onSubmit(_answers);
      await _clearDraft();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openQuestionPicker() {
    final total = widget.questions.length;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: YumeColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn câu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: YumeColors.ink)),
                const SizedBox(height: 10),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 44,
                    ),
                    itemCount: total,
                    itemBuilder: (_, i) {
                      final qid = widget.questions[i].id;
                      final answered = _answers[qid] != null && _answers[qid]!.isNotEmpty;
                      final active = i == _index;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          setState(() => _index = i);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: active ? YumeDecorations.playHeroGradient : null,
                            color: active
                                ? null
                                : answered
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? YumeColors.primary
                                  : answered
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: active ? Colors.white : answered ? const Color(0xFF15803D) : const Color(0xFF475569),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const ExamShell(body: Center(child: Text('Không có câu hỏi.')));
    }

    final q = widget.questions[_index];
    final answered = _answers.entries.where((e) => e.value.trim().isNotEmpty).length;
    final total = widget.questions.length;
    final urgent = _timeLeft <= 60;

    return ExamShell(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _examTopBar(total: total, answered: answered, urgent: urgent),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        children: [
                          _questionStrip(total: total),
                          const SizedBox(height: 12),
                          _questionCard(q),
                          const SizedBox(height: 14),
                          ...q.options.map(
                            (o) => _OptionTile(
                              keyLabel: o.key,
                              text: o.text,
                              selected: _answers[q.id] == o.key,
                              onTap: () {
                                setState(() => _answers[q.id] = o.key);
                                _scheduleAutosave();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _examFooter(total: total),
              ],
            ),
          ),
          if (_submitting)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: YumeColors.primary),
                        SizedBox(height: 14),
                        Text('Đang chấm bài...', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _examTopBar({required int total, required int answered, required bool urgent}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              if (widget.onExit != null)
                IconButton(
                  onPressed: widget.onExit,
                  icon: const Icon(Icons.arrow_back_rounded, color: YumeColors.ink),
                ),
              const Expanded(child: YumeBrandMark(size: 34, showTitle: false)),
              _TimerChip(time: _formatTime(_timeLeft), urgent: urgent),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [YumeColors.primary, YumeColors.sakura.withValues(alpha: 0.95)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
                          ),
                          Text(
                            widget.subtitle,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Câu ${_index + 1}/$total',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: YumeColors.primary.withValues(alpha: 0.1)),
              boxShadow: YumeDecorations.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _metaChip('Đã làm: $answered/$total'),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _openQuestionPicker,
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10)),
                      icon: const Icon(Icons.grid_view_rounded, size: 16),
                      label: const Text('Chọn câu', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: _savingDraft ? null : () => _saveDraft(),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10)),
                      icon: _savingDraft
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined, size: 16),
                      label: Text(_draftSavedAt == null ? 'Lưu tạm' : 'Đã lưu', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: answered / total,
                    minHeight: 6,
                    color: YumeColors.primary,
                    backgroundColor: YumeColors.pinkLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionStrip({required int total}) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final qid = widget.questions[i].id;
          final done = _answers[qid] != null && _answers[qid]!.isNotEmpty;
          final active = i == _index;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _index = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? YumeDecorations.playHeroGradient : null,
                color: active ? null : done ? const Color(0xFFDCFCE7) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? YumeColors.primary : done ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: active ? Colors.white : done ? const Color(0xFF15803D) : YumeColors.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _questionCard(ExamQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YumeColors.primary.withValues(alpha: 0.12)),
        boxShadow: YumeDecorations.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: YumeColors.pinkLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Câu ${_index + 1}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: YumeColors.primaryHover),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            q.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.5, color: YumeColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: YumeColors.pinkLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: YumeColors.primaryHover)),
    );
  }

  Widget _examFooter({required int total}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(color: YumeColors.primary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _index > 0 ? () => setState(() => _index--) : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: YumeColors.primary.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Trước', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _submitting
                    ? null
                    : () {
                        if (_index < total - 1) {
                          setState(() => _index++);
                        } else {
                          _submit();
                        }
                      },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _submitting ? null : YumeDecorations.playHeroGradient,
                    color: _submitting ? YumeColors.muted : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      _submitting ? 'Đang nộp...' : (_index < total - 1 ? 'Tiếp' : 'Nộp bài'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.time, required this.urgent});

  final String time;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFEE2E2) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: urgent ? const Color(0xFFF87171) : YumeColors.primary.withValues(alpha: 0.2)),
        boxShadow: YumeDecorations.glassShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: urgent ? const Color(0xFFB91C1C) : YumeColors.primary),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(fontWeight: FontWeight.w900, color: urgent ? const Color(0xFFB91C1C) : YumeColors.primaryHover),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.keyLabel,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String keyLabel;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final letter = keyLabel.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: selected ? YumeColors.pinkLight.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? YumeColors.primary : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: YumeColors.primary.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 4))]
                  : YumeDecorations.cardShadow,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? YumeDecorations.playHeroGradient : null,
                    color: selected ? null : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : YumeColors.primaryHover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 15, height: 1.4, color: YumeColors.text),
                        children: [
                          TextSpan(
                            text: '$letter. ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: selected ? YumeColors.primaryHover : YumeColors.muted,
                            ),
                          ),
                          TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (selected) const Icon(Icons.check_circle_rounded, color: YumeColors.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
