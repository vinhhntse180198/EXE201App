import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../utils/jlpt_levels.dart';
import '../utils/json_field.dart';
import 'api_client.dart';

class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  Future<List<dynamic>> fetchRoomCatalog() async {
    final data = await _api.get('/api/Chat/room-catalog');
    if (data is List) return data;
    return [];
  }

  Future<List<ChatRoom>> fetchMyRooms() async {
    final data = await _api.get('/api/Chat/rooms');
    return jsonApiMapList(data).map(ChatRoom.fromJson).toList();
  }

  Future<ChatRoom> getOrCreateDirectRoom(int peerUserId) async {
    final data = await _api.post(
      '/api/Chat/direct',
      body: {'peerUserId': peerUserId},
    );
    final map = jsonApiMap(data) ?? (data as Map<String, dynamic>);
    return ChatRoom.fromJson(map);
  }

  Future<List<ChatMessage>> fetchRoomMessages(int roomId) async {
    final data = await _api.get(
      '/api/Chat/rooms/$roomId/messages',
      query: {'page': '1', 'pageSize': '50'},
    );
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    }
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(ChatMessage.fromJson).toList();
    }
    return [];
  }

  Future<ChatMessage> sendMessage(int roomId, String content) async {
    final data = await _api.post(
      '/api/Chat/rooms/$roomId/messages',
      body: {'content': content},
    );
    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  Future<void> joinRoom(int roomId) async {
    await _api.post('/api/Chat/rooms/$roomId/join', body: {});
  }

  Future<List<ChatRoom>> fetchPublicRooms({
    String type = 'public',
    int? levelId,
    String? slug,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'type': type,
      'limit': '${limit.clamp(1, 100)}',
      if (levelId != null) 'levelId': '$levelId',
      if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
    };
    final data = await _api.get('/api/Chat/public-rooms', query: query);
    return jsonApiMapList(data).map(ChatRoom.fromJson).toList();
  }

  /// Phòng JLPT đúng level học viên (N5→levelId 1, N4→2, …).
  Future<List<ChatRoom>> fetchLevelRoomsForUser(int? userLevelId) async {
    final lid = userLevelId ?? 1;
    var rooms = await fetchPublicRooms(type: 'level', levelId: lid);
    if (rooms.isEmpty) {
      rooms = await fetchPublicRooms(type: 'level', slug: levelChatSlugFromId(lid));
    }
    return rooms.where((r) => r.levelId == null || r.levelId == lid).toList();
  }

  Future<ChatRoom> createRoom({
    required String name,
    required String type,
    String? description,
    int? levelId,
  }) async {
    final data = await _api.post(
      '/api/Chat/rooms',
      body: {
        'name': name,
        'type': type,
        if (description != null) 'description': description,
        if (levelId != null) 'levelId': levelId,
      },
    );
    return ChatRoom.fromJson(data as Map<String, dynamic>);
  }

  Future<ChatRoom> createModeratorSupportRoom() async {
    final data = await _api.post('/api/Chat/support/moderator');
    return ChatRoom.fromJson(data as Map<String, dynamic>);
  }

  Future<ChatRoom?> fetchRoom(int roomId) async {
    try {
      final data = await _api.get('/api/Chat/rooms/$roomId');
      if (data is Map<String, dynamic>) return ChatRoom.fromJson(data);
    } catch (_) {}
    return null;
  }

  Future<ChatMessage> addReaction(int roomId, int messageId, String emoji) async {
    final data = await _api.post(
      '/api/Chat/rooms/$roomId/messages/$messageId/reactions',
      body: {'emoji': emoji},
    );
    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  Future<void> removeReaction(int roomId, int messageId, String emoji) async {
    await _api.delete('/api/Chat/rooms/$roomId/messages/$messageId/reactions?emoji=$emoji');
  }
}
