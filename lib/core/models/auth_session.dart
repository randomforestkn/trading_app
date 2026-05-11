import 'app_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.createdAt,
    this.accessToken,
    this.refreshToken,
    this.provider,
    this.expiresAt,
  });

  final AppUser user;
  final DateTime createdAt;
  final String? accessToken;
  final String? refreshToken;
  final String? provider;
  final DateTime? expiresAt;

  factory AuthSession.fromJson(Map<String, Object?> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, Object?>) {
      throw const FormatException('Auth session user is missing.');
    }

    return AuthSession(
      user: AppUser.fromJson(userJson),
      createdAt: DateTime.parse(json['createdAt'] as String),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      provider: json['provider'] as String?,
      expiresAt: json['expiresAt'] is String
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (provider != null) 'provider': provider,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }
}
