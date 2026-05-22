import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../services/api_client.dart';
import '../../services/learn_ai_service.dart';

class _UiMessage {
  _UiMessage({
    required this.id,
    required this.role,
    required this.content,
    this.displayContent,
  });

  final String id;
  final String role;
  final String content;
  final String? displayContent;
}

class _TextSnippet {
  _TextSnippet({required this.id, required this.name, required this.text});

  final String id;
  final String name;
  final String text;
}

class _ImageAttach {
  _ImageAttach({required this.id, required this.name, required this.base64});

  final String id;
  final String name;
  final String base64;
}

/// Yumegoji AI — FAB + panel chat (khớp web `LearnAiWidget`).
class LearnAiWidget extends StatefulWidget {
  const LearnAiWidget({super.key, this.fabBottomOffset = 12});

  /// Khoảng cách FAB từ đáy (tăng khi có nút cố định phía dưới).
  final double fabBottomOffset;

  static LearnAiWidgetState? of(BuildContext context) {
    return context.findAncestorStateOfType<LearnAiWidgetState>();
  }

  @override
  State<LearnAiWidget> createState() => LearnAiWidgetState();
}

class LearnAiWidgetState extends State<LearnAiWidget> {
  final _ai = LearnAiService(AppSession.instance.api);
  final _draft = TextEditingController();
  final _scroll = ScrollController();

  bool _open = false;
  bool _busy = false;
  bool _docBusy = false;
  String? _error;
  final List<_UiMessage> _messages = [];
  final List<_ImageAttach> _images = [];
  final List<_TextSnippet> _snippets = [];

  bool get _isLoggedIn => AppSession.instance.isLoggedIn;

  void openPanel() => setState(() => _open = true);

