import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../models/chat_room.dart';
import '../../models/friend_models.dart';
import '../../services/chat_hub_service.dart';
import '../../services/chat_service.dart';
import '../../services/social_service.dart';
import '../../widgets/chat/create_chat_room_sheet.dart';
import '../../utils/jlpt_levels.dart';
import '../../utils/image_url.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import 'chat_room_screen.dart';
import '../social/friends_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _chat = ChatService(AppSession.instance.api);
  final _social = SocialService(AppSession.instance.api);
  final _hub = ChatHubService();

  List<FriendUser> _friends = [];
  List<ChatRoom> _myRooms = [];
  List<ChatRoom> _publicRooms = [];
  List<ChatRoom> _levelRooms = [];
  bool _loading = false;
  String? _error;
  String _hubStatus = '';
  String _query = '';

  int? get _myUserId => AppSession.instance.user?.user.id;

  int? get _myLevelId => AppSession.instance.user?.user.levelId ?? 1;

  String get _myLevelCode => levelCodeFromId(_myLevelId);

  /// Chỉ phòng JLPT trùng level đang học (N5, N4, …).
  List<ChatRoom> get _roomsForMyLevel {
    final lid = _myLevelId;
    final code = _myLevelCode.toLowerCase();
    return _levelRooms.where((r) {
      if (r.levelId != null) return r.levelId == lid;
      final slug = (r.slug ?? '').toLowerCase();
      final name = r.displayTitle.toLowerCase();
      return slug.contains(code) || name.contains(code);
    }).toList();
  }

  List<ChatRoom> get _myGroups {
    final uid = _myUserId;
    return _myRooms.where((r) {
      if (r.isDirect) return false;
      if (uid != null && r.createdBy != null) return r.createdBy == uid;
      return r.isGroup;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (designMode) {
      _friends = MockData.chatFriends;
      _myRooms = MockData.chatRooms;
      _levelRooms = MockData.levelChatRooms;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _hub.disconnect();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = AppSession.instance.user?.accessToken ?? '';
      if (token.isNotEmpty && !_hub.isConnected) {
        await _hub.connect(
          accessToken: token,
          onStatus: (s) {
            if (mounted) setState(() => _hubStatus = s);
          },
        );
      }
      final myLevel = AppSession.instance.user?.user.levelId;
      final results = await Future.wait([
        _social.fetchFriends(),
        _chat.fetchMyRooms(),
        _chat.fetchPublicRooms(type: 'public'),
        _chat.fetchLevelRoomsForUser(myLevel),
      ]);
      if (mounted) {
        setState(() {
          _friends = results[0] as List<FriendUser>;
          _myRooms = results[1] as List<ChatRoom>;
          _publicRooms = results[2] as List<ChatRoom>;
          _levelRooms = results[3] as List<ChatRoom>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<FriendUser> _filterFriends(List<FriendUser> rows) {
    if (_query.isEmpty) return rows;
    final q = _query.toLowerCase();
    return rows
        .where(
          (f) =>
              f.label.toLowerCase().contains(q) ||
              f.username.toLowerCase().contains(q),
        )
        .toList();
  }

  List<ChatRoom> _filterRooms(List<ChatRoom> rooms) {
    if (_query.isEmpty) return rooms;
    final q = _query.toLowerCase();
    return rooms.where((r) => r.displayTitle.toLowerCase().contains(q)).toList();
  }

  Future<void> _openRoom(ChatRoom room, {bool joinFirst = false}) async {
    if (!designMode && joinFirst && !room.isDirect) {
      try {
        await _chat.joinRoom(room.id);
      } catch (_) {}
    }
    if (!designMode) await _hub.joinRoom(room.id);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(room: room, hub: _hub, designOnly: designMode),
      ),
    );
    if (!designMode) await _hub.leaveRoom(room.id);
    if (!designMode) _load();
  }

  Future<void> _openFriendChat(FriendUser friend) async {
    if (designMode) {
      ChatRoom? direct;
      for (final r in _myRooms) {
        if (r.isDirect) {
          direct = r;
          break;
        }
      }
      await _openRoom(
        direct ??
            ChatRoom(
              id: 99,
              name: friend.label,
              roomType: 'private',
              peerUserId: friend.id,
              peerDisplayName: friend.label,
            ),
      );
      return;
    }
    try {
      final room = await _chat.getOrCreateDirectRoom(friend.id);
      await _openRoom(room);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!designMode && _loading) {
      return const SizedBox.expand(child: LoadingView(message: 'Chat...'));
    }
    if (!designMode && _error != null) {
      return SizedBox.expand(child: ErrorView(message: _error!, onRetry: _load));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: designMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final room = await CreateChatRoomSheet.show(context);
                if (room != null) await _openRoom(room);
              },
              backgroundColor: YumeColors.primary,
              icon: const Icon(Icons.add_comment),
              label: const Text('Tạo phòng'),
            ),
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: YumeColors.homeGradient,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/hero-japan.png',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: YumeColors.pinkLight,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chat Moji',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            if (!designMode && _hubStatus.isNotEmpty)
                              Text(_hubStatus, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: _tabs.index == 0
                        ? 'Tìm bạn bè hoặc nhóm...'
                        : _tabs.index == 2
                            ? 'Tìm phòng $_myLevelCode...'
                            : 'Tìm phòng chat...',
                    prefixIcon: const Icon(Icons.search, color: YumeColors.muted),
                    filled: true,
                    fillColor: YumeColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabs,
                  labelColor: YumeColors.primary,
                  onTap: (_) => setState(() {}),
                  tabs: const [
                    Tab(text: 'Của tôi'),
                    Tab(text: 'Công khai'),
                    Tab(text: 'Theo level'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _mineTab(),
                    _roomList(_filterRooms(_publicRooms), joinFirst: true),
                    _levelTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mineTab() {
    final friends = _filterFriends(_friends);
    final groups = _filterRooms(_myGroups);

    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          _sectionHeader(
            title: 'Bạn bè',
            actionIcon: Icons.person_add_outlined,
            onAction: designMode
                ? null
                : () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
                    ),
          ),
          if (friends.isEmpty)
            const _SectionEmpty('Chưa có bạn bè. Bấm + để kết bạn.')
          else
            ...friends.map(_friendTile),
          const SizedBox(height: 16),
          _sectionHeader(
            title: 'Nhóm của tôi',
            actionIcon: Icons.group_add_outlined,
            onAction: designMode
                ? null
                : () async {
                    final room = await CreateChatRoomSheet.show(context);
                    if (room != null) await _openRoom(room);
                  },
          ),
          if (groups.isEmpty)
            const _SectionEmpty('Chưa có nhóm nào. Bấm Tạo phòng để lập nhóm chat.')
          else
            ...groups.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _roomTile(r, joinFirst: false),
                )),
        ],
      ),
    );
  }

  Widget _levelTab() {
    final code = _myLevelCode;
    final rooms = _filterRooms(_roomsForMyLevel);

    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          _LevelBanner(levelCode: code),
          const SizedBox(height: 12),
          if (rooms.isEmpty)
            _SectionEmpty(
              'Chưa có phòng $code trên server.\n'
              'Khi bạn thi lên ${nextLevelCode(_myLevelId) ?? 'cấp cao hơn'}, tab này sẽ hiện phòng tương ứng.',
            )
          else
            ...rooms.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _levelRoomTile(r, joinFirst: true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _levelRoomTile(ChatRoom r, {required bool joinFirst}) {
    return Material(
      color: YumeColors.card,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFEF3C7),
          child: Text(
            _myLevelCode,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
          ),
        ),
        title: Text(r.displayTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          r.description?.trim().isNotEmpty == true
              ? r.description!
              : 'Phòng chat dành cho học viên JLPT $_myLevelCode',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.login, color: YumeColors.primary),
        onTap: () => _openRoom(r, joinFirst: joinFirst),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: YumeColors.primary,
            ),
          ),
          const Spacer(),
          if (actionIcon != null && onAction != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(actionIcon, size: 22, color: YumeColors.primary),
              onPressed: onAction,
              tooltip: title,
            ),
        ],
      ),
    );
  }

  Widget _friendTile(FriendUser f) {
    final avatarUrl = buildImageUrl(f.avatarUrl);
    final initial = f.label.isNotEmpty ? f.label[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: YumeColors.card,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundColor: YumeColors.pinkLight,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                onBackgroundImageError: (_, __) {},
                child: avatarUrl.isEmpty
                    ? Text(
                        initial,
                        style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: f.isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            f.isOnline ? 'Đang hoạt động · @${f.username}' : '@${f.username}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chat_bubble_outline, color: YumeColors.primary),
          onTap: () => _openFriendChat(f),
        ),
      ),
    );
  }

  Widget _roomList(List<ChatRoom> rooms, {required bool joinFirst}) {
    if (rooms.isEmpty) {
      return const Center(child: Text('Chưa có phòng.', style: TextStyle(color: YumeColors.muted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _roomTile(rooms[i], joinFirst: joinFirst),
    );
  }

  Widget _roomTile(ChatRoom r, {required bool joinFirst}) {
    final title = r.displayTitle;
    return Material(
      color: YumeColors.card,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: YumeColors.pinkLight,
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(r.isGroup ? 'Nhóm của bạn' : (r.roomType ?? 'chat')),
        trailing: r.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: YumeColors.primary, borderRadius: BorderRadius.circular(12)),
                child: Text('${r.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
              )
            : const Icon(Icons.chevron_right, color: YumeColors.muted),
        onTap: () => _openRoom(r, joinFirst: joinFirst),
      ),
    );
  }
}

class _LevelBanner extends StatelessWidget {
  const _LevelBanner({required this.levelCode});

  final String levelCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            YumeColors.primary.withValues(alpha: 0.12),
            const Color(0xFFFEF3C7).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YumeColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              levelCode,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Phòng chat theo JLPT bạn đang học.\nThi lên cấp cao hơn sẽ thấy phòng mới (vd. N4, N3).',
              style: TextStyle(fontSize: 13, color: YumeColors.ink.withValues(alpha: 0.85), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(message, style: const TextStyle(color: YumeColors.muted, fontSize: 13, height: 1.4)),
    );
  }
}
