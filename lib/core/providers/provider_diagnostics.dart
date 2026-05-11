import '../config/build_config.dart';
import '../data/auth_provider_config.dart';
import '../data/market_provider_config.dart';
import '../options_data/options_provider_config.dart';
import '../sync/sync_provider_config.dart';

class ProviderReadiness {
  const ProviderReadiness({
    required this.title,
    required this.providerLabel,
    required this.modeLabel,
    required this.configPresenceLabel,
    required this.safeSummary,
    required this.isRemoteEnabled,
    required this.hasConfig,
  });

  final String title;
  final String providerLabel;
  final String modeLabel;
  final String configPresenceLabel;
  final String safeSummary;
  final bool isRemoteEnabled;
  final bool hasConfig;

  String get readinessLabel => isRemoteEnabled ? 'Ready' : 'Fallback';

  factory ProviderReadiness.fromMarket(MarketProviderConfig config) {
    return ProviderReadiness(
      title: 'Market',
      providerLabel: config.providerLabel,
      modeLabel: config.remoteModeLabel,
      configPresenceLabel: config.diagnosticsLabel,
      safeSummary: config.safeConfigSummary,
      isRemoteEnabled: config.isRemoteEnabled,
      hasConfig: config.hasRemoteConfig,
    );
  }

  factory ProviderReadiness.fromAuth(AuthProviderConfig config) {
    return ProviderReadiness(
      title: 'Auth',
      providerLabel: config.providerLabel,
      modeLabel: config.remoteModeLabel,
      configPresenceLabel: config.hasRemoteConfig ? 'Present' : 'Missing',
      safeSummary: config.safeConfigSummary,
      isRemoteEnabled: config.isRemoteEnabled,
      hasConfig: config.hasRemoteConfig,
    );
  }

  factory ProviderReadiness.fromSync(SyncProviderConfig config) {
    return ProviderReadiness(
      title: 'Sync',
      providerLabel: config.providerLabel,
      modeLabel: config.remoteModeLabel,
      configPresenceLabel: config.remoteConfigPresenceLabel,
      safeSummary: config.safeConfigSummary,
      isRemoteEnabled: config.isRemoteEnabled,
      hasConfig: config.hasRemoteConfig,
    );
  }

  factory ProviderReadiness.fromOptions(OptionsProviderConfig config) {
    return ProviderReadiness(
      title: 'Options',
      providerLabel: config.providerLabel,
      modeLabel: config.dataModeLabel,
      configPresenceLabel: config.configPresenceLabel,
      safeSummary: config.safeConfigSummary,
      isRemoteEnabled: config.isRemoteEnabled,
      hasConfig: config.hasRemoteConfig,
    );
  }
}

class ProviderDiagnostics {
  const ProviderDiagnostics({
    required this.buildConfig,
    required this.market,
    required this.auth,
    required this.sync,
    required this.options,
  });

  final BuildConfig buildConfig;
  final ProviderReadiness market;
  final ProviderReadiness auth;
  final ProviderReadiness sync;
  final ProviderReadiness options;

  factory ProviderDiagnostics.current() {
    return ProviderDiagnostics(
      buildConfig: BuildConfig.current,
      market: ProviderReadiness.fromMarket(MarketProviderConfig.current),
      auth: ProviderReadiness.fromAuth(AuthProviderConfig.current),
      sync: ProviderReadiness.fromSync(SyncProviderConfig.current),
      options: ProviderReadiness.fromOptions(OptionsProviderConfig.current),
    );
  }

  String get readinessSummary =>
      '${buildConfig.flavor.label} · ${market.modeLabel} · ${auth.modeLabel} · ${sync.modeLabel} · ${options.modeLabel}';
}
