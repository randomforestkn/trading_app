import '../config/build_config.dart';
import '../utils/app_logger.dart';
import 'local_mock_market_repository.dart';
import 'market_api_client.dart';
import 'market_provider_config.dart';
import 'market_repository.dart';
import 'remote_market_repository.dart';

class MarketRepositoryFactory {
  const MarketRepositoryFactory._();

  static MarketRepository buildDefault() {
    final providerConfig = MarketProviderConfig.current;
    return build(
      useRemote: providerConfig.useRemoteMarketData,
      baseUrl: providerConfig.baseUrl,
      apiKey: providerConfig.apiKey,
      flavor: BuildConfig.current.flavor,
      providerConfig: providerConfig,
    );
  }

  static MarketRepository build({
    required bool useRemote,
    required String baseUrl,
    required String apiKey,
    AppFlavor? flavor,
    MarketProviderConfig? providerConfig,
  }) {
    final productionFlavor = flavor == AppFlavor.production;
    final hasConfig = baseUrl.isNotEmpty && apiKey.isNotEmpty;
    final resolvedProviderConfig =
        providerConfig ??
        MarketProviderConfig.fromValues(
          provider: 'twelvedata',
          useRemoteMarketData: useRemote,
          baseUrl: baseUrl,
          apiKey: apiKey,
        );

    if (useRemote && hasConfig) {
      return RemoteMarketRepository(
        apiClient: HttpMarketApiClient(providerConfig: resolvedProviderConfig),
      );
    }

    if (useRemote && !hasConfig) {
      AppLogger.warn(
        productionFlavor
            ? 'Production flavor requested remote market data without configuration; falling back to demo mode.'
            : 'Remote market data requested without configuration; falling back to demo mode.',
      );
    }

    return LocalMockMarketRepository();
  }
}
