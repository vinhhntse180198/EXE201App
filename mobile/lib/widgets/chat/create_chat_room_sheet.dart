import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';

class CreateChatRoomSheet extends StatefulWidget {
  const CreateChatRoomSheet({super.key});

  static Future<ChatRoom?> show(BuildContext context) {
    return showModalBottomSheet<ChatRoom>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreateChatRoomSheet(),
    );
  }

  @override
  State<CreateChatRoomSheet> createState() => _CreateChatRoomSheetState();
}

class _CreateChatRoomSheetState extends State<CreateChatRoomSheet> {
  final _name = TextEditingController();
  String _type = 'group';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Nhập tên phòng.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final room = await ChatService(AppSession.instance.api).createRoom(
        name: n,
        type: _type,
      );
      if (mounted) Navigator.pop(context, room);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tạo phòng chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tên phòng', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Loại phòng', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'group', child: Text('Nhóm')),
              DropdownMenuItem(value: 'public', child: Text('Công khai')),
              DropdownMenuItem(value: 'level', child: Text('Theo cấp')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'group'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Đang tạo...' : 'Tạo phòng'),
          ),
        ],
      ),
    );
  }
}
