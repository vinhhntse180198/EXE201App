import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/game_item.dart';
import '../../models/pvp_room.dart';
import '../../services/game_service.dart';
import '../../widgets/common/loading_view.dart';
import 'game_play_screen.dart';

/// Phòng PvP sau join — poll trạng thái rồi vào game (khớp web lobby + session).
class PvpGameScreen extends StatefulWidget {
  const PvpGameScreen({
    super.key,
    required this.gameSlug,
    required this.roomCode,
    this.initialRoom,
  });

  final String gameSlug;
  final String roomCode;
  final PvpRoom? initialRoom;

  @override
  State<PvpGameScreen> createState() => _PvpGameScreenState();
}

class _PvpGameScreenState extends State<PvpGameScreen> {
  final _game = GameService(AppSession.instance.api);
  PvpRoom? _room;
  Timer? _poll;
  String? _error;
  bool _starting = false;

  int get _myId => AppSession.instance.user?.user.id ?? 0;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _pollRoom();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollRoom());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _pollRoom() async {
    try {
      final r = await _game.fetchPvpRoom(widget.roomCode);
      if (mounted) setState(() => _room = r);
    } catch (e) {
      if (mounted && _error == null) setState(() => _error = e.toString());
    }
  }

  Future<void> _startBattle() async {
    setState(() => _starting = true);
    final game = GameItem(
      id: 0,
      name: 'PvP ${widget.gameSlug}',
      code: widget.gameSlug,
      isPvp: true,
    );
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GamePlayScreen(
          game: game,
          sessionMode: 'pvp',
          pvpRoomCode: widget.roomCode,
        ),
      ),
    );
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    return Scaffold(
      appBar: AppBar(title: Text('PvP · ${widget.roomCode}')),
      body: room == null && _error == null
          ? const LoadingView(message: 'Đang tải phòng...')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [YumeColors.primary, YumeColors.sakura]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mã phòng: ${room?.roomCode ?? widget.roomCode}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                      const SizedBox(height: 8),
                      Text(
                        'Trạng thái: ${room?.status ?? '…'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _playerTile('Host', room?.hostDisplayName ?? '—', room?.hostUserId == _myId),
                const SizedBox(height: 10),
                _playerTile(
                  'Đối thủ',
                  room?.hasGuest == true ? (room!.guestDisplayName ?? 'Guest') : 'Đang chờ người vào…',
                  room?.guestUserId == _myId,
                  waiting: room?.hasGuest != true,
                ),
                const SizedBox(height: 24),
                if (room?.isWaiting == true)
                  const Text(
                    'Chia sẻ mã phòng cho bạn bè. Khi họ tham gia, trạng thái chuyển sang active.',
                    style: TextStyle(color: YumeColors.muted, height: 1.4),
                  ),
                if (room?.isActive == true) ...[
                  const Text(
                    'Cả hai đã sẵn sàng. Mỗi người chơi phiên riêng (mode pvp) — so điểm sau khi kết thúc.',
                    style: TextStyle(color: YumeColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _starting ? null : _startBattle,
                    icon: const Icon(Icons.sports_esports),
                    label: Text(_starting ? 'Đang mở game...' : 'Bắt đầu đấu'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _playerTile(String role, String name, bool isMe, {bool waiting = false}) {
    return ListTile(
      tileColor: YumeColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: waiting ? YumeColors.border : YumeColors.pinkLight,
        child: Icon(waiting ? Icons.hourglass_empty : Icons.person, color: YumeColors.primary),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(role),
      trailing: isMe ? const Chip(label: Text('Bạn')) : null,
    );
  }
}
