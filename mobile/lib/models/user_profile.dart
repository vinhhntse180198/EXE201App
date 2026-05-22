import '../utils/json_field.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    this.isPremium = false,
    this.displayName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.dateOfBirth,
    this.theme,
  });

  final int userId;
  final bool isPremium;
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
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      theme: theme ?? this.theme,
    );
  }
}
