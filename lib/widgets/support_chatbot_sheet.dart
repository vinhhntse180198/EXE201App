import 'package:flutter/material.dart';

import '../config/app_flags.dart';
import '../config/yume_colors.dart';
import '../core/session/app_session.dart';
import '../screens/chat/chat_room_screen.dart';
import '../services/chat_service.dart';
import '../services/chatbot_service.dart';

/// Chatbot hỗ trợ — khớp web `ChatbotWidget` (guest + moderator support).
class SupportChatbotSheet extends StatefulWidget {
  const SupportChatbotSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SupportChatbotSheet(),
    );
  }

  @override
  State<SupportChatbotSheet> createState() => _SupportChatbotSheetState();
}

class _SupportChatbotSheetState extends State<SupportChatbotSheet> {
  final _input = TextEditingController();
  final _messages = <({bool bot, String text})>[];
  bool _loading = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final msg = _input.text.trim();
    if (msg.isEmpty) return;
    setState(() {
      _messages.add((bot: false, text: msg));
      _loading = true;
    });
    _input.clear();
    try {
      final reply = designMode
          ? 'Đây là phản hồi mẫu (design mode).'
          : await ChatbotService(AppSession.instance.api).askGuest(msg);
      if (mounted) setState(() => _messages.add((bot: true, text: reply)));
    } catch (e) {
      if (mounted) setState(() => _messages.add((bot: true, text: e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openModeratorChat() async {
    if (designMode) return;
    try {
      final room = await ChatService(AppSession.instance.api).createModeratorSupportRoom();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(room: room)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Trợ lý Yume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  return Align(
                    alignment: m.bot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: m.bot ? YumeColors.card : YumeColors.pinkLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(m.text),
                    ),
                  );
                },
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'Hỏi về Yume, học, game...'),
                      onSubmitted: (_) => _ask(),
                    ),
                  ),
                  IconButton(onPressed: _ask, icon: const Icon(Icons.send)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: designMode ? null : _openModeratorChat,
                icon: const Icon(Icons.support_agent),
                label: const Text('Chat với Moderator'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
