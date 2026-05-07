import 'app_user.dart';

class AuthSession {
  const AuthSession({required this.user, required this.createdAt});

  final AppUser user;
  final DateTime createdAt;

  factory AuthSession.fromJson(Map<String, Object?> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, Object?>) {
      throw const FormatException('Auth session user is missing.');
    }

    return AuthSession(
      user: AppUser.fromJson(userJson),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {'user': user.toJson(), 'createdAt': createdAt.toIso8601String()};
  }
}
