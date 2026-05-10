class OnboardingProgress {
  const OnboardingProgress({
    required this.viewedVersion,
    required this.acceptedVersion,
    required this.viewedAt,
    required this.acceptedAt,
  });

  final int viewedVersion;
  final int acceptedVersion;
  final DateTime? viewedAt;
  final DateTime? acceptedAt;

  bool get isAccepted => acceptedVersion > 0 && acceptedAt != null;

  factory OnboardingProgress.fromJson(Map<String, Object?> json) {
    return OnboardingProgress(
      viewedVersion: (json['viewedVersion'] as num?)?.toInt() ?? 0,
      acceptedVersion: (json['acceptedVersion'] as num?)?.toInt() ?? 0,
      viewedAt: json['viewedAt'] == null
          ? null
          : DateTime.parse(json['viewedAt'] as String),
      acceptedAt: json['acceptedAt'] == null
          ? null
          : DateTime.parse(json['acceptedAt'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'viewedVersion': viewedVersion,
      'acceptedVersion': acceptedVersion,
      'viewedAt': viewedAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
    };
  }

  OnboardingProgress copyWith({
    int? viewedVersion,
    int? acceptedVersion,
    DateTime? viewedAt,
    DateTime? acceptedAt,
  }) {
    return OnboardingProgress(
      viewedVersion: viewedVersion ?? this.viewedVersion,
      acceptedVersion: acceptedVersion ?? this.acceptedVersion,
      viewedAt: viewedAt ?? this.viewedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
