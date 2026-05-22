import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/friend_models.dart';
import '../../services/social_service.dart';
import '../../widgets/common/loading_view.dart';

/// Bạn bè & lời mời — khớp web social friends flows.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final _social = SocialService(AppSession.instance.api);
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _search = TextEditingController();

  List<FriendUser> _friends = [];
  List<FriendRequest> _incoming = [];
  List<FriendRequest> _outgoing = [];
  List<FriendUser> _searchResults = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _social.fetchFriends(),
        _social.fetchIncomingRequests(),
        _social.fetchOutgoingRequests(),
      ]);
      if (mounted) {
        setState(() {
          _friends = results[0] as List<FriendUser>;
          _incoming = results[1] as List<FriendRequest>;
          _outgoing = results[2] as List<FriendRequest>;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doSearch() async {
    final q = _search.text.trim();
    if (q.length < 2) return;
    final rows = await _social.searchUsers(q);
    if (mounted) setState(() => _searchResults = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Bạn (${_friends.length})'),
            Tab(text: 'Đến (${_incoming.length})'),
            Tab(text: 'Đi (${_outgoing.length})'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingView(message: 'Đang tải...')
          : TabBarView(
              controller: _tabs,
              children: [
                RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _search,
                                decoration: const InputDecoration(
                                  hintText: 'Tìm username...',
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(onPressed: _doSearch, icon: const Icon(Icons.search)),
                          ],
                        ),
                      ),
                      ..._searchResults.map((u) => ListTile(
                            title: Text(u.label),
                            subtitle: Text('@${u.username}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_add),
                              onPressed: () async {
                                await _social.sendFriendRequest(u.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã gửi lời mời')),
                                  );
                                }
                                await _reload();
                              },
                            ),
                          )),
                      const Divider(),
                      ..._friends.map((u) => ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(u.label),
                            subtitle: Text('@${u.username}'),
                          )),
                    ],
                  ),
                ),
                _requestList(_incoming, incoming: true),
                _requestList(_outgoing, incoming: false),
              ],
            ),
    );
  }

  Widget _requestList(List<FriendRequest> items, {required bool incoming}) {
    if (items.isEmpty) {
      return const Center(child: Text('Không có lời mời', style: TextStyle(color: YumeColors.muted)));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        final other = incoming ? r.fromUser : r.toUser;
        return ListTile(
          title: Text(other.label),
          subtitle: Text(r.status),
          trailing: incoming
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _social.acceptFriendRequest(r.id);
                        await _reload();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await _social.rejectFriendRequest(r.id);
                        await _reload();
                      },
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: () async {
                    await _social.cancelFriendRequest(r.id);
                    await _reload();
                  },
                ),
        );
      },
    );
  }
}
