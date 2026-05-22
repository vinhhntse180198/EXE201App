import '../utils/json_field.dart';

class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.levelId,
    this.exp = 0,
    this.xu = 0,
    this.isEmailVerified = false,
    this.isLocked = false,
    this.isPremium = false,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final int? levelId;
  final int exp;
  final int xu;
  final bool isEmailVerified;
  final bool isLocked;
  final bool isPremium;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: jsonInt(json, 'id') ?? 0,
      username: jsonStr(json, 'username') ?? '',
      email: jsonStr(json, 'email') ?? '',
      role: jsonStr(json, 'role') ?? 'Learner',
      levelId: jsonInt(json, 'levelId'),
      exp: jsonInt(json, 'exp') ?? 0,
      xu: jsonInt(json, 'xu') ?? 0,
      isEmailVerified: jsonBool(json, 'isEmailVerified'),
      isLocked: jsonBool(json, 'isLocked'),
      isPremium: jsonBool(json, 'isPremium'),
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    int? levelId,
    int? exp,
    int? xu,
    bool? isEmailVerified,
    bool? isLocked,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      levelId: levelId ?? this.levelId,
      exp: exp ?? this.exp,
      xu: xu ?? this.xu,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isLocked: isLocked ?? this.isLocked,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
