import '../utils/json_field.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    this.isPremium = false,
    this.levelId,
    this.levelCode,
    this.exp = 0,
    this.xu = 0,
    this.displayName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.dateOfBirth,
    this.theme,
  });

  final int userId;
  final bool isPremium;
  final int? levelId;
  final String? levelCode;
  final int exp;
  final int xu;
  final String? displayName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? theme;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final dob = jsonField(json, 'dateOfBirth');
    return UserProfile(
      userId: jsonInt(json, 'userId') ?? jsonInt(json, 'id') ?? 0,
      isPremium: jsonBool(json, 'isPremium'),
      levelId: jsonInt(json, 'levelId'),
      levelCode: jsonStr(json, 'levelCode'),
      exp: jsonInt(json, 'exp') ?? 0,
      xu: jsonInt(json, 'xu') ?? 0,
      displayName: jsonStr(json, 'displayName'),
      avatarUrl: jsonStr(json, 'avatarUrl'),
      coverUrl: jsonStr(json, 'coverUrl'),
      bio: jsonStr(json, 'bio'),
      dateOfBirth: dob is String ? DateTime.tryParse(dob) : null,
      theme: jsonStr(json, 'theme'),
    );
  }

  UserProfile copyWith({
    int? userId,
    bool? isPremium,
    int? levelId,
    String? levelCode,
    int? exp,
    int? xu,
    String? displayName,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    DateTime? dateOfBirth,
    String? theme,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      isPremium: isPremium ?? this.isPremium,
      levelId: levelId ?? this.levelId,
      levelCode: levelCode ?? this.levelCode,
      exp: exp ?? this.exp,
      xu: xu ?? this.xu,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      theme: theme ?? this.theme,
    );
  }
}
