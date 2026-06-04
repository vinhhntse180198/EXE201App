import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/friend_models.dart';
import '../../models/social_post.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../services/social_service.dart';
import '../../utils/image_url.dart';
import '../../utils/pick_image.dart';
import '../../utils/yume_links.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/social/sakura_feed_widgets.dart';

/// Bảng tin cộng đồng — layout Sakura responsive (mẫu Cộng đồng).
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _social = SocialService(AppSession.instance.api);
  final _profile = ProfileService(AppSession.instance.api);
  final _postController = TextEditingController();
  final _commentControllers = <int, TextEditingController>{};

  List<SocialPost> _posts = [];
  Map<int, List<SocialComment>> _commentsByPost = {};
  Map<int, String?> _activeReactions = {};
  UserProfile? _profileData;

  bool _loading = false;
  bool _creating = false;
  String? _error;
  Uint8List? _postImageBytes;
  String? _postImageName;

  @override
  void initState() {
    super.initState();
    if (!designMode) _load();
  }

  @override
  void dispose() {
    _postController.dispose();
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _avatarInitial {
    final n = _displayName.trim();
    if (n.isEmpty) return 'U';
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n[0].toUpperCase();
  }

  String get _displayName {
    final p = _profileData?.displayName;
    if (p != null && p.trim().isNotEmpty) return p.trim();
    final u = AppSession.instance.user?.user;
    if (u != null && u.username.isNotEmpty) return u.username;
    return 'Học viên';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _social.fetchFeed(),
        _profile.fetchMyProfile(),
      ]);
      final posts = results[0] as List<SocialPost>;
      final commentsMap = <int, List<SocialComment>>{};
      await Future.wait(
        posts.map((p) async {
          try {
            commentsMap[p.id] = await _social.fetchComments(p.id);
          } catch (_) {
            commentsMap[p.id] = [];
          }
        }),
      );
      if (mounted) {
        setState(() {
          _posts = posts;
          _commentsByPost = commentsMap;
          _profileData = results[1] as UserProfile;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPostImage() async {
    final picked = await pickImageWithSheet(context);
    if (picked == null) return;
    setState(() {
      _postImageBytes = picked.bytes;
      _postImageName = picked.filename;
    });
  }

  Future<void> _createPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty && _postImageBytes == null) return;
    setState(() => _creating = true);
    try {
      String? imageUrl;
      if (_postImageBytes != null && _postImageName != null) {
        imageUrl = await _profile.uploadImage(_postImageBytes!, _postImageName!);
      }
      final post = await _social.createPost(
        content: text.isEmpty ? null : text,
        imageUrl: imageUrl,
      );
      _postController.clear();
      if (mounted) {
        setState(() {
          _posts = [post, ..._posts];
          _commentsByPost[post.id] = [];
          _postImageBytes = null;
          _postImageName = null;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đăng được bài. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _toggleLike(SocialPost post) async {
    final current = _activeReactions[post.id] ?? post.myReactionEmoji;
    final optimistic = current != null ? null : '❤️';
    setState(() => _activeReactions[post.id] = optimistic);
    try {
      final counts = await _social.toggleReaction(post.id, emoji: '❤️');
      if (!mounted) return;
      setState(() {
        _posts = _posts
            .map((p) => p.id == post.id ? p.copyWith(reactionCounts: counts, myReactionEmoji: optimistic) : p)
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _activeReactions[post.id] = current);
    }
  }

  Future<void> _submitComment(int postId) async {
    final ctrl = _commentControllers.putIfAbsent(postId, TextEditingController.new);
    final content = ctrl.text.trim();
    if (content.isEmpty) return;
    try {
      final dto = await _social.addComment(postId, content);
      if (!mounted) return;
      setState(() {
        _commentsByPost[postId] = [...(_commentsByPost[postId] ?? []), dto];
        _posts = _posts
            .map((p) => p.id == postId ? p.copyWith(commentCount: p.commentCount + 1) : p)
            .toList();
      });
      ctrl.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không gửi được bình luận.')));
      }
    }
  }

  void _openComments(SocialPost post) {
    final ctrl = _commentControllers.putIfAbsent(post.id, TextEditingController.new);
    showSakuraCommentsSheet(
      context: context,
      comments: List.from(_commentsByPost[post.id] ?? []),
      inputController: ctrl,
      designMode: designMode,
      onSubmit: () => _submitComment(post.id),
    );
  }

  String _postAuthorName(SocialPost post) {
    final a = post.author;
    if (a.displayName != null && a.displayName!.trim().isNotEmpty) return a.displayName!.trim();
    return a.username;
  }

  String _postAuthorInitial(SocialPost post) {
    final n = _postAuthorName(post);
    if (n.isEmpty) return '?';
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final myAvatar = buildImageUrl(_profileData?.avatarUrl);
    return Scaffold(
      backgroundColor: YumeColors.surface,
      appBar: AppBar(
        title: const Text('Cộng đồng'),
        backgroundColor: YumeColors.surface,
        foregroundColor: YumeColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.facebook),
            tooltip: 'Fanpage Facebook',
            onPressed: () => openYumeFacebookPage(context),
          ),
          if (!designMode)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: _buildBody(myAvatar),
    );
  }

  Widget _buildBody(String myAvatar) {
    if (!designMode && _loading && _posts.isEmpty) {
      return const LoadingView(message: 'Đang tải bảng tin...');
    }
    if (!designMode && _error != null && _posts.isEmpty) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: designMode ? () async {} : _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SakuraFeedComposer(
            avatarUrl: myAvatar,
            avatarInitial: _avatarInitial,
            controller: _postController,
            onSubmit: _createPost,
            creating: _creating,
            onPickImage: _pickPostImage,
            onEmoji: (e) => _postController.text = '${_postController.text}$e',
            imagePreviewBytes: _postImageBytes,
            designMode: designMode,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (_posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Chưa có bài đăng. Hãy chia sẻ khoảnh khắc đầu tiên!', style: TextStyle(color: YumeColors.muted)),
              ),
            )
          else
            ..._posts.map((post) {
              final liked = (_activeReactions[post.id] ?? post.myReactionEmoji) != null;
              return SakuraFeedPostCard(
                post: post,
                authorName: _postAuthorName(post),
                authorAvatarUrl: buildImageUrl(post.author.avatarUrl),
                authorInitial: _postAuthorInitial(post),
                commentCount: (_commentsByPost[post.id]?.length ?? post.commentCount),
                liked: liked,
                onLike: () => _toggleLike(post),
                onComment: () => _openComments(post),
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chia sẻ — sắp ra mắt')));
                },
                designMode: designMode,
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
