import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/config/build_config.dart';
import 'package:trading_app/core/data/auth_provider_config.dart';
import 'package:trading_app/core/data/market_provider_config.dart';
import 'package:trading_app/core/options_data/options_provider_config.dart';
import 'package:trading_app/core/providers/provider_diagnostics.dart';
import 'package:trading_app/core/sync/sync_provider_config.dart';

void main() {
  test('demo mode shows local or fallback providers', () {
    final diagnostics = ProviderDiagnostics(
      buildConfig: BuildConfig.fromValues(
        flavor: 'demo',
        versionLabel: 'MVP Demo',
        buildLabel: 'MVP Demo - Demo',
        useRemoteMarketData: false,
        marketApiBaseUrl: '',
        marketApiKey: '',
        supportUrl: 'https://example.com/support',
        privacyPolicyUrl: 'https://example.com/privacy',
      ),
      market: ProviderReadiness.fromMarket(
        MarketProviderConfig.fromValues(
          provider: 'twelvedata',
          useRemoteMarketData: false,
          baseUrl: '',
          apiKey: '',
        ),
      ),
      auth: ProviderReadiness.fromAuth(
        AuthProviderConfig.fromValues(
          provider: 'supabase',
          useRemoteAuth: false,
          baseUrl: '',
          publicKey: '',
          redirectUrl: '',
        ),
      ),
      sync: ProviderReadiness.fromSync(
        SyncProviderConfig.fromValues(
          provider: 'supabase',
          useRemoteSync: false,
          baseUrl: '',
          publicKey: '',
          namespace: 'cleartrade_demo',
        ),
      ),
      options: ProviderReadiness.fromOptions(
        OptionsProviderConfig.fromValues(
          provider: 'custom',
          useRemoteOptionsData: false,
          baseUrl: '',
          apiKey: '',
          delayedMarketData: true,
        ),
      ),
    );

    expect(diagnostics.readinessSummary, contains('Demo'));
    expect(diagnostics.market.modeLabel, 'Demo simulated prices');
    expect(diagnostics.auth.modeLabel, 'Demo auth');
    expect(diagnostics.sync.modeLabel, 'Local only');
    expect(diagnostics.options.modeLabel, 'Manual options input');
  });

  test('remote provider configs are detected safely', () {
    final market = MarketProviderConfig.fromValues(
      provider: 'finnhub',
      useRemoteMarketData: true,
      baseUrl: 'https://finnhub.io/api/v1',
      apiKey: 'secret-market-key',
    );
    final auth = AuthProviderConfig.fromValues(
      provider: 'firebase',
      useRemoteAuth: true,
      baseUrl: 'https://identitytoolkit.googleapis.com/v1',
      publicKey: 'secret-auth-key',
      redirectUrl: 'myapp://auth',
    );
    final sync = SyncProviderConfig.fromValues(
      provider: 'laravel',
      useRemoteSync: true,
      baseUrl: 'https://sync.example.com',
      publicKey: 'secret-sync-key',
      namespace: 'cleartrade_demo',
    );
    final options = OptionsProviderConfig.fromValues(
      provider: 'tradier',
      useRemoteOptionsData: true,
      baseUrl: 'https://api.tradier.com',
      apiKey: 'secret-options-key',
      delayedMarketData: true,
    );

    final diagnostics = ProviderDiagnostics(
      buildConfig: BuildConfig.fromValues(
        flavor: 'staging',
        versionLabel: '1.0.0',
        buildLabel: '1.0.0 (42)',
        useRemoteMarketData: true,
        marketApiBaseUrl: market.baseUrl,
        marketApiKey: market.apiKey,
        supportUrl: 'https://example.com/support',
        privacyPolicyUrl: 'https://example.com/privacy',
      ),
      market: ProviderReadiness.fromMarket(market),
      auth: ProviderReadiness.fromAuth(auth),
      sync: ProviderReadiness.fromSync(sync),
      options: ProviderReadiness.fromOptions(options),
    );

    expect(diagnostics.market.configPresenceLabel, contains('configured'));
    expect(diagnostics.auth.configPresenceLabel, 'Present');
    expect(diagnostics.sync.configPresenceLabel, 'Present');
    expect(diagnostics.options.configPresenceLabel, 'Present');
    expect(
      diagnostics.market.safeSummary,
      isNot(contains('secret-market-key')),
    );
    expect(diagnostics.auth.safeSummary, isNot(contains('secret-auth-key')));
    expect(diagnostics.sync.safeSummary, isNot(contains('secret-sync-key')));
    expect(
      diagnostics.options.safeSummary,
      isNot(contains('secret-options-key')),
    );
  });
}
