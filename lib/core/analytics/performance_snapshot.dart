import 'portfolio_analytics.dart';

class PerformanceSnapshot {
  const PerformanceSnapshot({
    required this.realizedProfitLoss,
    required this.unrealizedProfitLoss,
    required this.totalProfitLoss,
    required this.returnPercent,
    required this.cashAllocationPercent,
    required this.investedAllocationPercent,
    required this.concentrationRiskPercent,
    required this.hasConcentrationWarning,
    required this.startingCash,
    required this.totalPortfolioValue,
  });

  final double realizedProfitLoss;
  final double unrealizedProfitLoss;
  final double totalProfitLoss;
  final double returnPercent;
  final double cashAllocationPercent;
  final double investedAllocationPercent;
  final double concentrationRiskPercent;
  final bool hasConcentrationWarning;
  final double startingCash;
  final double totalPortfolioValue;

  factory PerformanceSnapshot.fromPortfolio(PortfolioAnalytics analytics) {
    return PerformanceSnapshot(
      realizedProfitLoss: analytics.realizedProfitLoss,
      unrealizedProfitLoss: analytics.unrealizedProfitLoss,
      totalProfitLoss: analytics.totalProfitLoss,
      returnPercent: analytics.returnPercent,
      cashAllocationPercent: analytics.cashAllocationPercent,
      investedAllocationPercent: analytics.investedAllocationPercent,
      concentrationRiskPercent: analytics.concentrationRiskPercent,
      hasConcentrationWarning: analytics.hasConcentrationWarning,
      startingCash: analytics.startingCash,
      totalPortfolioValue: analytics.totalPortfolioValue,
    );
  }
}
