import 'package:flutter/material.dart';
import 'dart:convert';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../services/moderation_service.dart';
import '../../utils/json_field.dart';
import '../../utils/jlpt_levels.dart';
import '../auth/login_screen.dart';
import '../../widgets/chat/chat_message_body.dart';
import '../../widgets/common/loading_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModeratorShell extends StatefulWidget {
  const ModeratorShell({super.key});

  @override
  State<ModeratorShell> createState() => _ModeratorShellState();
}

class _ModeratorShellState extends State<ModeratorShell> {
  final _mod = ModerationService(AppSession.instance.api);
  final _chat = ChatService(AppSession.instance.api);

  static const _kurenai = Color(0xFF8E031D);
  static const _kurenaiDeep = Color(0xFF6B0216);
  static const _cream = Color(0xFFFAF7F2);
  static const _prefsLogsKey = 'yumegoji_mod_internal_logs_v1';

  static const List<_ModTab> _tabs = [
    _ModTab(id: 'overview', label: 'Tổng quan', icon: '📊'),
    _ModTab(id: 'reports', label: 'Báo cáo & xử lý', icon: '🚩', badgeKey: 'pending'),
    _ModTab(id: 'chat', label: 'Giám sát chat', icon: '💬'),
    _ModTab(id: 'content', label: 'Bài học & nội dung', icon: '📚'),
    _ModTab(id: 'learners', label: 'Học viên', icon: '🎓', badgeKey: 'learners'),
    _ModTab(id: 'logs', label: 'Nhật ký nội bộ', icon: '📋'),
  ];

  String _tab = 'overview';

  Map<String, dynamic>? _overview;
  List<dynamic> _reports = [];
  List<dynamic> _learners = [];
  List<dynamic> _lessons = [];
  bool _loading = true;
  String? _loadError;

  String _reportTypeFilter = '';
  String _reportSeverityFilter = '';
  String _reportStatusFilter = 'open';
  bool _refreshingReports = false;

  final _lessonSearchCtrl = TextEditingController();
  bool _refreshingLessons = false;
  bool? _lessonPublishedFilter;

  // Chat monitor (web tab: ChatMonitorTab).
  final _roomIdCtrl = TextEditingController();
  bool _loadingRoom = false;
  bool _loadingChatRooms = false;
  bool _chatRoomsLoaded = false;
  String? _chatRoomsError;
  List<ChatRoom> _monitorRooms = [];
  int? _selectedRoomId;
  List<Map<String, dynamic>> _roomMembers = [];
  List<Map<String, dynamic>> _roomMessages = [];