  void closePanel() => setState(() => _open = false);

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFiles() async {
    if (!_isLoggedIn) {
      setState(() => _error = 'Đăng nhập để đính kèm file.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'txt', 'md', 'pdf', 'docx', 'pptx'],
    );
    if (result == null) return;

    for (final f in result.files) {
      if (f.bytes == null && f.path == null) continue;
      final name = f.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

      if (['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
        if (f.bytes == null) continue;
        if (f.bytes!.length > 2_200_000) {
          setState(() => _error = 'Ảnh "$name" quá lớn.');
          continue;
        }
        setState(() {
          _images.add(_ImageAttach(
            id: '${DateTime.now().millisecondsSinceEpoch}-$name',
            name: name,
            base64: base64Encode(f.bytes!),
          ));
        });
      } else if (['txt', 'md'].contains(ext)) {
        final text = utf8.decode(f.bytes ?? [], allowMalformed: true);
        var t = text;
        if (t.length > 24000) t = '${t.substring(0, 24000)}\n\n…(đã cắt bớt)';
        setState(() {
          _snippets.add(_TextSnippet(id: '${DateTime.now().millisecondsSinceEpoch}-$name', name: name, text: t));
        });
      } else if (['pdf', 'docx', 'pptx'].contains(ext)) {
        if (f.bytes == null) continue;
        setState(() {
          _docBusy = true;
          _error = null;
        });
        try {
          final res = await _ai.extractDocument(bytes: f.bytes!, filename: name);
          var t = res.plainText;
          if (res.warning != null) t += '\n\n---\n(${res.warning})';
          if (t.trim().isEmpty) {
            setState(() => _error = 'Không trích được chữ từ file.');
          } else {
            setState(() {
              _snippets.add(_TextSnippet(id: '${DateTime.now().millisecondsSinceEpoch}-$name', name: name, text: t));
            });
          }
        } catch (e) {
          setState(() => _error = e is ApiException ? e.message : 'Không tải được tài liệu.');
        } finally {
          if (mounted) setState(() => _docBusy = false);
        }
      } else {
        setState(() => _error = 'Chỉ hỗ trợ ảnh, .txt/.md, .pdf/.docx/.pptx');
      }
    }
  }

  String _buildApiContent(String q) {
    var userContent = q;
    if (_snippets.isNotEmpty) {
      final blocks = _snippets.map((s) => '### ${s.name}\n${s.text}');
      userContent = [userContent, ...blocks].where((s) => s.isNotEmpty).join('\n\n---\n\n');
    }
    return userContent;
  }

  String _buildBubbleDisplay(String q) {
    final docNames = _snippets.map((s) => s.name).join(', ');
    final attach = <String>[];
    if (docNames.isNotEmpty) attach.add(docNames);
    if (_images.isNotEmpty) attach.add('${_images.length} ảnh');
    final attachLine = attach.isNotEmpty ? '📎 ${attach.join(' · ')}' : '';
    if (q.isNotEmpty && attachLine.isNotEmpty) return '$q\n$attachLine';
    if (q.isNotEmpty) return q;
    if (attachLine.isNotEmpty) return '$attachLine\n(Nội dung đã gửi kèm cho AI)';
    return '';
  }

  Future<void> _send() async {
    final q = _draft.text.trim();
    if (q.isEmpty && _images.isEmpty && _snippets.isEmpty) return;
    if (!_isLoggedIn && !designMode) {
      setState(() => _error = 'Đăng nhập để dùng Yumegoji AI.');
      return;
    }

    final apiContent = _buildApiContent(q);
    final bubble = _buildBubbleDisplay(q);
    final imgs = _images.map((e) => e.base64).toList();

    final history = _messages.map((m) => LearnAiMessage(role: m.role, content: m.content)).toList();
    history.add(LearnAiMessage(role: 'user', content: apiContent.isEmpty ? '(Đính kèm ảnh)' : apiContent));

    setState(() {
      _error = null;
      _busy = true;
      _draft.clear();
      _messages.add(_UiMessage(
        id: 'u-${DateTime.now().millisecondsSinceEpoch}',
        role: 'user',
        content: apiContent,
        displayContent: bubble.isNotEmpty ? bubble : apiContent,
      ));
      _images.clear();
      _snippets.clear();
    });
    _scrollToEnd();

    if (designMode) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _messages.add(_UiMessage(
            id: 'a-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: 'Xin chào! Đây là phản hồi mẫu Yumegoji AI (design mode). Bật API: `flutter run` không có DESIGN_MODE.',
          ));
          _busy = false;
        });
        _scrollToEnd();
      }
      return;
    }

    try {
      final reply = await _ai.chat(messages: history, imagesBase64: imgs.isEmpty ? null : imgs);
      if (mounted) {
        setState(() {
          _messages.add(_UiMessage(
            id: 'a-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: reply.isEmpty ? '(Không có phản hồi)' : reply,
          ));
        });
        _scrollToEnd();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.statusCode == 503
              ? 'Ollama chưa chạy. Trên máy backend: `ollama serve` và tải model.'
              : e.message;
          if (_messages.isNotEmpty && _messages.last.role == 'user') {
            _messages.removeLast();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không gửi được tin nhắn.';
          if (_messages.isNotEmpty && _messages.last.role == 'user') {
            _messages.removeLast();
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_open) Positioned.fill(child: _panel(context)),
        Positioned(
          right: 12,
          bottom: widget.fabBottomOffset,
          child: _fab(),
        ),
      ],
    );
  }

  Widget _fab() {
    return Material(
      elevation: 6,
      shadowColor: YumeColors.primary.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [YumeColors.primary, YumeColors.sakura]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_open ? Icons.close_rounded : Icons.auto_awesome, color: Colors.white, size: 22),
                if (!_open) ...[
                  const SizedBox(width: 8),
                  const Text('Yumegoji AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.78,
          margin: EdgeInsets.only(bottom: bottom + 56),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBFE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _panelHeader(),
              Expanded(child: _isLoggedIn || designMode ? _chatBody() : _loginGate()),
              if (_isLoggedIn || designMode) _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: YumeColors.border)),
        gradient: LinearGradient(
          colors: [YumeColors.pinkLight.withValues(alpha: 0.6), Colors.white],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: YumeColors.pinkLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, color: YumeColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yumegoji AI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: YumeColors.ink)),
                Text('Hỏi bài, đính ảnh hoặc tài liệu', style: TextStyle(fontSize: 11, color: YumeColors.muted)),
              ],
            ),
          ),
          IconButton(onPressed: closePanel, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _loginGate() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Đăng nhập để dùng Yumegoji AI trên màn Học tập.',
          textAlign: TextAlign.center,
          style: TextStyle(color: YumeColors.muted),
        ),
      ),
    );
  }

  Widget _chatBody() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  YumeColors.pinkLight.withValues(alpha: 0.25),
                  const Color(0xFFFFFBFE),
                ],
              ),
            ),
            child: _messages.isEmpty && !_busy
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Hỏi về bài học, ngữ pháp, hoặc đính kèm ảnh / PDF để AI phân tích.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: YumeColors.muted, height: 1.4),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) return _typingBubble();
                      return _bubble(_messages[i]);
                    },
                  ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        if (_docBusy)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Đang trích văn bản từ tài liệu…', style: TextStyle(fontSize: 12, color: YumeColors.muted)),
              ],
            ),
          ),
        if (_images.isNotEmpty || _snippets.isNotEmpty) _attachBar(),
      ],
    );
  }

  Widget _bubble(_UiMessage m) {
    final isUser = m.role == 'user';
    final text = m.displayContent ?? m.content;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? YumeColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: YumeColors.border),
          boxShadow: [
            if (!isUser) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'Bạn' : 'Yumegoji AI',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isUser ? Colors.white70 : YumeColors.primary),
            ),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(color: isUser ? Colors.white : YumeColors.ink, height: 1.35)),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YumeColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: YumeColors.primary)),
            SizedBox(width: 8),
            Text('Yumegoji AI đang soạn…', style: TextStyle(fontSize: 12, color: YumeColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _attachBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          ..._images.map((img) => Chip(
                label: Text(img.name, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _images.removeWhere((x) => x.id == img.id)),
              )),
          ..._snippets.map((s) => Chip(
                label: Text(s.name, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _snippets.removeWhere((x) => x.id == s.id)),
              )),
        ],
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: YumeColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _busy || _docBusy ? null : _pickFiles,
              icon: const Icon(Icons.add_circle_outline, color: YumeColors.primary),
              tooltip: 'Đính ảnh / tài liệu',
            ),
            Expanded(
              child: TextField(
                controller: _draft,
                maxLines: 4,
                minLines: 1,
                enabled: !_busy && !_docBusy,
                decoration: InputDecoration(
                  hintText: 'Hỏi bài, dán nội dung…',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: _busy || _docBusy ? null : _send,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bọc màn Học + FAB Yumegoji AI.
class LearnWithAi extends StatelessWidget {
  const LearnWithAi({super.key, required this.child, this.fabBottomOffset = 12});

  final Widget child;
  final double fabBottomOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        LearnAiWidget(fabBottomOffset: fabBottomOffset),
      ],
    );
  }

  static void openAi(BuildContext context) {
    LearnAiWidget.of(context)?.openPanel();
  }
}
