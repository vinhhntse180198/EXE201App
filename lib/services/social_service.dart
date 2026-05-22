import '../models/friend_models.dart';
import '../models/social_post.dart';
import '../utils/json_field.dart';
import 'api_client.dart';

class SocialService {
  SocialService(this._api);

  final ApiClient _api;

  Future<List<SocialPost>> fetchFeed({int limit = 50}) async {
    final data = await _api.get('/api/Social/posts', query: {'limit': '$limit'});
    return jsonApiMapList(data).map(SocialPost.fromJson).toList();
  }

  Future<List<SocialPost>> fetchMyPosts(int userId, {int limit = 50}) async {
    final all = await fetchFeed(limit: limit);
    return all.where((p) => p.author.id == userId).toList();
  }

  Future<SocialPost> createPost({String? content, String? imageUrl}) async {
    final data = await _api.post(
      '/api/Social/posts',
      body: {
        if (content != null && content.isNotEmpty) 'content': content,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
    );
    final map = jsonApiMap(data) ?? (data is Map<String, dynamic> ? data : <String, dynamic>{});
    return SocialPost.fromJson(map);
  }

  Future<void> deletePost(int postId) async {
    await _api.delete('/api/Social/posts/$postId');
  }

  Future<int> fetchFriendsCount() async {
    final list = await fetchFriends();
    return list.length;
  }

  Future<List<FriendUser>> fetchFriends() async {
    final data = await _api.get('/api/Social/friends');
    return jsonApiMapList(data).map(FriendUser.fromJson).toList();
  }

  Future<List<FriendUser>> searchUsers(String query) async {
    final data = await _api.get('/api/Social/users/search', query: {'q': query.trim()});
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(FriendUser.fromJson).toList();
  }

  Future<void> sendFriendRequest(int toUserId) async {
    await _api.post('/api/Social/friend-requests', body: {'toUserId': toUserId});
  }

  Future<List<FriendRequest>> fetchIncomingRequests() async {
    final data = await _api.get('/api/Social/friend-requests/incoming');
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(FriendRequest.fromJson).toList();
  }

  Future<List<FriendRequest>> fetchOutgoingRequests() async {
    final data = await _api.get('/api/Social/friend-requests/outgoing');
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(FriendRequest.fromJson).toList();
  }

  Future<void> acceptFriendRequest(int requestId) async {
    await _api.post('/api/Social/friend-requests/$requestId/accept');
  }

  Future<void> rejectFriendRequest(int requestId) async {
    await _api.post('/api/Social/friend-requests/$requestId/reject');
  }

  Future<void> cancelFriendRequest(int requestId) async {
    await _api.delete('/api/Social/friend-requests/$requestId');
  }

  Future<List<SocialComment>> fetchComments(int postId, {int limit = 50}) async {
    final data = await _api.get(
      '/api/Social/posts/$postId/comments',
      query: {'limit': '$limit'},
    );
    return jsonApiMapList(data).map(SocialComment.fromJson).toList();
  }

  Future<SocialComment> addComment(int postId, String content) async {
    final data = await _api.post(
      '/api/Social/posts/$postId/comments',
      body: {'content': content.trim()},
    );
    final map = jsonApiMap(data) ?? (data is Map<String, dynamic> ? data : <String, dynamic>{});
    return SocialComment.fromJson(map);
  }

  Future<Map<String, int>> toggleReaction(int postId, {required String emoji}) async {
    final data = await _api.post(
      '/api/Social/posts/$postId/reactions/toggle',
      body: {'emoji': emoji},
    );
    return SocialPost.parseReactionCounts(data);
  }

  Future<void> updatePresence({required String status}) async {
    await _api.post('/api/Social/presence', body: {'status': status});
  }
}
