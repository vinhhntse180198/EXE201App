import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/pvp_room.dart';
import '../../services/game_service.dart';
import '../../utils/json_field.dart';
import '../../widgets/common/loading_view.dart';
import 'pvp_game_screen.dart';

class PlayPvpScreen extends StatefulWidget {
  const PlayPvpScreen({super.key, this.gameSlug = 'flashcard-battle'});

  final String gameSlug;

  @override
  State<PlayPvpScreen> createState() => _PlayPvpScreenState();
}

class _PlayPvpScreenState extends State<PlayPvpScreen> {
  final _game = GameService(AppSession.instance.api);
  final _joinCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _joinCtrl.dispose();
    super.dispose();
  }

  void _openRoom(String code, {PvpRoom? room}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PvpGameScreen(
          gameSlug: widget.gameSlug,
          roomCode: code,
          initialRoom: room,
        ),
      ),
    );
  }

  Future<void> _create() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _game.createPvpRoom(gameSlug: widget.gameSlug);
      final code = jsonStr(raw, 'roomCode') ?? jsonStr(raw, 'RoomCode') ?? '';
      final room = PvpRoom.fromJson(raw);
      if (!mounted) return;
      _openRoom(code, room: room);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    final code = _joinCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _game.joinPvpRoom(code);
      final room = PvpRoom.fromJson(raw);
      if (!mounted) return;
      _openRoom(code, room: room);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PvP Lobby')),
      body: _loading
          ? const LoadingView(message: 'Đang xử lý...')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Game: ${widget.gameSlug}', style: TextStyle(color: YumeColors.muted)),
                const SizedBox(height: 16),
                const Text('Tạo phòng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                FilledButton(onPressed: _create, child: const Text('Tạo phòng mới')),
                const Divider(height: 32),
                const Text('Tham gia phòng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                TextField(
                  controller: _joinCtrl,
                  decoration: const InputDecoration(labelText: 'Mã phòng', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _join, child: const Text('Vào phòng')),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
    );
  }
}
