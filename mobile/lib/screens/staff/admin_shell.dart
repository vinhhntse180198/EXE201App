import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../services/admin_service.dart';
import '../../utils/json_field.dart';
import '../auth/login_screen.dart';
import '../../widgets/common/loading_view.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  final _admin = AdminService(AppSession.instance.api);
  late final TabController _tabs = TabController(length: 7, vsync: this);

  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _premiumConfig;
  List<dynamic> _users = [];
  List<dynamic> _games = [];
  List<dynamic> _lockRequests = [];
  List<dynamic> _premiumRequests = [];
  bool _loading = true;

  final _annTitle = TextEditingController();
  final _annBody = TextEditingController();
  String _annType = 'event';
  bool _annPublishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _annTitle.dispose();
    _annBody.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _admin.fetchOverview(),
        _admin.listUsers(),
        _admin.listGames(),
        _admin.listLockRequests(),
        _admin.listPremiumRequests(),
        _admin.getPremiumConfig(),
      ]);
      if (mounted) {
        setState(() {
          _overview = results[0] as Map<String, dynamic>;
          _users = results[1] as List<dynamic>;
          _games = results[2] as List<dynamic>;
          _lockRequests = results[3] as List<dynamic>;
          _premiumRequests = results[4] as List<dynamic>;
          _premiumConfig = results[5] as Map<String, dynamic>;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _publishAnnouncement() async {
    final title = _annTitle.text.trim();
    final content = _annBody.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tiêu đề và nội dung.')));
      return;
    }
    setState(() => _annPublishing = true);
    try {
      await _admin.publishAnnouncement(title: title, content: content, type: _annType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xuất bản thông báo.')));
        _annTitle.clear();
        _annBody.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _annPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: YumeColors.ink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Users'),
            Tab(text: 'Games'),
            Tab(text: 'Khóa TK'),
            Tab(text: 'Premium'),
            Tab(text: 'Payment'),
            Tab(text: 'Thông báo'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingView(message: 'Admin...')
          : TabBarView(
              controller: _tabs,
              children: [
                _overviewTab(),
                _listTab(_users, (u) {
                  if (u is! Map<String, dynamic>) return const SizedBox.shrink();
                  return ListTile(
                    title: Text(jsonStr(u, 'username') ?? '—'),
                    subtitle: Text('${jsonStr(u, 'role')} · ${jsonStr(u, 'email')}'),
                  );
                }),
                _listTab(_games, (g) {
                  if (g is! Map<String, dynamic>) return const SizedBox.shrink();
                  return ListTile(title: Text(jsonStr(g, 'name') ?? jsonStr(g, 'code') ?? 'Game'));
                }),
                _lockTab(),
                _premiumTab(),
                _paymentTab(),
                _announcementTab(),
              ],
            ),
    );
  }

  Widget _overviewTab() {
    final o = _overview ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: o.entries
          .map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value}')))
          .toList(),
    );
  }

  Widget _listTab(List<dynamic> items, Widget Function(dynamic) builder) {
    return ListView.builder(itemCount: items.length, itemBuilder: (_, i) => builder(items[i]));
  }

  Widget _lockTab() {
    return ListView.builder(
      itemCount: _lockRequests.length,
      itemBuilder: (_, i) {
        final r = _lockRequests[i];
        if (r is! Map<String, dynamic>) return const SizedBox.shrink();
        final id = jsonInt(r, 'id') ?? jsonInt(r, 'reportId') ?? 0;
        return ListTile(
          title: Text('Report #$id'),
          subtitle: Text(jsonStr(r, 'status') ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  await _admin.approveLockRequest(id);
                  await _load();
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  await _admin.rejectLockRequest(id);
                  await _load();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _premiumTab() {
    return ListView.builder(
      itemCount: _premiumRequests.length,
      itemBuilder: (_, i) {
        final r = _premiumRequests[i];
        if (r is! Map<String, dynamic>) return const SizedBox.shrink();
        final id = jsonInt(r, 'id') ?? 0;
        final user = jsonStr(r, 'username') ?? jsonStr(r, 'userName') ?? '';
        final amount = jsonInt(r, 'amountVnd') ?? jsonInt(r, 'AmountVnd');
        return ListTile(
          title: Text('Request #$id · $user'),
          subtitle: Text([
            jsonStr(r, 'status'),
            if (amount != null) '$amount VND',
          ].whereType<String>().join(' · ')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  await _admin.approvePremiumRequest(id);
                  await _load();
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  await _admin.rejectPremiumRequest(id, reason: 'Từ chối trên mobile');
                  await _load();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentTab() {
    final cfg = _premiumConfig ?? {};
    final price = jsonInt(cfg, 'premiumPriceVnd') ?? jsonInt(cfg, 'PremiumPriceVnd');
    final days = jsonInt(cfg, 'premiumDurationDays') ?? jsonInt(cfg, 'PremiumDurationDays');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text('Cấu hình Premium'),
            subtitle: Text('Giá: ${price ?? '—'} VND · Thời hạn: ${days ?? '—'} ngày'),
          ),
        ),
        const SizedBox(height: 8),
        Text('Yêu cầu thanh toán (${_premiumRequests.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ..._premiumRequests.map((r) {
          if (r is! Map<String, dynamic>) return const SizedBox.shrink();
          final id = jsonInt(r, 'id') ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('#$id'),
              subtitle: Text(jsonStr(r, 'status') ?? ''),
              trailing: FilledButton(
                onPressed: () async {
                  await _admin.approvePremiumRequest(id);
                  await _load();
                },
                child: const Text('Duyệt'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _announcementTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Xuất bản thông báo hệ thống', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(controller: _annTitle, decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
          controller: _annBody,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _annType,
          decoration: const InputDecoration(labelText: 'Loại', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'event', child: Text('Sự kiện')),
            DropdownMenuItem(value: 'maintenance', child: Text('Bảo trì')),
            DropdownMenuItem(value: 'promo', child: Text('Khuyến mãi')),
          ],
          onChanged: (v) => setState(() => _annType = v ?? 'event'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _annPublishing ? null : _publishAnnouncement,
          child: Text(_annPublishing ? 'Đang gửi...' : 'Publish'),
        ),
      ],
    );
  }
}
