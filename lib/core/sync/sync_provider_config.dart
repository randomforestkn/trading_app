enum SyncProvider { supabase, firebase, laravel, custom }

extension SyncProviderX on SyncProvider {
  String get label => switch (this) {
    SyncProvider.supabase => 'Supabase',
    SyncProvider.firebase => 'Firebase',
    SyncProvider.laravel => 'Laravel',
    SyncProvider.custom => 'Custom',
  };

  static SyncProvider parse(String value) {
    return switch (value.toLowerCase()) {
      'firebase' => SyncProvider.firebase,
      'laravel' => SyncProvider.laravel,
      'custom' => SyncProvider.custom,
      _ => SyncProvider.supabase,
    };
  }
}

class SyncProviderConfig {
  const SyncProviderConfig({
    required this.provider,
    required this.useRemoteSync,
    required this.baseUrl,
    required this.publicKey,
    required this.namespace,
  });

  final SyncProvider provider;
  final bool useRemoteSync;
  final String baseUrl;
  final String publicKey;
  final String namespace;

  factory SyncProviderConfig.fromEnvironment() {
    const providerValue = String.fromEnvironment(
      'SYNC_PROVIDER',
      defaultValue: 'supabase',
    );
    const useRemoteSync = bool.fromEnvironment(
      'USE_REMOTE_SYNC',
      defaultValue: false,
    );
    const baseUrl = String.fromEnvironment('SYNC_BASE_URL');
    const publicKey = String.fromEnvironment('SYNC_PUBLIC_KEY');
    const namespace = String.fromEnvironment(
      'SYNC_NAMESPACE',
      defaultValue: 'cleartrade_demo',
    );
    return SyncProviderConfig(
      provider: SyncProviderX.parse(providerValue),
      useRemoteSync: useRemoteSync,
      baseUrl: baseUrl,
      publicKey: publicKey,
      namespace: namespace,
    );
  }

  factory SyncProviderConfig.fromValues({
    required String provider,
    required bool useRemoteSync,
    required String baseUrl,
    required String publicKey,
    required String namespace,
  }) {
    return SyncProviderConfig(
      provider: SyncProviderX.parse(provider),
      useRemoteSync: useRemoteSync,
      baseUrl: baseUrl,
      publicKey: publicKey,
      namespace: namespace,
    );
  }

  static SyncProviderConfig get current => SyncProviderConfig.fromEnvironment();

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;

  bool get hasPublicKey => publicKey.trim().isNotEmpty;

  bool get hasRemoteConfig => hasBaseUrl;

  bool get isRemoteEnabled => useRemoteSync && hasRemoteConfig;

  String get providerLabel => provider.label;

  String get remoteModeLabel => isRemoteEnabled ? 'Remote ready' : 'Local only';

  String get remoteConfigPresenceLabel =>
      hasRemoteConfig ? 'Present' : 'Missing';

  String get safeConfigSummary {
    if (!hasRemoteConfig) {
      return 'Missing base URL';
    }
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host;
    if (host == null || host.isEmpty) {
      return 'Configured';
    }
    return 'Configured for $host';
  }

  String get publicKeyPresenceLabel => hasPublicKey ? 'Present' : 'Missing';
}
