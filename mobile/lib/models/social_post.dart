import '../utils/json_field.dart';

class SocialPostAuthor {
  const SocialPostAuthor({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  factory SocialPostAuthor.fromJson(Map<String, dynamic> json) {
    return SocialPostAuthor(
      id: jsonInt(json, 'id') ?? 0,
      username: jsonStr(json, 'username') ?? '',
      displayName: jsonStr(json, 'displayName'),
      avatarUrl: jsonStr(json, 'avatarUrl'),
    );
  }
}

class SocialPost {
  const SocialPost({
    required this.id,
    this.content,
    this.imageUrl,
    this.isOwner = false,
    required this.createdAt,
    required this.author,
    this.commentCount = 0,
    this.reactionCount = 0,
    this.reactionCounts = const {},
    this.myReactionEmoji,
  });

  final int id;
  final String? content;
  final String? imageUrl;
  final bool isOwner;
  final DateTime createdAt;
  final SocialPostAuthor author;
  final int commentCount;
  final int reactionCount;
  final Map<String, int> reactionCounts;
  final String? myReactionEmoji;

  int get totalReactions {
    if (reactionCounts.isNotEmpty) {
      return reactionCounts.values.fold(0, (a, b) => a + b);
    }
    return reactionCount;
  }

  SocialPost copyWith({
    Map<String, int>? reactionCounts,
    String? myReactionEmoji,
    int? commentCount,
  }) {
    return SocialPost(
      id: id,
      content: content,
      imageUrl: imageUrl,
      isOwner: isOwner,
      createdAt: createdAt,
      author: author,
      commentCount: commentCount ?? this.commentCount,
      reactionCount: reactionCount,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      myReactionEmoji: myReactionEmoji ?? this.myReactionEmoji,
    );
  }

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final authorRaw = jsonField(json, 'author');
    final created = jsonField(json, 'createdAt');
    final reactionsRaw = jsonField(json, 'reactions');
    final counts = <String, int>{};
    String? mine;
    if (reactionsRaw is Map<String, dynamic>) {
      final c = reactionsRaw['counts'] ?? reactionsRaw['Counts'];
      if (c is Map) {
        c.forEach((key, val) {
          if (val is num) counts['$key'] = val.toInt();
        });
      }
      mine = jsonStr(reactionsRaw, 'myReaction') ?? jsonStr(reactionsRaw, 'userEmoji');
    }
    final totalFromCounts = counts.values.fold(0, (a, b) => a + b);
    return SocialPost(
      id: jsonInt(json, 'id') ?? 0,
      content: jsonStr(json, 'content'),
      imageUrl: jsonStr(json, 'imageUrl'),
      isOwner: jsonBool(json, 'isOwner'),
      createdAt: created is String ? DateTime.tryParse(created) ?? DateTime.now() : DateTime.now(),
      author: authorRaw is Map<String, dynamic>
          ? SocialPostAuthor.fromJson(authorRaw)
          : const SocialPostAuthor(id: 0, username: ''),
      commentCount: jsonInt(json, 'commentCount') ?? 0,
      reactionCount: totalFromCounts > 0 ? totalFromCounts : (jsonInt(json, 'likeCount') ?? 0),
      reactionCounts: counts,
      myReactionEmoji: mine,
    );
  }

  static Map<String, int> parseReactionCounts(dynamic data) {
    final counts = <String, int>{};
    if (data is! Map<String, dynamic>) return counts;
    final c = data['counts'] ?? data['Counts'];
    if (c is Map) {
      c.forEach((key, val) {
        if (val is num) counts['$key'] = val.toInt();
      });
    }
    return counts;
  }
}
