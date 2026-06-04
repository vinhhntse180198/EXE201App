import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_hub_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat/chat_message_body.dart';
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

  late ChatRoom _room;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String _status = '';

  int? get _myUserId => AppSession.instance.user?.user.id;

  late final ChatHubHandler _hubListener = _onHubMessage;

  void _onHubMessage(Map<String, dynamic> payload) {
    final roomId = payload['roomId'] as int? ?? payload['chatRoomId'] as int?;
    if (roomId != null && roomId != widget.room.id) return;
    _appendMessage(ChatMessage.fromJson(payload));
  }

  @override
  void initState() {
    super.initState();
    _room = widget.room;
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
      if (!widget.room.isDirect) {
        await _chat.joinRoom(widget.room.id);
      }
      final hub = widget.hub;
      if (hub != null) {
        await hub.joinRoom(widget.room.id);
      }

      if (_room.isDirect && (_room.peerDisplayName == null || _room.peerDisplayName!.trim().isEmpty)) {
        final detail = await _chat.fetchRoom(widget.room.id);
        if (detail != null && mounted) {
          _room = detail;
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

  String get _roomSubtitle {
    if (_room.isDirect) return 'Tin nhắn riêng tư';
    final t = (_room.roomType ?? '').toLowerCase();
    if (t == 'level') return 'Phòng theo level JLPT';
    if (t == 'public') return 'Phòng công khai';
    if (t == 'group') return 'Nhóm chat';
    return _room.description ?? 'Phòng chat';
  }

  @override
  Widget build(BuildContext context) {
    final title = _room.displayTitle;
    final avatarLetter = title.isNotEmpty ? title[0].toUpperCase() : '💬';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: YumeColors.pinkLight,
              child: Text(
                avatarLetter,
                style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: YumeColors.ink)),
                  Text(_roomSubtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: YumeColors.muted)),
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
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có tin nhắn.\nHãy gửi lời chào!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: YumeColors.muted.withValues(alpha: 0.9), height: 1.4),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) => _messageRow(_messages[i]),
                      ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _messageRow(ChatMessage m) {
    final mine = _myUserId != null && m.senderId == _myUserId;
    final showSender = !mine && !_room.isDirect;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mine) ...[
            _avatarBubble(m.senderName),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      m.senderName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: YumeColors.muted),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () => _showReactionPicker(m),
                  child: _bubble(m, mine: mine),
                ),
                if (m.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
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
                  ),
              ],
            ),
          ),
          if (mine) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _avatarBubble(String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: YumeColors.pinkLight,
      child: Text(letter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: YumeColors.primary)),
    );
  }

  Widget _bubble(ChatMessage m, {required bool mine}) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: mine ? const LinearGradient(colors: [YumeColors.primary, YumeColors.sakura]) : null,
        color: mine ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: YumeColors.primary.withValues(alpha: mine ? 0.12 : 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: mine ? Colors.white : YumeColors.ink, height: 1.35, fontSize: 15),
        child: ChatMessageBody(
          content: m.content,
          messageType: m.messageType,
          maxImageHeight: 200,
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: YumeColors.primary.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: YumeColors.primary, width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: YumeColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _send,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.send_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
