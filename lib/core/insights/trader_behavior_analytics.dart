import '../config/app_config.dart';
import '../data/market_state.dart';
import '../data/paper_trading_state.dart';
import '../journal/journal_state.dart';
import '../options_portfolio/options_income_analytics.dart';
import '../options_portfolio/options_portfolio_state.dart';
import '../options_portfolio/wheel_cycle.dart';
import 'journal_pattern_analyzer.dart';
import 'strategy_performance_analyzer.dart';
import 'trader_insight.dart';

class TraderBehaviorAnalytics {
  const TraderBehaviorAnalytics({
    required this.journalAnalysis,
    required this.strategyAnalysis,
    required this.optionsInsights,
    required this.insights,
    required this.generatedAt,
  });

  final JournalPatternAnalytics journalAnalysis;
  final StrategyPerformanceAnalytics strategyAnalysis;
  final List<TraderInsight> optionsInsights;
  final List<TraderInsight> insights;
  final DateTime generatedAt;

  int get totalInsights => insights.length;

  int get positiveCount => insights
      .where((insight) => insight.severity == TraderInsightSeverity.positive)
      .length;

  int get warningCount => insights
      .where((insight) => insight.severity == TraderInsightSeverity.warning)
      .length;

  int get criticalCount => insights
      .where((insight) => insight.severity == TraderInsightSeverity.critical)
      .length;

  bool get hasData =>
      journalAnalysis.hasEntries ||
      strategyAnalysis.hasData ||
      optionsInsights.isNotEmpty;

