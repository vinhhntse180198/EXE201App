class ChatReaction {
  const ChatReaction({required this.emoji, required this.count, this.reactedByMe = false});

  final String emoji;
  final int count;
  final bool reactedByMe;

  factory ChatReaction.fromJson(Map<String, dynamic> json) {
    return ChatReaction(
      emoji: json['emoji'] as String? ?? '👍',
      count: json['count'] as int? ?? 1,
      reactedByMe: json['reactedByMe'] as bool? ?? json['ReactedByMe'] as bool? ?? false,
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
    this.reactions = const [],
  });

  final int id;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime? sentAt;
  final List<ChatReaction> reactions;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? sent;
    final raw = json['sentAt'] ?? json['createdAt'];
    if (raw is String) sent = DateTime.tryParse(raw);

    final rx = json['reactions'] ?? json['Reactions'];
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      senderId: json['senderId'] as int? ?? json['userId'] as int? ?? 0,
      senderName: json['senderName'] as String? ?? json['username'] as String? ?? 'User',
      content: json['content'] as String? ?? json['body'] as String? ?? '',
      sentAt: sent,
      reactions: rx is List
          ? rx.whereType<Map<String, dynamic>>().map(ChatReaction.fromJson).toList()
          : [],
    );
  }

  ChatMessage copyWith({List<ChatReaction>? reactions}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: sentAt,
      reactions: reactions ?? this.reactions,
    );
  }
}