  // Internal logs (web tab: LogsTab) — local only.
  final List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _restoreLogs();
    _load();
  }

  @override
  void dispose() {
    _lessonSearchCtrl.dispose();
    _roomIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _mod.fetchStaffOverview(),
        _mod.listReports(status: _mapReportStatusFilter(_reportStatusFilter)),
        _mod.listLearners(),
        _mod.listStaffLessonsPaged(page: 1, pageSize: 50),
      ]);
      if (mounted) {
        setState(() {
          _overview = results[0] as Map<String, dynamic>;
          _reports = results[1] as List<dynamic>;
          _learners = results[2] as List<dynamic>;
          _lessons = results[3] as List<dynamic>;
        });
      }
      _log('refresh', 'dashboard', 'Tải dữ liệu tổng quan.');
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsLogsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = <Map<String, dynamic>>[];
      for (final x in decoded) {
        if (x is Map) {
          restored.add(x.map((k, v) => MapEntry(k.toString(), v)));
        }
      }
      if (!mounted) return;
      setState(() {
        _logs
          ..clear()
          ..addAll(restored.take(200));
      });
    } catch (_) {
      // ignore corrupted local cache
    }
  }

  Future<void> _persistLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLogsKey, jsonEncode(_logs));
    } catch (_) {
      // ignore local storage failures
    }
  }

  void _log(String action, String target, [String? note]) {
    _logs.insert(0, {
      'at': DateTime.now().toIso8601String(),
      'action': action,
      'target': target,
      'note': note ?? '',
    });
    if (_logs.length > 200) _logs.removeRange(200, _logs.length);
    // Fire-and-forget local persistence.
    _persistLogs();
  }

  Future<void> _addManualLog() async {
    final ctrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thêm nhật ký'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Nhập nội dung bạn muốn ghi lại…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Lưu')),
          ],
        ),
      );
      if (ok != true) return;
      final text = ctrl.text.trim();
      if (text.isEmpty) return;
      setState(() {
        _logs.insert(0, {
          'at': DateTime.now().toIso8601String(),
          'action': 'note',
          'target': 'manual',
          'note': text,
        });
        if (_logs.length > 200) _logs.removeRange(200, _logs.length);
      });
      await _persistLogs();
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _reloadLessons() async {
    setState(() => _refreshingLessons = true);
    try {
      final items = await _mod.listStaffLessonsPaged(
        search: _lessonSearchCtrl.text.trim().isEmpty ? null : _lessonSearchCtrl.text.trim(),
        isPublished: _lessonPublishedFilter,
        page: 1,
        pageSize: 80,
      );
      if (mounted) setState(() => _lessons = items);
      _log('refresh', 'lessons', 'Làm mới danh sách bài học.');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _refreshingLessons = false);
    }
  }

  Future<void> _loadChatRoomsForMonitor() async {
    if (_loadingChatRooms) return;
    setState(() {
      _loadingChatRooms = true;
      _chatRoomsError = null;
    });
    try {
      final results = await Future.wait([
        _chat.fetchPublicRooms(type: 'public', limit: 100),
        _chat.fetchPublicRooms(type: 'level', limit: 100),
        _chat.fetchMyRooms(),
      ]);
      final seen = <int>{};
      final rooms = <ChatRoom>[];
      for (final batch in results) {
        for (final room in batch) {
          if (room.id > 0 && seen.add(room.id)) rooms.add(room);
        }
      }
      rooms.sort((a, b) => a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));

      if (!mounted) return;
      final selected = _selectedRoomId ?? (rooms.isNotEmpty ? rooms.first.id : null);
      setState(() {
        _monitorRooms = rooms;
        _selectedRoomId = selected;
        _chatRoomsLoaded = true;
        if (selected != null) _roomIdCtrl.text = '$selected';
      });
      if (selected != null) {
        await _loadRoom(selected, silent: true);
      }
    } catch (e) {
      if (mounted) setState(() => _chatRoomsError = '$e');
    } finally {
      if (mounted) setState(() => _loadingChatRooms = false);
    }
  }

  void _openChatTab() {
    setState(() => _tab = 'chat');
    if (!_chatRoomsLoaded) {
      _loadChatRoomsForMonitor();
    }
  }

  Future<void> _loadRoom(int? roomIdOverride, {bool silent = false}) async {
    final roomId = roomIdOverride ?? int.tryParse(_roomIdCtrl.text.trim());
    if (roomId == null || roomId <= 0) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chọn phòng hoặc nhập roomId hợp lệ.')));
      }
      return;
    }
    setState(() => _loadingRoom = true);
    try {
      final results = await Future.wait([
        _chat.fetchRoomMembers(roomId, includeOnline: true),
        _chat.fetchRoomMessagesCursor(roomId, limit: 50),
      ]);
      if (!mounted) return;
      final members = jsonApiMapList(results[0]);
      final msgPayload = results[1] is Map<String, dynamic>
          ? results[1] as Map<String, dynamic>
          : <String, dynamic>{'items': results[1]};
      final messages = jsonApiMapList(msgPayload);
      setState(() {
        _selectedRoomId = roomId;
        _roomIdCtrl.text = '$roomId';
        _roomMembers = members;
        _roomMessages = messages.reversed.toList();
      });
      _log('chat_monitor', 'room#$roomId', 'Tải ${members.length} members, ${messages.length} messages.');
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingRoom = false);
    }
  }

  String? _mapReportStatusFilter(String key) {
    switch (key) {
      case 'open':
        return 'open';
      case 'pending_admin_lock':
        return 'pending_admin_lock';
      case 'resolved':
        return 'resolved';
      case 'dismissed':
        return 'dismissed';
      default:
        return null;
    }
  }

  String? _mapReportTypeFilter(String key) {
    final v = key.trim().toLowerCase();
    if (v.isEmpty) return null;
    return v;
  }

  int? _mapReportSeverityFilter(String key) {
    final v = key.trim();
    if (v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null) return null;
    if (n < 1 || n > 3) return null;
    return n;
  }

  String _labelReportType(String? type) {
    final v = (type ?? '').trim().toLowerCase();
    switch (v) {
      case 'spam':
        return 'Spam';
      case 'profanity':
        return 'Ngôn ngữ thô tục';
      case 'harassment':
        return 'Quấy rối';
      case 'inappropriate':
        return 'Nội dung không phù hợp';
      case 'other':
        return 'Khác';
      default:
        return v.isEmpty ? '—' : v;
    }
  }

  String _labelSeverity(int? sev) {
    switch (sev) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return '—';
    }
  }

  Future<void> _reloadReports() async {
    setState(() => _refreshingReports = true);
    try {
      final items = await _mod.listReports(
        type: _mapReportTypeFilter(_reportTypeFilter),
        severity: _mapReportSeverityFilter(_reportSeverityFilter),
        status: _mapReportStatusFilter(_reportStatusFilter),
        limit: 100,
      );
      if (mounted) setState(() => _reports = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _refreshingReports = false);
    }
  }

  Future<void> _logout() async {
    await AppSession.instance.auth.logout();
    AppSession.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.instance.isLoggedIn) {
      return const LoginScreen();
    }

    final user = AppSession.instance.user?.user;
    final displayName = (user?.username.isNotEmpty == true
            ? user!.username
            : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'Điều hành viên'))
        .trim();
    final initials =
        (displayName.isEmpty ? 'M' : displayName).substring(0, (displayName.length >= 2 ? 2 : 1)).toUpperCase();
    final pendingCount =
        _reports.where((r) => (jsonStr(r as Map<String, dynamic>, 'status') ?? '').toLowerCase() == 'open').length;
    final learnerCount = _learners.length;

    return Scaffold(
      backgroundColor: _cream,
      drawer: _modDrawer(
        displayName: displayName,
        initials: initials,
        pendingCount: pendingCount,
        learnerCount: learnerCount,
      ),
      appBar: _topBar(),
      body: _loading
          ? const LoadingView(message: 'Moderator...')
          : SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(child: _washiBackground()),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) {
                          final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                          final slide = Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(fade);
                          return FadeTransition(
                            opacity: fade,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: _tabBody(key: ValueKey(_tab)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _topBar() {
    return AppBar(
      backgroundColor: _cream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: const Text('Moderator', style: TextStyle(fontWeight: FontWeight.w900, color: _kurenaiDeep)),
      ),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _load,
          icon: const Icon(Icons.refresh, color: _kurenaiDeep),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: _kurenaiDeep),
        ),
      ],
    );
  }

  Widget _washiBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cream,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _cream,
            Color.lerp(_cream, Colors.white, 0.7)!,
          ],
        ),
      ),
      child: CustomPaint(painter: _WashiPainter(accent: _kurenai)),
    );
  }

  Drawer _modDrawer({
    required String displayName,
    required String initials,
    required int pendingCount,
    required int learnerCount,
  }) {
    Widget navItem(_ModTab t) {
      final active = _tab == t.id;
      String? badge;
      if (t.badgeKey == 'pending') badge = pendingCount.toString();
      if (t.badgeKey == 'learners') badge = learnerCount.toString();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop();
            if (t.id == 'chat') {
              _openChatTab();
            } else {
              setState(() => _tab = t.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? Colors.white.withValues(alpha: 0.35) : Colors.transparent),
              boxShadow: active
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 10))]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(width: 24, child: Text(t.icon, textAlign: TextAlign.center)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: active ? _kurenai : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? _kurenai.withValues(alpha: 0.12) : _kurenai.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: active ? _kurenaiDeep : Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Drawer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF221A1C),
              Color(0xFF1A1214),
              Color(0xFF120E0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [_kurenai, Color(0xFFFB7185)]),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/yume-logo.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('Y', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YumeGo-Ji', style: TextStyle(color: Color(0xFFFFF7F7), fontWeight: FontWeight.w900, fontSize: 16)),
                          SizedBox(height: 2),
                          Text('Moderator', style: TextStyle(color: Color(0x99FEF2F2), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) => navItem(_tabs[i]),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [_kurenai, Color(0xFFFB7185)]),
                      ),
                      alignment: Alignment.center,
                      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFF7F7), fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('Điều hành viên', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBody({required Key key}) {
    if (_loadError != null && _tab == 'overview') {
      return _errorView(key: key, message: _loadError!, onRetry: _load);
    }
    switch (_tab) {
      case 'overview':
        return _panel(key: key, child: _overviewTab());
      case 'reports':
        return _panel(key: key, child: _reportsTab());
      case 'learners':
        return _panel(key: key, child: _learnersTab());
      case 'content':
        return _panel(key: key, child: _lessonsTab());
      case 'chat':
        return _panel(key: key, child: _chatTab());
      case 'logs':
        return _panel(key: key, child: _logsTab());
      default:
        return _panel(key: key, child: _overviewTab());
    }
  }

  Widget _panel({required Key key, required Widget child}) {
    return Card(
      key: key,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _kurenai.withValues(alpha: 0.12)),
      ),
      color: Colors.white.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }

  Widget _errorView({required Key key, required String message, required VoidCallback onRetry}) {
    return Card(
      key: key,
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _kurenai.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Không tải được dữ liệu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: YumeColors.muted, height: 1.35)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatTab() {
    if (!_chatRoomsLoaded && !_loadingChatRooms) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadChatRoomsForMonitor());
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Giám sát chat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: (_loadingRoom || _loadingChatRooms)
                  ? null
                  : () async {
                      await _loadChatRoomsForMonitor();
                    },
              icon: (_loadingRoom || _loadingChatRooms)
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('Tải'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loadingChatRooms)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_chatRoomsError != null) ...[
                  Text(_chatRoomsError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                if (_monitorRooms.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: _selectedRoomId,
                    decoration: const InputDecoration(
                      labelText: 'Chọn phòng chat',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _monitorRooms
                        .map(
                          (r) => DropdownMenuItem<int>(
                            value: r.id,
                            child: Text('#${r.id} · ${r.displayTitle}', overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: _loadingRoom
                        ? null
                        : (id) {
                            if (id == null) return;
                            setState(() => _selectedRoomId = id);
                            _loadRoom(id);
                          },
                  )
                else
                  TextField(
                    controller: _roomIdCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loadRoom(null),
                    decoration: const InputDecoration(
                      labelText: 'Room ID',
                      hintText: 'Nhập roomId nếu chưa có danh sách phòng',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                if (_monitorRooms.isEmpty && !_loadingChatRooms) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _roomIdCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loadRoom(null),
                    decoration: const InputDecoration(
                      labelText: 'Room ID (thủ công)',
                      hintText: 'Ví dụ: 1, 2, 3…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _pill('Members: ${_roomMembers.length}', const Color(0xFF7C3AED), bgAlpha: 0.12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _pill('Messages: ${_roomMessages.length}', const Color(0xFF059669), bgAlpha: 0.12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Thành viên', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (_loadingRoom && _roomMembers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_roomMembers.isEmpty)
          const Text('Chưa có dữ liệu. Chọn phòng và bấm Tải.', style: TextStyle(color: YumeColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _roomMembers.map((mm) {
              final name = (jsonStr(mm, 'displayName') ?? jsonStr(mm, 'username') ?? '—').trim();
              final uid = jsonInt(mm, 'userId') ?? jsonInt(mm, 'id');
              final online = jsonBool(mm, 'isOnline');
              final label = '@$name${uid != null ? ' (#$uid)' : ''}${online ? ' · online' : ''}';
              return _pill(label, online ? const Color(0xFF059669) : _kurenai, bgAlpha: 0.12);
            }).toList(),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text('Luồng tin gần đây', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            color: _cream.withValues(alpha: 0.6),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: _roomMessages.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chưa có tin nhắn.', style: TextStyle(color: YumeColors.muted)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _roomMessages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final msg = _roomMessages[i];
                      final sender = (jsonStr(msg, 'senderDisplayName') ??
                              jsonStr(msg, 'senderUsername') ??
                              jsonStr(msg, 'senderName') ??
                              '—')
                          .trim();
                      final body = (jsonStr(msg, 'content') ?? jsonStr(msg, 'message') ?? '').trim();
                      final mid = jsonInt(msg, 'id') ?? jsonInt(msg, 'messageId');
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@$sender${mid != null ? ' · msg#$mid' : ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(body.isEmpty ? '—' : body, style: const TextStyle(height: 1.35)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _logsTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Nhật ký nội bộ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _addManualLog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _logs.isEmpty
                  ? null
                  : () {
                      setState(_logs.clear);
                      _persistLogs();
                    },
              child: const Text('Xoá'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_logs.isEmpty)
          const Text('Chưa có log. Khi xử lý report / warning / monitor chat sẽ tự ghi lại ở đây.', style: TextStyle(color: YumeColors.muted))
        else
          ..._logs.map((e) {
            final at = (e['at'] as String?) ?? '';
            final action = (e['action'] as String?) ?? '—';
            final target = (e['target'] as String?) ?? '—';
            final note = (e['note'] as String?) ?? '';
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(action, style: const TextStyle(fontWeight: FontWeight.w900))),
                        Text(at.replaceFirst('T', ' ').split('.').first, style: const TextStyle(color: YumeColors.muted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(target, style: const TextStyle(fontWeight: FontWeight.w800, color: _kurenaiDeep)),
                    if (note.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(note, style: const TextStyle(color: YumeColors.muted, height: 1.35)),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _lessonsTab() {
    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: _reloadLessons,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bài học và nội dung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _refreshingLessons ? null : _reloadLessons,
                icon: _refreshingLessons
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _lessonSearchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _reloadLessons(),
                    decoration: InputDecoration(
                      labelText: 'Tìm bài học',
                      hintText: 'Nhập tiêu đề/slug…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _lessonSearchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _lessonSearchCtrl.clear();
                                _reloadLessons();
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _lessonPublishedFilter == null ? 'all' : (_lessonPublishedFilter! ? 'pub' : 'draft'),
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'pub', child: Text('Published')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    ],
                    onChanged: (v) async {
                      setState(() {
                        if (v == 'pub') {
                          _lessonPublishedFilter = true;
                        } else if (v == 'draft') {
                          _lessonPublishedFilter = false;
                        } else {
                          _lessonPublishedFilter = null;
                        }
                      });
                      await _reloadLessons();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Center(child: Text('Chưa có bài học (hoặc không khớp bộ lọc).', style: TextStyle(color: YumeColors.muted))),
            )
          else
            ..._lessons.map((l) {
              if (l is! Map<String, dynamic>) return const SizedBox.shrink();
              final id = jsonInt(l, 'id') ?? 0;
              final title = (jsonStr(l, 'title') ?? '—').trim();
              final slug = (jsonStr(l, 'slug') ?? '').trim();
              final levelId = jsonInt(l, 'levelId');
              final levelCode = levelCodeFromId(levelId);
              final published = (l['isPublished'] == true) || (l['IsPublished'] == true);

              Color badgeColor() {
                if (published) return const Color(0xFF059669);
                return const Color(0xFFB45309);
              }

              final bc = badgeColor();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (slug.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(slug, style: const TextStyle(color: YumeColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: bc.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            published ? 'Published' : 'Draft',
                            style: TextStyle(color: bc, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                        if (levelId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              levelCode,
                              style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'view') {
                        await _openLessonDetail(id, title);
                      } else if (v == 'delete') {
                        await _deleteLesson(id, title);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                  onTap: () => _openLessonDetail(id, title),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openLessonDetail(int lessonId, String title) async {
    if (lessonId == 0) return;
    try {
      final full = await _mod.fetchStaffLessonFull(lessonId);
      final lessonObj = (full['lesson'] ?? full['Lesson']);
      final lesson = (lessonObj is Map) ? Map<String, dynamic>.from(lessonObj) : full;

      String strVal(Map<String, dynamic> map, String key) {
        final camel = key[0].toUpperCase() + key.substring(1);
        final direct = map[key];
        final pascal = map[camel];
        final v = direct ?? pascal;
        if (v == null) return '';
        if (v is String) return v.trim();
        return v.toString().trim();
      }

      String firstString(Map<String, dynamic> map, List<String> keys) {
        for (final k in keys) {
          final s = strVal(map, k);
          if (s.isNotEmpty) return s;
        }
        return '';
      }

      int? intVal(Map<String, dynamic> map, String key) => jsonInt(map, key) ?? jsonInt(map, key[0].toUpperCase() + key.substring(1));
      bool? boolVal(Map<String, dynamic> map, String key) {
        final a = map[key];
        final b = map[key[0].toUpperCase() + key.substring(1)];
        final v = a ?? b;
        if (v is bool) return v;
        if (v is String) {
          final t = v.trim().toLowerCase();
          if (t == 'true') return true;
          if (t == 'false') return false;
        }
        return null;
      }

      final slug = firstString(lesson, ['slug', 'unit', 'code']);
      final levelId = intVal(lesson, 'levelId');
      final categoryId = intVal(lesson, 'categoryId');
      final categoryName = firstString(lesson, ['categoryName', 'category', 'categoryTitle']);
      final published = boolVal(lesson, 'isPublished');
      final contentHtml = firstString(lesson, [
        'content',
        'contentHtml',
        'html',
        'lessonHtml',
        'body',
        'text',
      ]);
      final contentText = contentHtml
          .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (slug.isNotEmpty) _pill(slug, YumeColors.muted, bgAlpha: 0.10),
                    if (published != null)
                      _pill(
                        published ? 'Published' : 'Draft',
                        published ? const Color(0xFF059669) : const Color(0xFFB45309),
                        bgAlpha: 0.14,
                      ),
                    if (levelId != null) _pill(levelCodeFromId(levelId), const Color(0xFF7C3AED), bgAlpha: 0.12),
                    if (categoryId != null)
                      _pill(
                        categoryName.isEmpty ? 'Category #$categoryId' : categoryName,
                        const Color(0xFF2563EB),
                        bgAlpha: 0.12,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nội dung bài học', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        if (contentText.isEmpty)
                          Text(
                            'Không có nội dung (Lesson.Content rỗng).',
                            style: TextStyle(color: YumeColors.muted.withValues(alpha: 0.9)),
                          )
                        else
                          SelectableText(
                            contentText,
                            style: const TextStyle(height: 1.45),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ExpansionTile(
                  title: const Text('Xem dữ liệu thô (JSON)', style: TextStyle(fontWeight: FontWeight.w800)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SelectableText(
                        full.toString(),
                        style: const TextStyle(fontSize: 12, color: YumeColors.muted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteLesson(int lessonId, String title) async {
    if (lessonId == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài học?'),
        content: Text('Bạn muốn xóa "$title" (ID $lessonId)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _mod.deleteStaffLesson(lessonId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bài học.')));
      await _reloadLessons();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _overviewTab() {
    final data = _overview ?? <String, dynamic>{};

    final pending = jsonInt(data, 'pendingCount') ?? 0;
    final resolvedToday = jsonInt(data, 'resolvedTodayCount') ?? 0;
    final dismissedToday = jsonInt(data, 'dismissedTodayCount') ?? 0;
    final newSinceYesterday = jsonInt(data, 'newSinceYesterdayCount') ?? 0;
    final registeredLearners = jsonInt(data, 'registeredLearnersCount') ?? 0;

    final trend = (data['trend'] is List) ? (data['trend'] as List) : const <dynamic>[];
    final monthlyTrend = (data['monthlyTrend'] is List) ? (data['monthlyTrend'] as List) : const <dynamic>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
      children: [
        Text(
          'Tổng quan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // Fix overflow on small screens by enforcing height.
            mainAxisExtent: 108,
          ),
          children: [
            _statCard(
              label: 'Pending',
              value: '$pending',
              icon: Icons.pending_actions,
              color: const Color(0xFFF59E0B),
            ),
            _statCard(
              label: 'New',
              value: '$newSinceYesterday',
              icon: Icons.fiber_new,
              color: const Color(0xFF2563EB),
              subtitle: '(since yesterday)',
            ),
            _statCard(
              label: 'Resolved',
              value: '$resolvedToday',
              icon: Icons.task_alt,
              color: const Color(0xFF16A34A),
              subtitle: 'today',
            ),
            _statCard(
              label: 'Dismissed',
              value: '$dismissedToday',
              icon: Icons.not_interested,
              color: const Color(0xFF64748B),
              subtitle: 'today',
            ),
            _statCard(
              label: 'Registered learners',
              value: '$registeredLearners',
              icon: Icons.people,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _trendSection(
          title: 'Trend theo ngày',
          items: trend,
          labelKeyPrimary: 'date',
          labelKeyFallback: 'Date',
        ),
        const SizedBox(height: 12),
        _trendSection(
          title: 'Trend theo tháng',
          items: monthlyTrend,
          labelKeyPrimary: 'monthLabel',
          labelKeyFallback: 'MonthLabel',
          secondaryLabelKeyPrimary: 'monthKey',
          secondaryLabelKeyFallback: 'MonthKey',
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.black.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (subtitle != null && subtitle.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: YumeColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendSection({
    required String title,
    required List<dynamic> items,
    required String labelKeyPrimary,
    required String labelKeyFallback,
    String? secondaryLabelKeyPrimary,
    String? secondaryLabelKeyFallback,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Chưa có dữ liệu.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black.withValues(alpha: 0.6)),
                ),
              )
            else
              ...items.take(12).map((x) {
                if (x is! Map<String, dynamic>) return const SizedBox.shrink();
                final primary = jsonStr(x, labelKeyPrimary) ?? jsonStr(x, labelKeyFallback) ?? '—';
                final secondary = (secondaryLabelKeyPrimary == null)
                    ? null
                    : (jsonStr(x, secondaryLabelKeyPrimary) ??
                        (secondaryLabelKeyFallback == null ? null : jsonStr(x, secondaryLabelKeyFallback)));

                final created = jsonInt(x, 'reportsCreated') ?? jsonInt(x, 'ReportsCreated') ?? 0;
                final resolved = jsonInt(x, 'reportsResolved') ?? jsonInt(x, 'ReportsResolved') ?? 0;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  primary,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (secondary != null && secondary.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      secondary,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.black.withValues(alpha: 0.55),
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _metricPill('Created', created, const Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          _metricPill('Resolved', resolved, const Color(0xFF16A34A)),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _reportsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Quản lý báo cáo & xử lý vi phạm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _refreshingReports ? null : _reloadReports,
                icon: _refreshingReports
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Tải lại'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 420;
                  final typeField = DropdownButtonFormField<String>(
                    value: _reportTypeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Loại',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả loại')),
                      DropdownMenuItem(value: 'spam', child: Text('Spam')),
                      DropdownMenuItem(value: 'profanity', child: Text('Ngôn ngữ thô tục')),
                      DropdownMenuItem(value: 'harassment', child: Text('Quấy rối')),
                      DropdownMenuItem(value: 'inappropriate', child: Text('Nội dung không phù hợp')),
                      DropdownMenuItem(value: 'other', child: Text('Khác')),
                    ],
                    onChanged: (v) async {
                      setState(() => _reportTypeFilter = v ?? '');
                      await _reloadReports();
                    },
                  );
                  final severityField = DropdownButtonFormField<String>(
                    value: _reportSeverityFilter,
                    decoration: const InputDecoration(
                      labelText: 'Mức độ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Mọi mức')),
                      DropdownMenuItem(value: '1', child: Text('Thấp')),
                      DropdownMenuItem(value: '2', child: Text('Trung bình')),
                      DropdownMenuItem(value: '3', child: Text('Cao')),
                    ],
                    onChanged: (v) async {
                      setState(() => _reportSeverityFilter = v ?? '');
                      await _reloadReports();
                    },
                  );
                  final statusField = DropdownButtonFormField<String>(
                    value: _reportStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(value: 'pending_admin_lock', child: Text('Pending lock')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
                    ],
                    onChanged: (v) async {
                      final next = v ?? 'open';
                      setState(() => _reportStatusFilter = next);
                      await _reloadReports();
                    },
                  );

                  if (narrow) {
                    return Column(
                      children: [
                        typeField,
                        const SizedBox(height: 10),
                        severityField,
                        const SizedBox(height: 10),
                        statusField,
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: typeField),
                          const SizedBox(width: 10),
                          Expanded(child: severityField),
                        ],
                      ),
                      const SizedBox(height: 10),
                      statusField,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            color: YumeColors.primary,
            onRefresh: _reloadReports,
            child: _reports.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    children: const [
                      Center(
                        child: Text(
                          'Chưa có báo cáo ở trạng thái này.',
                          style: TextStyle(color: YumeColors.muted),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                    itemCount: _reports.length,
                    itemBuilder: (_, i) {
                      final r = _reports[i];
                      if (r is! Map<String, dynamic>) return const SizedBox.shrink();
                      return _reportCard(r);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _reportCard(Map<String, dynamic> r) {
    final id = jsonInt(r, 'id') ?? 0;
    final status = (jsonStr(r, 'status') ?? '').toLowerCase();
    final type = jsonStr(r, 'type');
    final severity = jsonInt(r, 'severity');
    final desc = (jsonStr(r, 'description') ?? jsonStr(r, 'desc') ?? '').trim();

    final reportedUsername = jsonStr(r, 'reportedUsername') ?? jsonStr(r, 'reportedUser') ?? '';
    final reporterUsername = jsonStr(r, 'reporterUsername') ?? jsonStr(r, 'reporterUser') ?? '';
    final roomId = jsonInt(r, 'roomId');
    final messageId = jsonInt(r, 'messageId');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Report #$id',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                _statusPill(status),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Hành động',
                  onPressed: () => _openReportActions(r),
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1F0F172A)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _identityCard(
                          label: 'Bị báo cáo',
                          accent: const Color(0xFFDC2626),
                          username: reportedUsername.isEmpty ? '—' : '@$reportedUsername',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x1F0F172A)),
                        ),
                        child: const Center(
                          child: Text('⇄', style: TextStyle(color: YumeColors.muted, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _identityCard(
                          label: 'Người báo cáo',
                          accent: const Color(0xFF7C3AED),
                          username: reporterUsername.isEmpty ? '—' : '@$reporterUsername',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(
                  _labelReportType(type),
                  const Color(0xFFDC2626),
                  bgAlpha: 0.12,
                ),
                _pill(
                  'Mức: ${_labelSeverity(severity)}',
                  const Color(0xFFB45309),
                  bgAlpha: 0.16,
                ),
                _pill(
                  roomId != null ? 'Phòng #$roomId' : 'Phòng —',
                  const Color(0xFF7C3AED),
                  bgAlpha: 0.12,
                ),
                if (messageId != null)
                  _pill(
                    'msg #$messageId',
                    YumeColors.muted,
                    bgAlpha: 0.12,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              desc.isEmpty ? '—' : (desc.length > 140 ? '${desc.substring(0, 140)}…' : desc),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: YumeColors.muted, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openReportActions(r),
                    icon: const Icon(Icons.gavel_outlined, size: 18),
                    label: const Text('Hành động'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openReportDetails(r),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Chi tiết'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityCard({
    required String label,
    required Color accent,
    required String username,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.6), width: 4),
          top: BorderSide(color: const Color(0x1F0F172A)),
          right: BorderSide(color: const Color(0x1F0F172A)),
          bottom: BorderSide(color: const Color(0x1F0F172A)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, {double bgAlpha = 0.12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Widget _statusPill(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'resolved') return _pill('Đã xử lý', const Color(0xFF059669), bgAlpha: 0.16);
    if (s == 'dismissed') return _pill('Đã bỏ qua', YumeColors.muted, bgAlpha: 0.12);
    if (s == 'pending_admin_lock') return _pill('Pending lock', const Color(0xFFB45309), bgAlpha: 0.18);
    return _pill('Chờ xử lý', const Color(0xFFB45309), bgAlpha: 0.18);
  }

  Future<void> _openReportDetails(Map<String, dynamic> r) async {
    final id = jsonInt(r, 'id') ?? 0;
    final desc = (jsonStr(r, 'description') ?? '').trim();
    final type = jsonStr(r, 'type');
    final severity = jsonInt(r, 'severity');
    final status = jsonStr(r, 'status') ?? '';

    final reportedUsername = jsonStr(r, 'reportedUsername') ?? '';
    final reportedUserId = jsonInt(r, 'reportedUserId');
    final reporterUsername = jsonStr(r, 'reporterUsername') ?? '';
    final reporterId = jsonInt(r, 'reporterId');
    final roomId = jsonInt(r, 'roomId');
    final messageId = jsonInt(r, 'messageId');

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Chi tiết Report #$id', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(_labelReportType(type), const Color(0xFFDC2626), bgAlpha: 0.12),
                  _pill('Mức: ${_labelSeverity(severity)}', const Color(0xFFB45309), bgAlpha: 0.16),
                  _pill(status.isEmpty ? '—' : status, YumeColors.muted, bgAlpha: 0.12),
                  _pill(roomId != null ? 'Phòng #$roomId' : 'Phòng —', const Color(0xFF7C3AED), bgAlpha: 0.12),
                  if (messageId != null) _pill('msg #$messageId', YumeColors.muted, bgAlpha: 0.12),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tài khoản', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('Bị báo cáo: @${reportedUsername.isEmpty ? '—' : reportedUsername} (id: ${reportedUserId ?? '—'})'),
                      const SizedBox(height: 4),
                      Text('Người báo cáo: @${reporterUsername.isEmpty ? '—' : reporterUsername} (id: ${reporterId ?? '—'})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nội dung bị báo cáo', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(desc.isEmpty ? '—' : desc, style: const TextStyle(height: 1.35)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openReportActions(r);
                },
                icon: const Icon(Icons.gavel),
                label: const Text('Mở hành động'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReportActions(Map<String, dynamic> report) async {
    final id = jsonInt(report, 'id') ?? 0;
    if (id == 0) return;
    final noteCtrl = TextEditingController();
    String action = 'resolved';
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Report #$id'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: action,
                  decoration: const InputDecoration(labelText: 'Hành động', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'resolved', child: Text('Resolve')),
                    DropdownMenuItem(value: 'dismissed', child: Text('Dismiss')),
                    DropdownMenuItem(value: 'pending_admin_lock', child: Text('Escalate lock')),
                  ],
                  onChanged: (v) => action = v ?? 'resolved',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
            ],
          );
        },
      );
      if (ok != true) return;
      final note = noteCtrl.text.trim();
      if (action == 'pending_admin_lock') {
        await _mod.escalateLockRequest(id, resolutionNote: note.isEmpty ? null : note);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chuyển yêu cầu khoá lên Admin.')));
        _log('escalate_admin_lock', 'report#$id', note.isEmpty ? null : note);
      } else {
        await _mod.resolveReport(id, status: action, resolutionNote: note.isEmpty ? null : note);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật report.')));
        _log(action == 'dismissed' ? 'dismiss_report' : 'resolve_report', 'report#$id', note.isEmpty ? null : note);
      }
      await _reloadReports();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      noteCtrl.dispose();
    }
  }

  Widget _learnersTab() {
    Color levelColor(String? code) {
      switch ((code ?? '').toUpperCase()) {
        case 'N5':
          return const Color(0xFF059669);
        case 'N4':
          return const Color(0xFF2563EB);
        case 'N3':
          return const Color(0xFF7C3AED);
        case 'N2':
          return const Color(0xFFB45309);
        case 'N1':
          return const Color(0xFFDC2626);
        default:
          return YumeColors.muted;
      }
    }

    Widget levelBadge(String label, String? code) {
      final c = levelColor(code);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12)),
      );
    }

    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quản lý học viên',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_learners.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Center(child: Text('Chưa có học viên.', style: TextStyle(color: YumeColors.muted))),
            )
          else
            ..._learners.map((u) {
              if (u is! Map<String, dynamic>) return const SizedBox.shrink();
              final userId = jsonInt(u, 'id') ?? jsonInt(u, 'userId') ?? 0;
              final username = (jsonStr(u, 'username') ?? '').trim();
              final email = (jsonStr(u, 'email') ?? '').trim();
              final displayName = (jsonStr(u, 'displayName') ?? jsonStr(u, 'name') ?? '').trim();
              final joinedAt = (jsonStr(u, 'createdAt') ?? jsonStr(u, 'CreatedAt') ?? '').trim();

              final levelId = jsonInt(u, 'levelId');
              final levelCode = levelCodeFromId(levelId);
              final levelLabel = levelId == null ? 'Chưa xếp loại' : levelCode;

              final title = displayName.isNotEmpty ? displayName : (username.isNotEmpty ? username : 'User #$userId');

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: YumeColors.pinkLight,
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : '?',
                          style: const TextStyle(color: YumeColors.primary, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    switch (v) {
                                      case 'set_level':
                                        await _setLearnerLevel(userId, title, levelId);
                                        break;
                                      case 'warnings':
                                        await _showLearnerWarnings(userId, title);
                                        break;
                                      case 'issue_warning':
                                        await _issueWarning(userId, title);
                                        break;
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'set_level', child: Text('Chỉnh cấp độ')),
                                    PopupMenuItem(value: 'warnings', child: Text('Xem warnings')),
                                    PopupMenuItem(value: 'issue_warning', child: Text('Gửi warning')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (username.isNotEmpty)
                              Text('@$username', style: const TextStyle(color: YumeColors.muted, fontSize: 12)),
                            if (email.isNotEmpty)
                              Text(email, style: const TextStyle(color: YumeColors.muted, fontSize: 12)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                levelBadge(levelLabel, levelCode),
                                if (joinedAt.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Tham gia: $joinedAt',
                                      style: TextStyle(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _LearnerLegendDot(color: Color(0xFF059669), label: 'N5 — Sơ cấp'),
              _LearnerLegendDot(color: Color(0xFF2563EB), label: 'N4 — Trung cấp'),
              _LearnerLegendDot(color: Color(0xFF7C3AED), label: 'N3 — Nâng cao'),
              _LearnerLegendDot(color: YumeColors.muted, label: 'Chưa xếp loại'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setLearnerLevel(int userId, String username, int? currentLevelId) async {
    if (userId == 0) return;
    int? levelId = currentLevelId ?? 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Đổi level · $username'),
          content: DropdownButtonFormField<int>(
            value: levelId,
            decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 1, child: Text('N5 (1)')),
              DropdownMenuItem(value: 2, child: Text('N4 (2)')),
              DropdownMenuItem(value: 3, child: Text('N3 (3)')),
              DropdownMenuItem(value: 4, child: Text('N2 (4)')),
              DropdownMenuItem(value: 5, child: Text('N1 (5)')),
            ],
            onChanged: (v) => levelId = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Lưu')),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await _mod.setLearnerLevel(userId, levelId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật level.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showLearnerWarnings(int userId, String username) async {
    if (userId == 0) return;
    try {
      final items = await _mod.listWarningsForUser(userId);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Warnings · $username', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                if (items.isEmpty) const Text('Không có warnings.'),
                ...items.map((w) {
                  if (w is! Map<String, dynamic>) return const SizedBox.shrink();
                  final id = jsonInt(w, 'id') ?? 0;
                  final reason = jsonStr(w, 'reason') ?? '';
                  final createdAt = jsonStr(w, 'createdAt') ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Warning #$id'),
                      subtitle: Text([reason, createdAt].where((s) => s.isNotEmpty).join('\n')),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _issueWarning(int userId, String username, {int? reportId}) async {
    if (userId == 0) return;
    final ctrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Gửi warning · $username'),
            content: TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Lý do', border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Gửi')),
            ],
          );
        },
      );
      if (ok != true) return;
      final reason = ctrl.text.trim();
      if (reason.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập lý do.')));
        return;
      }
      await _mod.issueWarning(userId: userId, reason: reason, reportId: reportId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi warning.')));
      _log('issue_warning', 'user#$userId', reason);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      ctrl.dispose();
    }
  }

}

class _LearnerLegendDot extends StatelessWidget {
  const _LearnerLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: YumeColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ModTab {
  const _ModTab({required this.id, required this.label, required this.icon, this.badgeKey});

  final String id;
  final String label;
  final String icon;
  final String? badgeKey;
}

class _WashiPainter extends CustomPainter {
  const _WashiPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = Colors.white.withValues(alpha: 0.0);
    canvas.drawRect(Offset.zero & size, base);

    // subtle radial glow top
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.07),
          Colors.transparent,
        ],
        stops: const [0, 1],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, -size.height * 0.15), radius: size.width));
    canvas.drawRect(Offset.zero & size, glow);

    // repeating horizontal wash lines
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const gap = 3.0;
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WashiPainter oldDelegate) => oldDelegate.accent != accent;
}