  static TraderBehaviorAnalytics fromState({
    required JournalState journalState,
    required PaperTradingState paperTradingState,
    required OptionsPortfolioState optionsState,
    required MarketState marketState,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final journalAnalysis = JournalPatternAnalytics.fromEntries(
      journalState.entries,
      asOf: now,
    );
    final optionsAnalytics = OptionsIncomeAnalytics.fromState(
      state: optionsState,
      marketState: marketState,
      asOf: now,
    );
    final strategyAnalysis = StrategyPerformanceAnalyzer.analyze(
      journalEntries: journalState.entries,
      orders: paperTradingState.orders,
      optionsState: optionsState,
      optionsAnalytics: optionsAnalytics,
      asOf: now,
    );

    final optionsInsights = _buildOptionsBehaviorInsights(
      analytics: optionsAnalytics,
      optionsState: optionsState,
      asOf: now,
    );

    final insights =
        <TraderInsight>[
          ...journalAnalysis.insights,
          ...strategyAnalysis.insights,
          ...optionsInsights,
        ]..sort((left, right) {
          final severityComparison = _severityRank(
            right.severity,
          ).compareTo(_severityRank(left.severity));
          if (severityComparison != 0) {
            return severityComparison;
          }
          return right.createdAt.compareTo(left.createdAt);
        });

    return TraderBehaviorAnalytics(
      journalAnalysis: journalAnalysis,
      strategyAnalysis: strategyAnalysis,
      optionsInsights: optionsInsights,
      insights: insights,
      generatedAt: now,
    );
  }

  static List<TraderInsight> _buildOptionsBehaviorInsights({
    required OptionsIncomeAnalytics analytics,
    required OptionsPortfolioState optionsState,
    required DateTime asOf,
  }) {
    final insights = <TraderInsight>[];
    final premiumShare = _largestShare(analytics.premiumByUnderlying);
    if (premiumShare >= AppConfig.insightsPremiumConcentrationThreshold) {
      insights.add(
        TraderInsight(
          id: 'options-concentration-${analytics.premiumByUnderlying.length}',
          title: 'Options premium is concentrated in one underlying',
          description:
              'Most premium collected comes from a single underlying, which increases concentration risk.',
          category: TraderInsightCategory.optionsIncome,
          severity: premiumShare >= 0.6
              ? TraderInsightSeverity.critical
              : TraderInsightSeverity.warning,
          createdAt: asOf,
          metricValue: premiumShare * 100,
          actionSuggestion:
              'Spread premium across more underlyings if that fits your playbook.',
        ),
      );
    }

    final expiringSoon = analytics.upcomingExpirations
        .where(
          (position) =>
              position.daysToExpiration(asOf) <=
              AppConfig.insightsExpirationClusterWindowDays,
        )
        .toList(growable: false);
    if (expiringSoon.length >= AppConfig.insightsExpirationClusterThreshold) {
      insights.add(
        TraderInsight(
          id: 'options-expiration-cluster-${expiringSoon.length}',
          title: 'Several option positions are expiring soon',
          description:
              '${expiringSoon.length} open positions expire within the next ${AppConfig.insightsExpirationClusterWindowDays} days.',
          category: TraderInsightCategory.optionsIncome,
          severity: TraderInsightSeverity.warning,
          createdAt: asOf,
          metricValue: expiringSoon.length.toDouble(),
          actionSuggestion:
              'Plan exits, rolls, or assignments before expiry week gets busy.',
        ),
      );
    }

    if (analytics.assignmentsCount > 0) {
      insights.add(
        TraderInsight(
          id: 'options-assignments-${analytics.assignmentsCount}',
          title: 'Assignment history is present',
          description:
              '${analytics.assignmentsCount} option position(s) have moved into assignment.',
          category: TraderInsightCategory.optionsIncome,
          severity: TraderInsightSeverity.info,
          createdAt: asOf,
          metricValue: analytics.assignmentsCount.toDouble(),
          actionSuggestion:
              'Review assignment notes to see whether assignment was part of the plan.',
        ),
      );
    }

    if (analytics.openPositionsCount > 0 ||
        analytics.expiredWorthlessCount > 0 ||
        analytics.assignmentsCount > 0) {
      final closedCount =
          analytics.expiredWorthlessCount + analytics.assignmentsCount;
      final expiredRate = closedCount == 0
          ? 0.0
          : analytics.expiredWorthlessCount / closedCount;
      insights.add(
        TraderInsight(
          id: 'options-expired-rate-${analytics.expiredWorthlessCount}',
          title:
              'Expired-worthless rate: ${(expiredRate * 100).toStringAsFixed(0)}%',
          description:
              'This is a simple heuristic based on the share of completed option positions that expired worthless.',
          category: TraderInsightCategory.optionsIncome,
          severity: expiredRate >= 0.5
              ? TraderInsightSeverity.positive
              : TraderInsightSeverity.info,
          createdAt: asOf,
          metricValue: expiredRate * 100,
          actionSuggestion:
              'Track whether this rate remains stable across strategies and underlyings.',
        ),
      );
    }

    if (analytics.averagePremiumPerTrade > 0) {
      insights.add(
        TraderInsight(
          id: 'options-average-premium-${analytics.averagePremiumPerTrade.toStringAsFixed(2)}',
          title:
              'Average premium per trade is ${_money(analytics.averagePremiumPerTrade)}',
          description:
              'This helps you compare income efficiency between strategies and underlyings.',
          category: TraderInsightCategory.optionsIncome,
          severity: TraderInsightSeverity.info,
          createdAt: asOf,
          metricValue: analytics.averagePremiumPerTrade,
          actionSuggestion:
              'Compare this number against your capital at risk and days to expiry.',
        ),
      );
    }

    final cycleWarnings = optionsState.wheelCycles
        .where(
          (cycle) =>
              cycle.status == WheelCycleStatus.assigned ||
              cycle.status == WheelCycleStatus.calledAway,
        )
        .where((cycle) => cycle.realizedPnl < 0)
        .toList(growable: false);
    if (cycleWarnings.isNotEmpty) {
      insights.add(
        TraderInsight(
          id: 'options-wheel-negative-${cycleWarnings.length}',
          title: 'Some wheel cycles closed with a loss',
          description:
              '${cycleWarnings.length} wheel cycle(s) ended with negative realized P/L.',
          category: TraderInsightCategory.optionsIncome,
          severity: TraderInsightSeverity.warning,
          createdAt: asOf,
          metricValue: cycleWarnings.length.toDouble(),
          actionSuggestion:
              'Review strike selection, shares assignment, and exit rules.',
        ),
      );
    }

    return insights;
  }

  static double _largestShare(Map<String, double> values) {
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return 0;
    }
    final largest = values.values.fold<double>(
      0,
      (best, value) => value > best ? value : best,
    );
    return largest / total;
  }

  static int _severityRank(TraderInsightSeverity severity) {
    return switch (severity) {
      TraderInsightSeverity.info => 0,
      TraderInsightSeverity.positive => 1,
      TraderInsightSeverity.warning => 2,
      TraderInsightSeverity.critical => 3,
    };
  }

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';
}
