enum AppFlavor { demo, staging, production }

extension AppFlavorX on AppFlavor {
  String get label => switch (this) {
    AppFlavor.demo => 'Demo',
    AppFlavor.staging => 'Staging',
    AppFlavor.production => 'Production',
  };
}

class BuildConfig {
  const BuildConfig({
    required this.flavor,
    required this.versionLabel,
    required this.buildLabel,
    required this.useRemoteMarketData,
    required this.marketApiBaseUrl,
    required this.marketApiKey,
    required this.supportUrl,
    required this.privacyPolicyUrl,
    required this.packageNamePlaceholder,
    required this.androidApplicationIdPlaceholder,
    required this.iosBundleIdPlaceholder,
    required this.macosBundleIdPlaceholder,
  });

  final AppFlavor flavor;
  final String versionLabel;
  final String buildLabel;
  final bool useRemoteMarketData;
  final String marketApiBaseUrl;
  final String marketApiKey;
  final String supportUrl;
  final String privacyPolicyUrl;
  final String packageNamePlaceholder;
  final String androidApplicationIdPlaceholder;
  final String iosBundleIdPlaceholder;
  final String macosBundleIdPlaceholder;

  static BuildConfig get current => BuildConfig.fromEnvironment();

  factory BuildConfig.fromEnvironment() {
    const flavorValue = String.fromEnvironment(
      'APP_FLAVOR',
      defaultValue: 'demo',
    );
    const versionLabel = String.fromEnvironment(
      'APP_VERSION_LABEL',
      defaultValue: 'MVP Demo',
    );
    const buildLabel = String.fromEnvironment(
      'APP_BUILD_LABEL',
      defaultValue: 'MVP Demo - Demo',
    );
    const useRemoteMarketData = bool.fromEnvironment(
      'USE_REMOTE_MARKET_DATA',
      defaultValue: false,
    );
    const marketApiBaseUrl = String.fromEnvironment('MARKET_API_BASE_URL');
    const marketApiKey = String.fromEnvironment('MARKET_API_KEY');
    const supportUrl = String.fromEnvironment(
      'APP_SUPPORT_URL',
      defaultValue: 'https://example.com/support (placeholder)',
    );
    const privacyPolicyUrl = String.fromEnvironment(
      'APP_PRIVACY_POLICY_URL',
      defaultValue: 'https://example.com/privacy (placeholder)',
    );

    return BuildConfig(
      flavor: parseFlavor(flavorValue),
      versionLabel: versionLabel,
      buildLabel: buildLabel,
      useRemoteMarketData: useRemoteMarketData,
      marketApiBaseUrl: marketApiBaseUrl,
      marketApiKey: marketApiKey,
      supportUrl: supportUrl,
      privacyPolicyUrl: privacyPolicyUrl,
      packageNamePlaceholder: 'com.example.cleartrade',
      androidApplicationIdPlaceholder: 'com.example.cleartrade',
      iosBundleIdPlaceholder: 'com.example.cleartrade',
      macosBundleIdPlaceholder: 'com.example.cleartrade',
    );
  }

  factory BuildConfig.fromValues({
    required String flavor,
    required String versionLabel,
    required String buildLabel,
    required bool useRemoteMarketData,
    required String marketApiBaseUrl,
    required String marketApiKey,
    required String supportUrl,
    required String privacyPolicyUrl,
    String packageNamePlaceholder = 'com.example.cleartrade',
    String androidApplicationIdPlaceholder = 'com.example.cleartrade',
    String iosBundleIdPlaceholder = 'com.example.cleartrade',
    String macosBundleIdPlaceholder = 'com.example.cleartrade',
  }) {
    return BuildConfig(
      flavor: parseFlavor(flavor),
      versionLabel: versionLabel,
      buildLabel: buildLabel,
      useRemoteMarketData: useRemoteMarketData,
      marketApiBaseUrl: marketApiBaseUrl,
      marketApiKey: marketApiKey,
      supportUrl: supportUrl,
      privacyPolicyUrl: privacyPolicyUrl,
      packageNamePlaceholder: packageNamePlaceholder,
      androidApplicationIdPlaceholder: androidApplicationIdPlaceholder,
      iosBundleIdPlaceholder: iosBundleIdPlaceholder,
      macosBundleIdPlaceholder: macosBundleIdPlaceholder,
    );
  }

  static AppFlavor parseFlavor(String value) {
    return switch (value.toLowerCase()) {
      'staging' => AppFlavor.staging,
      'production' => AppFlavor.production,
      _ => AppFlavor.demo,
    };
  }
}
