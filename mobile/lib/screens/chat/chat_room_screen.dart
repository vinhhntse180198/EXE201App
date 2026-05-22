import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_hub_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/common/loading_view.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.room,
    this.hub,
    this.designOnly = false,
  });

  final ChatRoom room;
  final ChatHubService? hub;
  final bool designOnly;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final ChatService _chat = ChatService(AppSession.instance.api);
  final _input = TextEditingController();
  final _scroll = ScrollController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  String _status = '';

  int? get _myUserId => AppSession.instance.user?.user.id;

  late final ChatHubHandler _hubListener = (payload) {
    final roomId = payload['roomId'] as int? ?? payload['chatRoomId'] as int?;
    if (roomId != null && roomId != widget.room.id) return;
    _appendMessage(ChatMessage.fromJson(payload));
  };

  @override
  void initState() {
    super.initState();
    widget.hub?.addMessageListener(_hubListener);
    _bootstrap();
  }

  @override
  void dispose() {
    widget.hub?.removeMessageListener(_hubListener);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.designOnly) {
      setState(() {
        _messages = [
          ChatMessage(id: 1, senderId: 0, senderName: 'Yume Bot', content: 'Chào bạn! (design)', sentAt: DateTime.now()),
        ];
        _loading = false;
      });
      return;
    }

    try {
      if (!widget.designOnly) await _chat.joinRoom(widget.room.id);
      final hub = widget.hub;
      if (hub != null) {
        await hub.joinRoom(widget.room.id);
        if (hub.isConnected) {
          // Hub đã connect ở màn list; chỉ join room.
        }
      }
      final list = await _chat.fetchRoomMessages(widget.room.id);
      if (mounted) setState(() => _messages = list);
    } catch (e) {
      if (mounted) setState(() => _status = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appendMessage(ChatMessage m) {
    if (_messages.any((x) => x.id == m.id && m.id != 0)) return;
    setState(() => _messages = [..._messages, m]);
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

  Future<void> _toggleReaction(ChatMessage m, String emoji) async {
    if (widget.designOnly) return;
    final existing = m.reactions.where((r) => r.emoji == emoji && r.reactedByMe).isNotEmpty;
    try {
      if (existing) {
        await _chat.removeReaction(widget.room.id, m.id, emoji);
      } else {
        await _chat.addReaction(widget.room.id, m.id, emoji);
      }
      final list = await _chat.fetchRoomMessages(widget.room.id);
      if (mounted) setState(() => _messages = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reaction: $e')));
      }
    }
  }

  void _showReactionPicker(ChatMessage m) {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis
                .map(
                  (e) => IconButton(
                    iconSize: 32,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _toggleReaction(m, e);
                    },
                    icon: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || widget.designOnly) return;
    _input.clear();
    try {
      final msg = await _chat.sendMessage(widget.room.id, text);
      _appendMessage(msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gửi lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: YumeColors.pinkLight,
              child: Text(
                widget.room.name.isNotEmpty ? widget.room.name[0].toUpperCase() : '💬',
                style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (widget.room.roomType != null)
                    Text(widget.room.roomType!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(_status, style: const TextStyle(fontSize: 11, color: YumeColors.muted)),
            ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _bubble(_messages[i]),
                  ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = _myUserId != null && m.senderId == _myUserId;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showReactionPicker(m),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              decoration: BoxDecoration(
                gradient: mine
                    ? const LinearGradient(colors: [YumeColors.primary, YumeColors.sakura])
                    : null,
                color: mine ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 6),
                  bottomRight: Radius.circular(mine ? 6 : 18),
                ),
                border: mine ? null : Border.all(color: YumeColors.border.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: YumeColors.primary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(m.senderName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: YumeColors.muted)),
                    ),
                  Text(m.content, style: TextStyle(color: mine ? Colors.white : YumeColors.ink, height: 1.35)),
                ],
              ),
            ),
            if (m.reactions.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: m.reactions
                    .map(
                      (r) => ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text('${r.emoji} ${r.count}', style: const TextStyle(fontSize: 11)),
                        backgroundColor: r.reactedByMe ? YumeColors.pinkLight : Colors.white,
                        onPressed: () => _toggleReaction(m, r.emoji),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded, size: 20),
              style: IconButton.styleFrom(backgroundColor: YumeColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
