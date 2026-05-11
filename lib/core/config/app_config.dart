import '../data/market_repository.dart';
import 'build_config.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'ClearTrade';
  static const appVersionLabel = 'MVP Demo';
  static const appFlavorLabel = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'demo',
  );
  static const homeSubtitle = 'Paper trading workspace';
  static const useRemoteMarketData = bool.fromEnvironment(
    'USE_REMOTE_MARKET_DATA',
    defaultValue: false,
  );

  static const defaultStartingCash = 18420.55;
  static const maxMarketHistoryLength = 30;
  static const simulatedPriceMovementMin = -0.02;
  static const simulatedPriceMovementMax = 0.02;
  static const analyticsConcentrationThreshold = 0.40;
  static const insightsHighRiskRatingThreshold = 4;
  static const insightsRepeatedLossThreshold = 2;
  static const insightsPremiumConcentrationThreshold = 0.40;
  static const insightsExpirationClusterWindowDays = 14;
  static const insightsExpirationClusterThreshold = 3;

  static const paperTradingDisclaimer =
      'Paper trading only - no real money involved.';
  static const simulatedPricesDisclaimer =
      'Prices are simulated demo data and are not suitable for real trading decisions.';
  static const optionsRiskDisclaimer =
      'Options tools are educational calculators only and do not model broker execution.';
  static const insightsDisclaimer =
      'Insights are rule-based and educational only.';
  static const demoAuthDisclaimer =
      'Demo auth only - no real account is created.';
  static const legalDisclaimerVersion = 1;
  static const onboardingVersion = 1;
  static const supportContactPlaceholder =
      'support@cleartrade.example (placeholder)';
  static const supportUrlPlaceholder =
      'https://example.com/support (placeholder)';
  static const privacyPolicyUrlPlaceholder =
      'https://example.com/privacy (placeholder)';
  static const appPackageNamePlaceholder = 'com.example.cleartrade';
  static const androidApplicationIdPlaceholder = 'com.example.cleartrade';
  static const iosBundleIdPlaceholder = 'com.example.cleartrade';
  static const macosBundleIdPlaceholder = 'com.example.cleartrade';
  static const syncDisclaimer =
      'Cloud sync is not connected yet. Changes are tracked locally for future backend integration.';
  static const syncDiagnosticsLabel = 'Local-first sync';
  static const exportDisclaimer =
      'Exports stay local unless you manually share the generated file.';
  static const exportReportDisclaimer =
      'Reports are generated from local paper trading, journal, and options data.';
  static const importRestoreDisclaimer =
      'Restores replace local data on this device. Keep a backup before applying changes.';
  static const backupFormatVersion = 1;
  static const demoUserId = 'demo-user';
  static const demoUserEmail = 'demo@cleartrade.local';
  static const demoUserDisplayName = 'Demo Trader';
  static const journalStorageKey = 'journal_entries_v1';
  static const optionsPortfolioStorageKey = 'options_portfolio_v1';
  static const onboardingStorageKey = 'onboarding_progress_v1';

  static String marketModeLabel(MarketDataMode mode) {
    return switch (mode) {
      MarketDataMode.demo => 'Demo simulated prices',
      MarketDataMode.remote => 'Remote market data',
    };
  }

  static const _isRelease = bool.fromEnvironment('dart.vm.product');
  static const _isProfile = bool.fromEnvironment('dart.vm.profile');
  static const buildModeLabel = _isRelease
      ? 'Release'
      : _isProfile
      ? 'Profile'
      : 'Debug';
  static String get appBuildLabel => '$appVersionLabel · $buildModeLabel';
  static BuildConfig get buildConfig => BuildConfig.current;
}
