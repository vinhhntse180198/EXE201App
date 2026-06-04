import '../utils/json_field.dart';

class ChatReaction {
  const ChatReaction({required this.emoji, required this.count, this.reactedByMe = false});

  final String emoji;
  final int count;
  final bool reactedByMe;

  factory ChatReaction.fromJson(Map<String, dynamic> json) {
    return ChatReaction(
      emoji: jsonStr(json, 'emoji') ?? '👍',
      count: jsonInt(json, 'count') ?? 1,
      reactedByMe: jsonBool(json, 'reactedByMe'),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.messageType = 'text',
    this.reactions = const [],
  });

  final int id;
  final int senderId;
  final String senderName;
  final String content;
  final String messageType;
  final DateTime? sentAt;
  final List<ChatReaction> reactions;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final map = _unwrapMessageMap(json);

    DateTime? sent;
    final raw = jsonField(map, 'sentAt') ?? jsonField(map, 'createdAt');
    if (raw is String) sent = DateTime.tryParse(raw);

    final rx = jsonField(map, 'reactions');
    return ChatMessage(
      id: jsonInt(map, 'id') ?? 0,
      senderId: jsonInt(map, 'userId') ?? jsonInt(map, 'senderId') ?? 0,
      senderName: _resolveSenderName(map),
      content: jsonStr(map, 'content') ?? jsonStr(map, 'body') ?? '',
      messageType: jsonStr(map, 'type') ?? 'text',
      sentAt: sent,
      reactions: rx is List
          ? rx.whereType<Map>().map((e) => ChatReaction.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
    );
  }

  static Map<String, dynamic> _unwrapMessageMap(Map<String, dynamic> json) {
    final wrapped = jsonField(json, 'message');
    if (wrapped is Map) return Map<String, dynamic>.from(wrapped);
    return json;
  }

  static String _resolveSenderName(Map<String, dynamic> json) {
    for (final key in ['senderDisplayName', 'senderUsername', 'senderName', 'username', 'displayName']) {
      final v = jsonStr(json, key);
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return 'Học viên';
  }

  ChatMessage copyWith({List<ChatReaction>? reactions}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      messageType: messageType,
      sentAt: sentAt,
      reactions: reactions ?? this.reactions,
    );
  }
}
