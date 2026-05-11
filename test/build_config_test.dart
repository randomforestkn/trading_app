import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/config/build_config.dart';
import 'package:trading_app/core/data/auth_provider_config.dart';
import 'package:trading_app/core/data/local_mock_market_repository.dart';
import 'package:trading_app/core/data/market_repository_factory.dart';
import 'package:trading_app/core/data/market_provider_config.dart';
import 'package:trading_app/core/data/remote_market_repository.dart';
import 'package:trading_app/core/options_data/local_manual_options_repository.dart';
import 'package:trading_app/core/options_data/options_chain_repository_factory.dart';
import 'package:trading_app/core/options_data/options_provider_config.dart';
import 'package:trading_app/core/options_data/remote_options_chain_repository.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/sync_provider_config.dart';
import 'package:trading_app/core/sync/sync_repository_factory.dart';
import 'package:trading_app/core/sync/remote_sync_repository.dart';

void main() {
  test('default build config is demo/local-first', () {
    expect(AppConfig.appFlavorLabel, 'demo');
    expect(AppConfig.useRemoteMarketData, isFalse);
    expect(BuildConfig.current.flavor, AppFlavor.demo);
    expect(BuildConfig.current.buildLabel.isNotEmpty, isTrue);
    expect(MarketProviderConfig.current.provider, MarketProvider.twelvedata);
    expect(MarketProviderConfig.current.hasRemoteConfig, isFalse);
    expect(AuthProviderConfig.current.provider, AuthProvider.supabase);
    expect(AuthProviderConfig.current.hasRemoteConfig, isFalse);
    expect(SyncProviderConfig.current.provider, SyncProvider.supabase);
    expect(SyncProviderConfig.current.hasRemoteConfig, isFalse);
    expect(SyncProviderConfig.current.remoteModeLabel, 'Local only');
    expect(SyncProviderConfig.current.remoteConfigPresenceLabel, 'Missing');
    expect(OptionsProviderConfig.current.provider, OptionsProvider.custom);
    expect(OptionsProviderConfig.current.hasRemoteConfig, isFalse);
    expect(OptionsProviderConfig.current.dataModeLabel, 'Manual options input');
  });

  test('build config parser handles flavor and labels', () {
    final config = BuildConfig.fromValues(
      flavor: 'production',
      versionLabel: '2.0.1',
      buildLabel: '2.0.1 · 42',
      useRemoteMarketData: true,
      marketApiBaseUrl: 'https://example.com/api',
      marketApiKey: 'secret',
      supportUrl: 'https://example.com/support',
      privacyPolicyUrl: 'https://example.com/privacy',
    );

    expect(config.flavor, AppFlavor.production);
    expect(config.versionLabel, '2.0.1');
    expect(config.buildLabel, '2.0.1 · 42');
    expect(config.useRemoteMarketData, isTrue);
  });

  test('market repository falls back safely when remote config is missing', () {
    final repo = MarketRepositoryFactory.build(
      useRemote: true,
      baseUrl: '',
      apiKey: '',
      flavor: AppFlavor.production,
    );

    expect(repo, isA<LocalMockMarketRepository>());
  });

  test('market repository uses remote implementation when configured', () {
    final repo = MarketRepositoryFactory.build(
      useRemote: true,
      baseUrl: 'https://example.com/api',
      apiKey: 'secret',
      flavor: AppFlavor.staging,
    );

    expect(repo, isA<RemoteMarketRepository>());
  });

  test('market provider config parses values and defaults safely', () {
    final config = MarketProviderConfig.fromValues(
      provider: 'finnhub',
      useRemoteMarketData: true,
      baseUrl: 'https://finnhub.io/api/v1',
      apiKey: 'secret',
    );

    expect(config.provider, MarketProvider.finnhub);
    expect(config.useRemoteMarketData, isTrue);
    expect(config.hasRemoteConfig, isTrue);
    expect(config.providerLabel, 'Finnhub');
    expect(config.safeConfigSummary, contains('finnhub.io'));
  });

  test('missing provider config fails safely', () {
    final config = MarketProviderConfig.fromValues(
      provider: 'twelvedata',
      useRemoteMarketData: true,
      baseUrl: '',
      apiKey: '',
    );

    expect(config.hasRemoteConfig, isFalse);
    expect(config.isRemoteEnabled, isFalse);
    expect(config.safeConfigSummary, contains('Missing'));
  });

  test('auth provider config parses values and defaults safely', () {
    final config = AuthProviderConfig.fromValues(
      provider: 'firebase',
      useRemoteAuth: true,
      baseUrl: 'https://identitytoolkit.googleapis.com/v1',
      publicKey: 'public-key',
      redirectUrl: 'myapp://auth',
    );

    expect(config.provider, AuthProvider.firebase);
    expect(config.useRemoteAuth, isTrue);
    expect(config.hasRemoteConfig, isTrue);
    expect(config.providerLabel, 'Firebase');
    expect(config.safeConfigSummary, contains('googleapis.com'));
  });

  test('missing auth config falls back safely', () {
    final config = AuthProviderConfig.fromValues(
      provider: 'supabase',
      useRemoteAuth: true,
      baseUrl: '',
      publicKey: '',
      redirectUrl: '',
    );

    expect(config.hasRemoteConfig, isFalse);
    expect(config.isRemoteEnabled, isFalse);
    expect(config.safeConfigSummary, contains('Missing'));
  });

  test('sync provider config parses values and defaults safely', () {
    final config = SyncProviderConfig.fromValues(
      provider: 'laravel',
      useRemoteSync: true,
      baseUrl: 'https://sync.example.com',
      publicKey: '',
      namespace: 'cleartrade_demo',
    );

    expect(config.provider, SyncProvider.laravel);
    expect(config.useRemoteSync, isTrue);
    expect(config.hasRemoteConfig, isTrue);
    expect(config.isRemoteEnabled, isTrue);
    expect(config.providerLabel, 'Laravel');
    expect(config.remoteModeLabel, 'Remote ready');
    expect(config.safeConfigSummary, contains('sync.example.com'));
    expect(config.publicKeyPresenceLabel, 'Missing');
  });

  test('missing sync config falls back safely', () {
    final config = SyncProviderConfig.fromValues(
      provider: 'supabase',
      useRemoteSync: true,
      baseUrl: '',
      publicKey: '',
      namespace: 'cleartrade_demo',
    );

    expect(config.hasRemoteConfig, isFalse);
    expect(config.isRemoteEnabled, isFalse);
    expect(config.remoteModeLabel, 'Local only');
    expect(config.safeConfigSummary, contains('Missing'));
  });

  test('sync repository factory falls back safely without config', () {
    final repo = SyncRepositoryFactory.build(
      useRemote: true,
      baseUrl: '',
      publicKey: '',
      namespace: 'cleartrade_demo',
    );

    expect(repo, isA<LocalSyncRepository>());
  });

  test(
    'sync repository factory uses remote implementation when configured',
    () {
      final repo = SyncRepositoryFactory.build(
        useRemote: true,
        baseUrl: 'https://sync.example.com',
        publicKey: '',
        namespace: 'cleartrade_demo',
      );

      expect(repo, isA<RemoteSyncRepository>());
    },
  );

  test('options provider config parses values and defaults safely', () {
    final config = OptionsProviderConfig.fromValues(
      provider: 'tradier',
      useRemoteOptionsData: true,
      baseUrl: 'https://api.tradier.com',
      apiKey: 'secret',
      delayedMarketData: true,
    );

    expect(config.provider, OptionsProvider.tradier);
    expect(config.useRemoteOptionsData, isTrue);
    expect(config.hasRemoteConfig, isTrue);
    expect(config.isRemoteEnabled, isTrue);
    expect(config.providerLabel, 'Tradier');
    expect(config.dataModeLabel, 'Remote options data');
    expect(config.safeConfigSummary, contains('tradier.com'));
    expect(config.delayedDataLabel, 'Delayed quotes');
  });

  test('missing options config falls back safely', () {
    final config = OptionsProviderConfig.fromValues(
      provider: 'polygon',
      useRemoteOptionsData: true,
      baseUrl: '',
      apiKey: '',
      delayedMarketData: false,
    );

    expect(config.hasRemoteConfig, isFalse);
    expect(config.isRemoteEnabled, isFalse);
    expect(config.dataModeLabel, 'Manual options input');
    expect(config.safeConfigSummary, contains('Missing'));
  });

  test(
    'options repository factory falls back to manual input without config',
    () {
      final repo = OptionsChainRepositoryFactory.build(
        useRemote: true,
        baseUrl: '',
        apiKey: '',
        delayedMarketData: true,
      );

      expect(repo, isA<LocalManualOptionsRepository>());
    },
  );

  test(
    'options repository factory uses remote implementation when configured',
    () {
      final repo = OptionsChainRepositoryFactory.build(
        useRemote: true,
        baseUrl: 'https://api.tradier.com',
        apiKey: 'secret',
        delayedMarketData: true,
      );

      expect(repo, isA<RemoteOptionsChainRepository>());
    },
  );
}
