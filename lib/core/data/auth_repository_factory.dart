import '../config/build_config.dart';
import '../utils/app_logger.dart';
import 'auth_api_client.dart';
import 'auth_provider_config.dart';
import 'auth_repository.dart';
import 'auth_store.dart';
import 'local_demo_auth_repository.dart';
import 'remote_auth_repository.dart';

class AuthRepositoryFactory {
  const AuthRepositoryFactory._();

  static AuthRepository buildDefault() {
    final providerConfig = AuthProviderConfig.current;
    return build(
      useRemote: providerConfig.useRemoteAuth,
      baseUrl: providerConfig.baseUrl,
      publicKey: providerConfig.publicKey,
      redirectUrl: providerConfig.redirectUrl,
      flavor: BuildConfig.current.flavor,
      providerConfig: providerConfig,
    );
  }

  static AuthRepository build({
    required bool useRemote,
    required String baseUrl,
    required String publicKey,
    required String redirectUrl,
    AppFlavor? flavor,
    AuthProviderConfig? providerConfig,
    AuthStore? store,
  }) {
    final hasConfig = baseUrl.isNotEmpty && publicKey.isNotEmpty;
    final productionFlavor = flavor == AppFlavor.production;
    final resolvedConfig =
        providerConfig ??
        AuthProviderConfig.fromValues(
          provider: 'supabase',
          useRemoteAuth: useRemote,
          baseUrl: baseUrl,
          publicKey: publicKey,
          redirectUrl: redirectUrl,
        );

    if (useRemote && hasConfig) {
      return RemoteAuthRepository(
        apiClient: HttpAuthApiClient(providerConfig: resolvedConfig),
        store: store ?? SharedPreferencesAuthStore(),
      );
    }

    if (useRemote && !hasConfig) {
      AppLogger.warn(
        productionFlavor
            ? 'Production flavor requested remote auth without configuration; falling back to demo auth.'
            : 'Remote auth requested without configuration; falling back to demo auth.',
      );
    }

    return LocalDemoAuthRepository(
      store: store ?? SharedPreferencesAuthStore(),
    );
  }
}
