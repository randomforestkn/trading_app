import '../data/market_repository.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'ClearTrade';
  static const appVersionLabel = 'MVP Demo';
  static const homeSubtitle = 'Paper trading workspace';

  static const defaultStartingCash = 18420.55;
  static const maxMarketHistoryLength = 30;
  static const simulatedPriceMovementMin = -0.02;
  static const simulatedPriceMovementMax = 0.02;

  static const paperTradingDisclaimer =
      'Paper trading only - no real money involved.';
  static const simulatedPricesDisclaimer =
      'Prices are simulated demo data and are not suitable for real trading decisions.';
  static const demoAuthDisclaimer =
      'Demo auth only - no real account is created.';
  static const demoUserId = 'demo-user';
  static const demoUserEmail = 'demo@cleartrade.local';
  static const demoUserDisplayName = 'Demo Trader';

  static String marketModeLabel(MarketDataMode mode) {
    return switch (mode) {
      MarketDataMode.demo => 'Demo simulated prices',
      MarketDataMode.remote => 'Remote market data',
    };
  }

  static String get buildModeLabel {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return 'Release';
    }
    if (const bool.fromEnvironment('dart.vm.profile')) {
      return 'Profile';
    }
    return 'Debug';
  }
}
