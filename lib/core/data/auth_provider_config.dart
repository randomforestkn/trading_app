enum AuthProvider { supabase, firebase, laravel, custom }

extension AuthProviderX on AuthProvider {
  String get label => switch (this) {
    AuthProvider.supabase => 'Supabase',
    AuthProvider.firebase => 'Firebase',
    AuthProvider.laravel => 'Laravel',
    AuthProvider.custom => 'Custom',
  };

  static AuthProvider parse(String value) {
    return switch (value.toLowerCase()) {
      'firebase' => AuthProvider.firebase,
      'laravel' => AuthProvider.laravel,
      'custom' => AuthProvider.custom,
      _ => AuthProvider.supabase,
    };
  }
}

class AuthProviderConfig {
  const AuthProviderConfig({
    required this.provider,
    required this.useRemoteAuth,
    required this.baseUrl,
    required this.publicKey,
    required this.redirectUrl,
  });

  final AuthProvider provider;
  final bool useRemoteAuth;
  final String baseUrl;
  final String publicKey;
  final String redirectUrl;

  factory AuthProviderConfig.fromEnvironment() {
    const providerValue = String.fromEnvironment(
      'AUTH_PROVIDER',
      defaultValue: 'supabase',
    );
    const useRemoteAuth = bool.fromEnvironment(
      'USE_REMOTE_AUTH',
      defaultValue: false,
    );
    const baseUrl = String.fromEnvironment('AUTH_BASE_URL');
    const publicKey = String.fromEnvironment('AUTH_PUBLIC_KEY');
    const redirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL');
    return AuthProviderConfig(
      provider: AuthProviderX.parse(providerValue),
      useRemoteAuth: useRemoteAuth,
      baseUrl: baseUrl,
      publicKey: publicKey,
      redirectUrl: redirectUrl,
    );
  }

  factory AuthProviderConfig.fromValues({
    required String provider,
    required bool useRemoteAuth,
    required String baseUrl,
    required String publicKey,
    required String redirectUrl,
  }) {
    return AuthProviderConfig(
      provider: AuthProviderX.parse(provider),
      useRemoteAuth: useRemoteAuth,
      baseUrl: baseUrl,
      publicKey: publicKey,
      redirectUrl: redirectUrl,
    );
  }

  static AuthProviderConfig get current => AuthProviderConfig.fromEnvironment();

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;

  bool get hasPublicKey => publicKey.trim().isNotEmpty;

  bool get hasRemoteConfig => hasBaseUrl && hasPublicKey;

  bool get isRemoteEnabled => useRemoteAuth && hasRemoteConfig;

  String get providerLabel => provider.label;

  String get remoteModeLabel =>
      isRemoteEnabled ? 'Remote identity' : 'Demo auth';

  String get safeConfigSummary {
    if (!hasRemoteConfig) {
      return 'Missing base URL or public key';
    }
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host;
    if (host == null || host.isEmpty) {
      return 'Configured';
    }
    return 'Configured for $host';
  }

  String get publicKeyPresenceLabel => hasPublicKey ? 'Present' : 'Missing';

  String get redirectUrlPresenceLabel =>
      redirectUrl.trim().isEmpty ? 'Missing' : 'Present';
}
