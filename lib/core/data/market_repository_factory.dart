import '../config/build_config.dart';
import '../utils/app_logger.dart';
import 'local_mock_market_repository.dart';
import 'market_api_client.dart';
import 'market_repository.dart';
import 'remote_market_repository.dart';

class MarketRepositoryFactory {
  const MarketRepositoryFactory._();

  static MarketRepository buildDefault() {
    return build(
      useRemote: BuildConfig.current.useRemoteMarketData,
      baseUrl: BuildConfig.current.marketApiBaseUrl,
      apiKey: BuildConfig.current.marketApiKey,
      flavor: BuildConfig.current.flavor,
    );
  }

  static MarketRepository build({
    required bool useRemote,
    required String baseUrl,
    required String apiKey,
    AppFlavor? flavor,
  }) {
    final productionFlavor = flavor == AppFlavor.production;
    final hasConfig = baseUrl.isNotEmpty && apiKey.isNotEmpty;

    if (useRemote && hasConfig) {
      return RemoteMarketRepository(
        apiClient: HttpMarketApiClient(baseUrl: baseUrl, apiKey: apiKey),
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
