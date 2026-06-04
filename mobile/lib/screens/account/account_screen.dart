import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../models/auth_response.dart';
import '../../models/friend_models.dart';
import '../../models/progress_summary.dart';
import '../../models/social_post.dart';
import '../../models/user.dart';
import '../../models/user_profile.dart';
import '../../services/learn_service.dart';
import '../../services/profile_service.dart';
import '../../services/social_service.dart';
import '../../utils/account_format.dart';
import '../../utils/image_url.dart';
import '../../utils/jlpt_levels.dart';
import '../../utils/pick_image.dart';
import '../../utils/yume_links.dart';
import '../../widgets/account/account_hanami_widgets.dart';
import '../../widgets/social/sakura_feed_widgets.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../auth/login_screen.dart';
import '../social/community_screen.dart';
import '../social/friends_screen.dart';
import '../upgrade/upgrade_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _profile = ProfileService(AppSession.instance.api);
  final _learn = LearnService(AppSession.instance.api);
  final _social = SocialService(AppSession.instance.api);
  final _feedKey = GlobalKey();
  final _scrollController = ScrollController();

  UserProfile? _profileData;
  ProgressSummary? _summary;
  List<SocialPost> _posts = [];
  Map<int, List<SocialComment>> _commentsByPost = {};
  final _commentControllers = <int, TextEditingController>{};
  Map<int, String?> _activeReactions = {};
  int? _friendsCount;

  bool _loading = false;
  String? _error;
  bool _loadingPosts = false;
  String? _postError;
  bool _creatingPost = false;
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  String _profileTab = 'info';
  final _postController = TextEditingController();
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
    _scrollController.dispose();
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  User get _sessionUser =>
      AppSession.instance.user?.user ??
      (designMode ? MockData.user : const User(id: 0, username: '—', email: '', role: 'Learner'));

  String get _displayName {
    final p = _profileData?.displayName;
    if (p != null && p.trim().isNotEmpty) return p.trim();
    final u = _sessionUser;
    if (u.username.isNotEmpty) return u.username;
    if (u.email.contains('@')) return u.email.split('@').first;
    return 'Học viên';
  }

  String get _avatarInitial {
    final n = _displayName.trim();
    if (n.isEmpty) return 'U';
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n[0].toUpperCase();
  }

  bool get _isPremium => _profileData?.isPremium ?? _sessionUser.isPremium;

  int? get _effectiveLevelId => _profileData?.levelId ?? _sessionUser.levelId;

  String get _levelCode {
    final fromProfile = _profileData?.levelCode?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile.toUpperCase();
    return levelCodeFromId(_effectiveLevelId);
  }

  int get _levelCompletionPct {
    final code = _levelCode;
    final row = _summary?.byLevel.where((l) => l.levelCode.toUpperCase() == code).firstOrNull;
    return (row?.completionPercent ?? 0).round().clamp(0, 100);
  }

  int get _accountExp {
    final u = _sessionUser.exp;
    final s = _summary?.exp ?? 0;
    return u > s ? u : s;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = _sessionUser.id;
      final results = await Future.wait([
        _profile.fetchMyProfile(),
        _learn.fetchProgressSummary(),
        _social.fetchFriendsCount(),
      ]);
      final profile = results[0] as UserProfile;
      _syncUserFieldsToSession(profile);
      if (mounted) {
        setState(() {
          _profileData = profile;
          _summary = results[1] as ProgressSummary;
          _friendsCount = results[2] as int;
        });
      }
      await _loadPosts(userId);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPosts(int userId) async {
    setState(() {
      _loadingPosts = true;
      _postError = null;
    });
    try {
      final mine = await _social.fetchMyPosts(userId);
      final commentsMap = <int, List<SocialComment>>{};
      await Future.wait(
        mine.map((p) async {
          try {
            commentsMap[p.id] = await _social.fetchComments(p.id);
          } catch (_) {
            commentsMap[p.id] = [];
          }
        }),
      );
      if (mounted) {
        setState(() {
          _posts = mine;
          _commentsByPost = commentsMap;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _postError = 'Không tải được bài đăng. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  void _syncUserFieldsToSession(UserProfile profile) {
    final session = AppSession.instance.user;
    if (session == null) return;
    AppSession.instance.applyAuth(AuthResponse(
      accessToken: session.accessToken,
      user: session.user.copyWith(
        isPremium: profile.isPremium,
        levelId: profile.levelId,
        exp: profile.exp > 0 ? profile.exp : session.user.exp,
        xu: profile.xu > 0 ? profile.xu : session.user.xu,
      ),
      needsPlacementTest: session.needsPlacementTest,
    ));
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await pickImageWithSheet(context);
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await _profile.uploadImage(picked.bytes, picked.filename);
      final updated = await _profile.updateMyProfile(avatarUrl: url);
      if (mounted) {
        setState(() => _profileData = updated.copyWith(isPremium: _profileData?.isPremium ?? updated.isPremium));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không upload được avatar: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickAndUploadCover() async {
    final picked = await pickImageWithSheet(context);
    if (picked == null) return;
    setState(() => _uploadingCover = true);
    try {
      final url = await _profile.uploadImage(picked.bytes, picked.filename);
      final updated = await _profile.updateMyProfile(coverUrl: url);
      if (mounted) {
        setState(() => _profileData = updated.copyWith(isPremium: _profileData?.isPremium ?? updated.isPremium));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tải được ảnh bìa: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _removeCover() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bỏ ảnh bìa?'),
        content: const Text('Dùng nền gradient mặc định thay cho ảnh bìa hiện tại.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bỏ ảnh bìa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final updated = await _profile.updateMyProfile(coverUrl: '');
      if (mounted) {
        setState(() => _profileData = updated.copyWith(isPremium: _profileData?.isPremium ?? updated.isPremium));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không xóa được ảnh bìa: $e')));
      }
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _profileData?.displayName ?? '');
    final bioCtrl = TextEditingController(text: _profileData?.bio ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Giới thiệu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    final displayName = nameCtrl.text.trim();
    final bio = bioCtrl.text.trim();
    nameCtrl.dispose();
    bioCtrl.dispose();
    if (saved != true) return;
    try {
      final updated = await _profile.updateMyProfile(displayName: displayName, bio: bio);
      if (mounted) {
        setState(() => _profileData = updated.copyWith(isPremium: _profileData?.isPremium ?? updated.isPremium));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
      }
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
    if (text.isEmpty && _postImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập nội dung hoặc chọn ảnh.')));
      return;
    }
    setState(() => _creatingPost = true);
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
          _commentsByPost = {post.id: [], ..._commentsByPost};
          _postImageBytes = null;
          _postImageName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không đăng được bài. Vui lòng thử lại.')));
      }
    } finally {
      if (mounted) setState(() => _creatingPost = false);
    }
  }

  Future<void> _deletePost(SocialPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài đăng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _social.deletePost(post.id);
      if (mounted) {
        setState(() {
          _posts = _posts.where((p) => p.id != post.id).toList();
          _commentsByPost.remove(post.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
      }
    }
  }

  Future<void> _toggleReaction(SocialPost post, String emoji) async {
    final current = _activeReactions[post.id] ?? post.myReactionEmoji;
    final optimistic = current == emoji ? null : emoji;
    setState(() => _activeReactions[post.id] = optimistic);
    try {
      final counts = await _social.toggleReaction(post.id, emoji: emoji);
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
        _commentsByPost = {
          ..._commentsByPost,
          postId: [...(_commentsByPost[postId] ?? []), dto],
        };
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

  void _openPostComments(SocialPost post) {
    final ctrl = _commentControllers.putIfAbsent(post.id, TextEditingController.new);
    showSakuraCommentsSheet(
      context: context,
      comments: _commentsByPost[post.id] ?? [],
      inputController: ctrl,
      designMode: designMode,
      onSubmit: () => _submitComment(post.id),
    );
  }

  void _scrollToFeed() {
    final ctx = _feedKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
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
    return Scaffold(
      backgroundColor: YumeColors.surface,
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: YumeColors.surface,
        foregroundColor: YumeColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.facebook),
            tooltip: 'Fanpage Facebook',
            onPressed: () => openYumeFacebookPage(context),
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Cộng đồng',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CommunityScreen()),
            ),
          ),
          if (!designMode)
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Tải lại', onPressed: _loading ? null : _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!designMode && _loading && _profileData == null) {
      return const LoadingView(message: 'Đang tải hồ sơ...');
    }
    if (!designMode && _error != null && _profileData == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final user = _sessionUser;
    final profile = designMode
        ? const UserProfile(userId: 1, displayName: 'Học viên mẫu', bio: 'Chế độ thiết kế', isPremium: true)
        : _profileData;
    final summary = designMode
        ? MockData.progressSummary
        : (_summary ?? const ProgressSummary(exp: 0, xu: 0, streakDays: 0, byLevel: []));
    final levelCode = _levelCode;
    final coverUrl = buildImageUrl(profile?.coverUrl);
    final avatarUrl = buildImageUrl(profile?.avatarUrl);
    final journeyAgg = aggregateLessonProgress(summary.byLevel);
    final memoryCells = buildMemoryLaneCells(
      posts: _posts,
      coverUrl: profile?.coverUrl ?? '',
      avatarUrl: profile?.avatarUrl ?? '',
    );

    return RefreshIndicator(
      color: YumeColors.primary,
      onRefresh: designMode ? () async {} : _load,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AccountProfileHeader(
            coverUrl: coverUrl,
            avatarUrl: avatarUrl,
            avatarInitial: _avatarInitial,
            displayName: _displayName,
            levelTitle: accountLevelTitle(levelCode),
            isPremium: _isPremium,
            profileTab: _profileTab,
            onTabChanged: (t) => setState(() => _profileTab = t),
            levelCode: levelCode,
            levelCompletionPct: _levelCompletionPct,
            progressLoading: !designMode && _loading,
            postsCount: _posts.length,
            loadingPosts: _loadingPosts,
            friendsCount: _friendsCount,
            onFriendsTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
            ),
            email: user.email,
            username: user.username,
            uploadingCover: _uploadingCover,
            onPickCover: _pickAndUploadCover,
            onRemoveCover: _removeCover,
            hasCover: profile?.coverUrl?.isNotEmpty ?? false,
            uploadingAvatar: _uploadingAvatar,
            onPickAvatar: _pickAndUploadAvatar,
            onEditProfile: _editProfile,
            designMode: designMode,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (profile?.bio != null && profile!.bio!.trim().isNotEmpty) ...[
                  Text(profile.bio!, style: const TextStyle(color: YumeColors.text)),
                  const SizedBox(height: 12),
                ],
                _actionsRow(),
                const SizedBox(height: 16),
                AccountProgressCard(
                  levelCode: levelCode,
                  levelCompletionPct: _levelCompletionPct,
                  progressLoading: !designMode && _loading,
                  journeyAgg: journeyAgg,
                  streakDays: summary.streakDays,
                  accountExp: _accountExp,
                ),
                const SizedBox(height: 12),
                AccountMemoryLane(
                  memoryCells: memoryCells,
                  loadingPosts: _loadingPosts,
                  onScrollToFeed: _scrollToFeed,
                ),
                const SizedBox(height: 16),
                SakuraFeedComposer(
                  avatarUrl: avatarUrl,
                  avatarInitial: _avatarInitial,
                  controller: _postController,
                  onSubmit: _createPost,
                  creating: _creatingPost,
                  onEmoji: (e) => _postController.text = '${_postController.text}$e',
                  onPickImage: _pickPostImage,
                  imagePreviewBytes: _postImageBytes,
                  hintText: 'Chia sẻ bài học hoặc khoảnh khắc…',
                  designMode: designMode,
                ),
                if (_postError != null) ...[
                  const SizedBox(height: 8),
                  Text(_postError!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                Row(
                  key: _feedKey,
                  children: const [
                    Text('Bài đăng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: YumeColors.ink)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingPosts)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (_posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Chưa có bài đăng. Hãy viết dòng đầu tiên!',
                      style: TextStyle(color: YumeColors.muted),
                    ),
                  )
                else
                  ..._posts.map((post) {
                    final liked = (_activeReactions[post.id] ?? post.myReactionEmoji) != null;
                    return SakuraFeedPostCard(
                      post: post,
                      authorName: _displayName,
                      authorAvatarUrl: avatarUrl,
                      authorInitial: _avatarInitial,
                      commentCount: (_commentsByPost[post.id]?.length ?? post.commentCount),
                      liked: liked,
                      onLike: () => _toggleReaction(post, '❤️'),
                      onComment: () => _openPostComments(post),
                      onShare: () {},
                      onDelete: () => _deletePost(post),
                      designMode: designMode,
                    );
                  }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const UpgradeScreen()),
            ),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: Text(
              _isPremium ? 'Quản lý Premium' : 'Nâng cấp Premium',
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(backgroundColor: YumeColors.primary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất', overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
