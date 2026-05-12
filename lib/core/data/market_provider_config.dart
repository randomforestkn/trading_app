enum MarketProvider { twelvedata, finnhub }

extension MarketProviderX on MarketProvider {
  String get label => switch (this) {
    MarketProvider.twelvedata => 'Twelve Data',
    MarketProvider.finnhub => 'Finnhub',
  };

  String get value => switch (this) {
    MarketProvider.twelvedata => 'twelvedata',
    MarketProvider.finnhub => 'finnhub',
  };

  static MarketProvider parse(String value) {
    return switch (value.toLowerCase()) {
      'finnhub' => MarketProvider.finnhub,
      _ => MarketProvider.twelvedata,
    };
  }
}

class MarketProviderConfig {
  const MarketProviderConfig({
    required this.provider,
    required this.useRemoteMarketData,
    required this.baseUrl,
    required this.apiKey,
  });

  final MarketProvider provider;
  final bool useRemoteMarketData;
  final String baseUrl;
  final String apiKey;

  factory MarketProviderConfig.fromEnvironment() {
    const providerValue = String.fromEnvironment(
      'MARKET_API_PROVIDER',
      defaultValue: 'twelvedata',
    );
    const useRemoteMarketData = bool.fromEnvironment(
      'USE_REMOTE_MARKET_DATA',
      defaultValue: false,
    );
    const baseUrl = String.fromEnvironment('MARKET_API_BASE_URL');
    const apiKey = String.fromEnvironment('MARKET_API_KEY');
    return MarketProviderConfig(
      provider: MarketProviderX.parse(providerValue),
      useRemoteMarketData: useRemoteMarketData,
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }

  factory MarketProviderConfig.fromValues({
    required String provider,
    required bool useRemoteMarketData,
    required String baseUrl,
    required String apiKey,
  }) {
    return MarketProviderConfig(
      provider: MarketProviderX.parse(provider),
      useRemoteMarketData: useRemoteMarketData,
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }

  static MarketProviderConfig get current =>
      MarketProviderConfig.fromEnvironment();

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  bool get hasRemoteConfig => hasBaseUrl && hasApiKey;

  bool get isRemoteEnabled => useRemoteMarketData && hasRemoteConfig;

  bool get supportsBatchQuotes => false;

  bool get supportsHistoricalCandles => true;

  String get providerLabel => provider.label;

  String get remoteModeLabel =>
      isRemoteEnabled ? 'Remote market data' : 'Demo simulated prices';

  String get diagnosticsLabel =>
      '$providerLabel · ${hasRemoteConfig ? 'configured' : 'config missing'}';

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

  String get apiKeyPresenceLabel => hasApiKey ? 'Present' : 'Missing';
}
