import 'user.dart';

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.user,
    this.needsPlacementTest = false,
  });

  final String accessToken;
  final User user;
  final bool needsPlacementTest;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      needsPlacementTest: json['needsPlacementTest'] as bool? ?? false,
    );
  }

  AuthResponse copyWith({bool? needsPlacementTest}) {
    return AuthResponse(
      accessToken: accessToken,
      user: user,
      needsPlacementTest: needsPlacementTest ?? this.needsPlacementTest,
    );
  }
}
