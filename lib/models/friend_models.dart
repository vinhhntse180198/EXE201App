import '../utils/json_field.dart';

class FriendUser {
  const FriendUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
  });

  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isOnline;

  String get label {
    final d = displayName?.trim();
    if (d != null && d.isNotEmpty) return d;
    return username;
  }

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    final nested = json['friend'] ?? json['Friend'];
    if (nested is Map<String, dynamic>) {
      return FriendUser(
        id: jsonInt(nested, 'id') ?? jsonInt(nested, 'userId') ?? 0,
        username: jsonStr(nested, 'username') ?? '',
        displayName: jsonStr(nested, 'displayName'),
        avatarUrl: jsonStr(nested, 'avatarUrl'),
        isOnline: jsonBool(json, 'isOnline'),
      );
    }
    return FriendUser(
      id: jsonInt(json, 'id') ?? jsonInt(json, 'userId') ?? jsonInt(json, 'friendId') ?? 0,
      username: jsonStr(json, 'username') ?? '',
      displayName: jsonStr(json, 'displayName'),
      avatarUrl: jsonStr(json, 'avatarUrl'),
      isOnline: jsonBool(json, 'isOnline'),
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    this.createdAt,
  });

  final int id;
  final FriendUser fromUser;
  final FriendUser toUser;
  final String status;
  final DateTime? createdAt;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final from = json['fromUser'] ?? json['sender'] ?? json['from'];
    final to = json['toUser'] ?? json['receiver'] ?? json['to'];
    final created = jsonStr(json, 'createdAt');
    return FriendRequest(
      id: jsonInt(json, 'id') ?? 0,
      status: jsonStr(json, 'status') ?? 'pending',
      fromUser: from is Map<String, dynamic>
          ? FriendUser.fromJson(from)
          : const FriendUser(id: 0, username: ''),
      toUser: to is Map<String, dynamic>
          ? FriendUser.fromJson(to)
          : const FriendUser(id: 0, username: ''),
      createdAt: created != null ? DateTime.tryParse(created) : null,
    );
  }
}

class SocialComment {
  const SocialComment({
    required this.id,
    required this.content,
    required this.author,
    this.createdAt,
  });

  final int id;
  final String content;
  final FriendUser author;
  final DateTime? createdAt;

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? json['user'];
    final created = jsonStr(json, 'createdAt');
    return SocialComment(
      id: jsonInt(json, 'id') ?? 0,
      content: jsonStr(json, 'content') ?? '',
      author: author is Map<String, dynamic>
          ? FriendUser.fromJson(author)
          : const FriendUser(id: 0, username: ''),
      createdAt: created != null ? DateTime.tryParse(created) : null,
    );
  }
}
