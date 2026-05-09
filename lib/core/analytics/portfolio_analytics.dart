import '../config/app_config.dart';
import '../data/market_state.dart';
import '../data/paper_trading_state.dart';
import '../models/asset.dart';

class PortfolioAllocation {
  const PortfolioAllocation({
    required this.asset,
    required this.quantity,
    required this.marketValue,
    required this.weightPercent,
    required this.unrealizedProfitLoss,
    required this.unrealizedProfitLossPercent,
  });

  final TradingAsset asset;
  final double quantity;
  final double marketValue;
  final double weightPercent;
  final double unrealizedProfitLoss;
  final double unrealizedProfitLossPercent;
}

class PortfolioAnalytics {
  const PortfolioAnalytics({
    required this.totalPortfolioValue,
    required this.cashBalance,
    required this.investedValue,
    required this.unrealizedProfitLoss,
    required this.unrealizedProfitLossPercent,
    required this.realizedProfitLoss,
    required this.totalProfitLoss,
    required this.returnPercent,
    required this.cashAllocationPercent,
    required this.investedAllocationPercent,
    required this.openPositionsCount,
    required this.concentrationRiskPercent,
    required this.hasConcentrationWarning,
    required this.largestPosition,
    required this.bestPosition,
    required this.worstPosition,
    required this.allocationByAsset,
    required this.startingCash,
  });

  final double totalPortfolioValue;
  final double cashBalance;
  final double investedValue;
  final double unrealizedProfitLoss;
  final double unrealizedProfitLossPercent;
  final double realizedProfitLoss;
  final double totalProfitLoss;
  final double returnPercent;
  final double cashAllocationPercent;
  final double investedAllocationPercent;
  final int openPositionsCount;
  final double concentrationRiskPercent;
  final bool hasConcentrationWarning;
  final PortfolioAllocation? largestPosition;
  final PortfolioAllocation? bestPosition;
  final PortfolioAllocation? worstPosition;
  final List<PortfolioAllocation> allocationByAsset;
  final double startingCash;

  static PortfolioAnalytics fromState({
    required PaperTradingState tradingState,
    required MarketState marketState,
  }) {
    final positions = tradingState.positionsFor(marketState);
    final investedValue = positions.fold<double>(
      0,
      (total, position) => total + position.marketValue,
    );
    final totalPortfolioValue = tradingState.cashBalance + investedValue;
    final unrealizedProfitLoss = positions.fold<double>(
      0,
      (total, position) => total + position.unrealizedProfitLoss,
    );
    final realizedProfitLoss = tradingState.realizedProfitLoss;
    final totalProfitLoss = realizedProfitLoss + unrealizedProfitLoss;
    final startingCash = tradingState.startingCash;
    final returnPercent = startingCash == 0
        ? 0.0
        : (totalProfitLoss / startingCash) * 100;
    final cashAllocationPercent = totalPortfolioValue == 0
        ? 0.0
        : (tradingState.cashBalance / totalPortfolioValue) * 100;
    final investedAllocationPercent = totalPortfolioValue == 0
        ? 0.0
        : (investedValue / totalPortfolioValue) * 100;
    final allocationByAsset =
        positions
            .map(
              (position) => PortfolioAllocation(
                asset: position.asset,
                quantity: position.quantity,
                marketValue: position.marketValue,
                weightPercent: totalPortfolioValue == 0
                    ? 0
                    : (position.marketValue / totalPortfolioValue) * 100,
                unrealizedProfitLoss: position.unrealizedProfitLoss,
                unrealizedProfitLossPercent:
                    position.unrealizedProfitLossPercent,
              ),
            )
            .toList()
          ..sort((a, b) => b.marketValue.compareTo(a.marketValue));

    PortfolioAllocation? largestPosition;
    PortfolioAllocation? bestPosition;
    PortfolioAllocation? worstPosition;
    if (allocationByAsset.isNotEmpty) {
      largestPosition = allocationByAsset.first;
      bestPosition = allocationByAsset.reduce(
        (best, current) =>
            current.unrealizedProfitLoss > best.unrealizedProfitLoss
            ? current
            : best,
      );
      worstPosition = allocationByAsset.reduce(
        (worst, current) =>
            current.unrealizedProfitLoss < worst.unrealizedProfitLoss
            ? current
            : worst,
      );
    }

    final concentrationRiskPercent = allocationByAsset.isEmpty
        ? 0.0
        : allocationByAsset.first.weightPercent;

    return PortfolioAnalytics(
      totalPortfolioValue: totalPortfolioValue,
      cashBalance: tradingState.cashBalance,
      investedValue: investedValue,
      unrealizedProfitLoss: unrealizedProfitLoss,
      unrealizedProfitLossPercent: investedValue == 0
          ? 0
          : (unrealizedProfitLoss / investedValue) * 100,
      realizedProfitLoss: realizedProfitLoss,
      totalProfitLoss: totalProfitLoss,
      returnPercent: returnPercent,
      cashAllocationPercent: cashAllocationPercent,
      investedAllocationPercent: investedAllocationPercent,
      openPositionsCount: positions.length,
      concentrationRiskPercent: concentrationRiskPercent,
      hasConcentrationWarning:
          concentrationRiskPercent >= AppConfig.analyticsConcentrationThreshold,
      largestPosition: largestPosition,
      bestPosition: bestPosition,
      worstPosition: worstPosition,
      allocationByAsset: allocationByAsset,
      startingCash: startingCash,
    );
  }
}
