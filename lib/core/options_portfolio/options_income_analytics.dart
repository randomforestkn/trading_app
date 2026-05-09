import '../data/market_state.dart';
import '../strategies/option_strategy.dart';
import 'option_position.dart';
import 'option_trade.dart';
import 'options_portfolio_state.dart';

class OptionsIncomeAnalytics {
  const OptionsIncomeAnalytics({
    required this.totalPremiumCollected,
    required this.premiumCollectedThisMonth,
    required this.realizedOptionsProfitLoss,
    required this.openPremiumAtRisk,
    required this.averagePremiumPerTrade,
    required this.annualizedPremiumYieldAverage,
    required this.premiumByStrategy,
    required this.premiumByUnderlying,
    required this.openContractsCount,
    required this.upcomingExpirations,
    required this.assignmentsCount,
    required this.expiredWorthlessCount,
    required this.openPositionsCount,
    required this.latestUpdatedAt,
  });

  final double totalPremiumCollected;
  final double premiumCollectedThisMonth;
  final double realizedOptionsProfitLoss;
  final double openPremiumAtRisk;
  final double averagePremiumPerTrade;
  final double annualizedPremiumYieldAverage;
  final Map<OptionStrategy, double> premiumByStrategy;
  final Map<String, double> premiumByUnderlying;
  final int openContractsCount;
  final List<OptionPosition> upcomingExpirations;
  final int assignmentsCount;
  final int expiredWorthlessCount;
  final int openPositionsCount;
  final DateTime? latestUpdatedAt;

  static OptionsIncomeAnalytics fromState({
    required OptionsPortfolioState state,
    required MarketState marketState,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final openPositions = state.openPositions;
    final trades = state.trades;

    final openTrades = trades
        .where((trade) => trade.eventType == OptionTradeEventType.open)
        .toList(growable: false);
    final closedTrades = trades.where((trade) => trade.realizedPnl != null);

    final totalPremiumCollected = openTrades.fold<double>(
      0,
      (total, trade) => total + trade.premium,
    );
    final premiumCollectedThisMonth = openTrades
        .where((trade) => trade.createdAt.year == now.year)
        .where((trade) => trade.createdAt.month == now.month)
        .fold<double>(0, (total, trade) => total + trade.premium);
    final realizedOptionsProfitLoss = closedTrades.fold<double>(
      0,
      (total, trade) => total + (trade.realizedPnl ?? 0),
    );
    final openPremiumAtRisk = openPositions.fold<double>(
      0,
      (total, position) => total + position.totalPremium,
    );
    final averagePremiumPerTrade = openTrades.isEmpty
        ? 0.0
        : totalPremiumCollected / openTrades.length;
    final annualizedPremiumYieldAverage = openPositions.isEmpty
        ? 0.0
        : openPositions.fold<double>(
                0,
                (total, position) =>
                    total + position.annualizedPremiumYieldPercent(now),
              ) /
              openPositions.length;

    final premiumByStrategy = <OptionStrategy, double>{};
    final premiumByUnderlying = <String, double>{};
    for (final position in openPositions) {
      final strategy = position.linkedStrategy;
      if (strategy != null) {
        premiumByStrategy[strategy] =
            (premiumByStrategy[strategy] ?? 0) + position.totalPremium;
      }
      premiumByUnderlying[position.underlyingSymbol] =
          (premiumByUnderlying[position.underlyingSymbol] ?? 0) +
          position.totalPremium;
    }

    final upcomingExpirations = [...openPositions]
      ..sort(
        (left, right) => left.expirationDate.compareTo(right.expirationDate),
      );

    final assignmentsCount = state.allPositions
        .where((position) => position.status == OptionPositionStatus.assigned)
        .length;
    final expiredWorthlessCount = state.allPositions
        .where((position) => position.status == OptionPositionStatus.expired)
        .length;

    return OptionsIncomeAnalytics(
      totalPremiumCollected: totalPremiumCollected,
      premiumCollectedThisMonth: premiumCollectedThisMonth,
      realizedOptionsProfitLoss: realizedOptionsProfitLoss,
      openPremiumAtRisk: openPremiumAtRisk,
      averagePremiumPerTrade: averagePremiumPerTrade,
      annualizedPremiumYieldAverage: annualizedPremiumYieldAverage,
      premiumByStrategy: premiumByStrategy,
      premiumByUnderlying: premiumByUnderlying,
      openContractsCount: openPositions.fold<int>(
        0,
        (total, position) => total + position.contractsCount,
      ),
      upcomingExpirations: upcomingExpirations,
      assignmentsCount: assignmentsCount,
      expiredWorthlessCount: expiredWorthlessCount,
      openPositionsCount: openPositions.length,
      latestUpdatedAt: state.lastUpdated,
    );
  }
}
