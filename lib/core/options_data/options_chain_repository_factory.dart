import '../config/build_config.dart';
import '../utils/app_logger.dart';
import 'local_manual_options_repository.dart';
import 'options_api_client.dart';
import 'options_chain_repository.dart';
import 'options_provider_config.dart';
import 'remote_options_chain_repository.dart';

class OptionsChainRepositoryFactory {
  const OptionsChainRepositoryFactory._();

  static OptionsChainRepository buildDefault() {
    final providerConfig = OptionsProviderConfig.current;
    return build(
      useRemote: providerConfig.useRemoteOptionsData,
      baseUrl: providerConfig.baseUrl,
      apiKey: providerConfig.apiKey,
      delayedMarketData: providerConfig.delayedMarketData,
      flavor: BuildConfig.current.flavor,
      providerConfig: providerConfig,
    );
  }

  static OptionsChainRepository build({
    required bool useRemote,
    required String baseUrl,
    required String apiKey,
    required bool delayedMarketData,
    AppFlavor? flavor,
    OptionsProviderConfig? providerConfig,
  }) {
    final productionFlavor = flavor == AppFlavor.production;
    final hasConfig = baseUrl.isNotEmpty && apiKey.isNotEmpty;
    final resolvedConfig =
        providerConfig ??
        OptionsProviderConfig.fromValues(
          provider: 'custom',
          useRemoteOptionsData: useRemote,
          baseUrl: baseUrl,
          apiKey: apiKey,
          delayedMarketData: delayedMarketData,
        );

    if (useRemote && hasConfig) {
      return RemoteOptionsChainRepository(
        apiClient: HttpOptionsApiClient(providerConfig: resolvedConfig),
      );
    }

    if (useRemote && !hasConfig) {
      AppLogger.warn(
        productionFlavor
            ? 'Production flavor requested remote options data without configuration; falling back to manual options input.'
            : 'Remote options data requested without configuration; falling back to manual options input.',
      );
    }

    return const LocalManualOptionsRepository();
  }
}
