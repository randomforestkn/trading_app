enum OptionsProvider { tradier, polygon, twelvedata, custom }

extension OptionsProviderX on OptionsProvider {
  String get label => switch (this) {
    OptionsProvider.tradier => 'Tradier',
    OptionsProvider.polygon => 'Polygon',
    OptionsProvider.twelvedata => 'Twelve Data',
    OptionsProvider.custom => 'Custom',
  };

  static OptionsProvider parse(String value) {
    return switch (value.toLowerCase()) {
      'tradier' => OptionsProvider.tradier,
      'polygon' => OptionsProvider.polygon,
      'twelvedata' => OptionsProvider.twelvedata,
      'custom' => OptionsProvider.custom,
      _ => OptionsProvider.custom,
    };
  }
}

class OptionsProviderConfig {
  const OptionsProviderConfig({
    required this.provider,
    required this.useRemoteOptionsData,
    required this.baseUrl,
    required this.apiKey,
    required this.delayedMarketData,
  });

  final OptionsProvider provider;
  final bool useRemoteOptionsData;
  final String baseUrl;
  final String apiKey;
  final bool delayedMarketData;

  factory OptionsProviderConfig.fromEnvironment() {
    const providerValue = String.fromEnvironment(
      'OPTIONS_PROVIDER',
      defaultValue: 'custom',
    );
    const useRemoteOptionsData = bool.fromEnvironment(
      'USE_REMOTE_OPTIONS_DATA',
      defaultValue: false,
    );
    const baseUrl = String.fromEnvironment('OPTIONS_BASE_URL');
    const apiKey = String.fromEnvironment('OPTIONS_API_KEY');
    const delayedMarketData = bool.fromEnvironment(
      'OPTIONS_MARKET_DATA_DELAYED',
      defaultValue: true,
    );
    return OptionsProviderConfig(
      provider: OptionsProviderX.parse(providerValue),
      useRemoteOptionsData: useRemoteOptionsData,
      baseUrl: baseUrl,
      apiKey: apiKey,
      delayedMarketData: delayedMarketData,
    );
  }

  factory OptionsProviderConfig.fromValues({
    required String provider,
    required bool useRemoteOptionsData,
    required String baseUrl,
    required String apiKey,
    required bool delayedMarketData,
  }) {
    return OptionsProviderConfig(
      provider: OptionsProviderX.parse(provider),
      useRemoteOptionsData: useRemoteOptionsData,
      baseUrl: baseUrl,
      apiKey: apiKey,
      delayedMarketData: delayedMarketData,
    );
  }

  static OptionsProviderConfig get current =>
      OptionsProviderConfig.fromEnvironment();

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  bool get hasRemoteConfig => hasBaseUrl && hasApiKey;

  bool get isRemoteEnabled => useRemoteOptionsData && hasRemoteConfig;

  String get providerLabel => provider.label;

  String get dataModeLabel =>
      isRemoteEnabled ? 'Remote options data' : 'Manual options input';

  String get delayedDataLabel =>
      delayedMarketData ? 'Delayed quotes' : 'Real-time capable';

  String get configPresenceLabel => hasRemoteConfig ? 'Present' : 'Missing';

  String get safeConfigSummary {
    if (!hasRemoteConfig) {
      return 'Missing base URL or API key';
    }
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host;
    if (host == null || host.isEmpty) {
      return 'Configured';
    }
    return 'Configured for $host';
  }
}
