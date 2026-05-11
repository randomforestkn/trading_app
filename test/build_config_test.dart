import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/config/build_config.dart';
import 'package:trading_app/core/data/local_mock_market_repository.dart';
import 'package:trading_app/core/data/market_repository_factory.dart';
import 'package:trading_app/core/data/remote_market_repository.dart';

void main() {
  test('default build config is demo/local-first', () {
    expect(AppConfig.appFlavorLabel, 'demo');
    expect(AppConfig.useRemoteMarketData, isFalse);
    expect(BuildConfig.current.flavor, AppFlavor.demo);
    expect(BuildConfig.current.buildLabel.isNotEmpty, isTrue);
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
}
