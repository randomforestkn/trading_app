import '../config/build_config.dart';
import '../utils/app_logger.dart';
import 'local_sync_repository.dart';
import 'remote_sync_repository.dart';
import 'sync_api_client.dart';
import 'sync_provider_config.dart';
import 'sync_repository.dart';
import 'sync_status.dart';

class SyncRepositoryFactory {
  const SyncRepositoryFactory._();

  static SyncRepository buildDefault({
    String? Function()? currentUserIdProvider,
  }) {
    final providerConfig = SyncProviderConfig.current;
    return build(
      useRemote: providerConfig.useRemoteSync,
      baseUrl: providerConfig.baseUrl,
      publicKey: providerConfig.publicKey,
      namespace: providerConfig.namespace,
      flavor: BuildConfig.current.flavor,
      providerConfig: providerConfig,
      currentUserIdProvider: currentUserIdProvider,
    );
  }

  static SyncRepository build({
    required bool useRemote,
    required String baseUrl,
    required String publicKey,
    required String namespace,
    AppFlavor? flavor,
    SyncProviderConfig? providerConfig,
    String? Function()? currentUserIdProvider,
  }) {
    final productionFlavor = flavor == AppFlavor.production;
    final hasConfig = baseUrl.isNotEmpty;
    final resolvedConfig =
        providerConfig ??
        SyncProviderConfig.fromValues(
          provider: 'supabase',
          useRemoteSync: useRemote,
          baseUrl: baseUrl,
          publicKey: publicKey,
          namespace: namespace,
        );

    if (useRemote && hasConfig) {
      return RemoteSyncRepository(
        apiClient: HttpSyncApiClient(providerConfig: resolvedConfig),
        currentUserIdProvider: currentUserIdProvider,
      );
    }

    if (useRemote && !hasConfig) {
      AppLogger.warn(
        productionFlavor
            ? 'Production flavor requested remote sync without configuration; falling back to local sync.'
            : 'Remote sync requested without configuration; falling back to local sync.',
      );
    }

    return LocalSyncRepository(syncMode: SyncMode.localOnly);
  }
}
