class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, Object?> json) {
    final createdAtValue = json['createdAt'] as String?;
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      createdAt: createdAtValue == null
          ? DateTime.now()
          : DateTime.parse(createdAtValue),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
