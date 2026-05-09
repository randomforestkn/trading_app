import '../config/app_config.dart';
import '../journal/journal_entry.dart';
import '../models/paper_order.dart';
import '../options_portfolio/options_income_analytics.dart';
import '../options_portfolio/options_portfolio_state.dart';
import '../options_portfolio/wheel_cycle.dart';
import 'trader_insight.dart';

class StrategyPerformanceAnalytics {
  const StrategyPerformanceAnalytics({
    required this.bestStrategy,
    required this.worstStrategy,
    required this.mostJournaledStrategy,
    required this.mostTradedAssetSymbol,
    required this.symbolsWithRepeatedLosses,
    required this.strategiesWithHighRiskRatings,
    required this.premiumConcentrationByUnderlying,
    required this.wheelCyclesWithPoorOutcomes,
    required this.insights,
  });

  final JournalStrategyType? bestStrategy;
  final JournalStrategyType? worstStrategy;
  final JournalStrategyType? mostJournaledStrategy;
  final String? mostTradedAssetSymbol;
  final List<String> symbolsWithRepeatedLosses;
  final List<JournalStrategyType> strategiesWithHighRiskRatings;
  final Map<String, double> premiumConcentrationByUnderlying;
  final List<WheelCycle> wheelCyclesWithPoorOutcomes;
  final List<TraderInsight> insights;

  bool get hasData =>
      bestStrategy != null ||
      worstStrategy != null ||
      mostJournaledStrategy != null ||
      mostTradedAssetSymbol != null ||
      symbolsWithRepeatedLosses.isNotEmpty ||
      strategiesWithHighRiskRatings.isNotEmpty ||
      premiumConcentrationByUnderlying.isNotEmpty ||
      wheelCyclesWithPoorOutcomes.isNotEmpty;
}

class StrategyPerformanceAnalyzer {
  const StrategyPerformanceAnalyzer._();

  static StrategyPerformanceAnalytics analyze({
    required List<JournalEntry> journalEntries,
    required List<PaperOrder> orders,
    required OptionsPortfolioState optionsState,
    required OptionsIncomeAnalytics optionsAnalytics,
    DateTime? asOf,
  }) {
    final journalStrategies = <JournalStrategyType, _StrategyScore>{};
    final symbolsWithLosses = <String, int>{};
    final strategiesWithRisk = <JournalStrategyType, List<int>>{};

    for (final entry in journalEntries) {
      final strategy = entry.linkedStrategy;
      if (strategy == null) {
        continue;
      }
      final score = journalStrategies.putIfAbsent(
        strategy,
        () => _StrategyScore(strategy),
      );
      score.totalCount += 1;
      switch (entry.outcome) {
        case JournalOutcome.win:
          score.winCount += 1;
        case JournalOutcome.loss:
          score.lossCount += 1;
          if (entry.linkedAssetSymbol != null) {
            symbolsWithLosses[entry.linkedAssetSymbol!] =
                (symbolsWithLosses[entry.linkedAssetSymbol!] ?? 0) + 1;
          }
        case JournalOutcome.breakeven:
          score.breakevenCount += 1;
        case JournalOutcome.open:
        case null:
          break;
      }
      strategiesWithRisk
          .putIfAbsent(strategy, () => <int>[])
          .add(entry.riskRating);
    }

    final bestStrategy = _bestStrategy(journalStrategies.values);
    final worstStrategy = _worstStrategy(journalStrategies.values);
    final mostJournaledStrategy = _mostJournaledStrategy(
      journalStrategies.values,
    );
    final mostTradedAssetSymbol = _mostTradedAsset(orders);
    final repeatedLossSymbols =
        symbolsWithLosses.entries
            .where(
              (entry) => entry.value >= AppConfig.insightsRepeatedLossThreshold,
            )
            .map((entry) => entry.key)
            .toList(growable: false)
          ..sort();
    final strategiesWithHighRiskRatings =
        strategiesWithRisk.entries
            .where(
              (entry) =>
                  entry.value.isNotEmpty &&
                  entry.value.fold<double>(
                            0,
                            (total, rating) => total + rating,
                          ) /
                          entry.value.length >=
                      4,
            )
            .map((entry) => entry.key)
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));

    final premiumConcentrationByUnderlying = Map<String, double>.from(
      optionsAnalytics.premiumByUnderlying,
    );
    final wheelCyclesWithPoorOutcomes = optionsState.wheelCycles
        .where((cycle) => cycle.realizedPnl < 0)
        .toList(growable: false);

    final insights = <TraderInsight>[];
    final best = bestStrategy;
    if (best != null) {
      final score = journalStrategies[best];
      if (score != null) {
        insights.add(
          TraderInsight(
            id: _id('best-strategy', best.name),
            title: 'Best journaled strategy: ${best.label}',
            description:
                '${best.label} notes have the strongest net outcome score in your journal.',
            category: TraderInsightCategory.strategy,
            severity: TraderInsightSeverity.positive,
            createdAt: asOf ?? DateTime.now(),
            relatedStrategy: best.name,
            metricValue: score.netScore.toDouble(),
            actionSuggestion:
                'Review the setups, sizing, and exits that make this strategy work.',
          ),
        );
      }
    }

    final worst = worstStrategy;
    if (worst != null) {
      final score = journalStrategies[worst];
      if (score != null) {
        insights.add(
          TraderInsight(
            id: _id('worst-strategy', worst.name),
            title: 'Weakest journaled strategy: ${worst.label}',
            description:
                '${worst.label} notes are producing the weakest net outcome score.',
            category: TraderInsightCategory.strategy,
            severity: TraderInsightSeverity.warning,
            createdAt: asOf ?? DateTime.now(),
            relatedStrategy: worst.name,
            metricValue: score.netScore.toDouble(),
            actionSuggestion:
                'Reduce size or tighten rules until the pattern improves.',
          ),
        );
      }
    }

    final mostJournaled = mostJournaledStrategy;
    if (mostJournaled != null) {
      final score = journalStrategies[mostJournaled];
      if (score != null) {
        insights.add(
          TraderInsight(
            id: _id('most-journaled', mostJournaled.name),
            title: 'Most journaled strategy: ${mostJournaled.label}',
            description:
                '${mostJournaled.label} appears most often in your notes.',
            category: TraderInsightCategory.consistency,
            severity: TraderInsightSeverity.info,
            createdAt: asOf ?? DateTime.now(),
            relatedStrategy: mostJournaled.name,
            metricValue: score.totalCount.toDouble(),
            actionSuggestion:
                'Keep logging the setup details for this strategy.',
          ),
        );
      }
    }

    if (mostTradedAssetSymbol != null) {
      final symbol = mostTradedAssetSymbol;
      insights.add(
        TraderInsight(
          id: _id('most-traded-asset', symbol),
          title: 'Most traded asset: $symbol',
          description:
              '$symbol has the highest traded notional in your paper orders.',
          category: TraderInsightCategory.execution,
          severity: TraderInsightSeverity.info,
          createdAt: asOf ?? DateTime.now(),
          relatedSymbol: symbol,
          actionSuggestion:
              'Check whether repeated trading in this symbol is deliberate or habitual.',
        ),
      );
    }

    if (repeatedLossSymbols.isNotEmpty) {
      insights.add(
        TraderInsight(
          id: _id('repeated-losses', repeatedLossSymbols.length),
          title: 'Repeated losses are clustering in a few symbols',
          description:
              'Symbols with repeated losses: ${repeatedLossSymbols.take(4).join(', ')}.',
          category: TraderInsightCategory.risk,
          severity: TraderInsightSeverity.warning,
          createdAt: asOf ?? DateTime.now(),
          metricValue: repeatedLossSymbols.length.toDouble(),
          actionSuggestion:
              'Consider pausing those symbols until the setup criteria are clearer.',
        ),
      );
    }

    if (strategiesWithHighRiskRatings.isNotEmpty) {
      insights.add(
        TraderInsight(
          id: _id('high-risk-strategies', strategiesWithHighRiskRatings.length),
          title: 'Some strategies are carrying high journal risk',
          description:
              'High average risk ratings show up in ${strategiesWithHighRiskRatings.take(4).map((item) => item.label).join(', ')}.',
          category: TraderInsightCategory.risk,
          severity: TraderInsightSeverity.warning,
          createdAt: asOf ?? DateTime.now(),
          metricValue: strategiesWithHighRiskRatings.length.toDouble(),
          actionSuggestion:
              'Use smaller size or stricter filters on these strategies.',
        ),
      );
    }

    if (optionsAnalytics.premiumByUnderlying.isNotEmpty) {
      insights.add(
        TraderInsight(
          id: _id(
            'premium-concentration',
            optionsAnalytics.premiumByUnderlying.length,
          ),
          title: 'Premium income is concentrated',
          description:
              'Most premium income comes from ${_topUnderlying(optionsAnalytics.premiumByUnderlying)}.',
          category: TraderInsightCategory.optionsIncome,
          severity: _concentrationSeverity(
            optionsAnalytics.premiumByUnderlying,
          ),
          createdAt: asOf ?? DateTime.now(),
          metricValue: _largestShare(optionsAnalytics.premiumByUnderlying),
          actionSuggestion:
              'Diversify underlyings if you want a smoother premium stream.',
        ),
      );
    }

    if (wheelCyclesWithPoorOutcomes.isNotEmpty) {
      insights.add(
        TraderInsight(
          id: _id('wheel-poor-outcomes', wheelCyclesWithPoorOutcomes.length),
          title: 'Some wheel cycles have weak outcomes',
          description:
              '${wheelCyclesWithPoorOutcomes.length} wheel cycle(s) currently show negative realized P/L.',
          category: TraderInsightCategory.optionsIncome,
          severity: TraderInsightSeverity.warning,
          createdAt: asOf ?? DateTime.now(),
          metricValue: wheelCyclesWithPoorOutcomes.length.toDouble(),
          actionSuggestion:
              'Review whether assignment quality or call strikes need adjustment.',
        ),
      );
    }

    insights.sort((left, right) {
      final severityComparison = _severityRank(
        right.severity,
      ).compareTo(_severityRank(left.severity));
      if (severityComparison != 0) {
        return severityComparison;
      }
      return right.createdAt.compareTo(left.createdAt);
    });

    return StrategyPerformanceAnalytics(
      bestStrategy: bestStrategy,
      worstStrategy: worstStrategy,
      mostJournaledStrategy: mostJournaledStrategy,
      mostTradedAssetSymbol: mostTradedAssetSymbol,
      symbolsWithRepeatedLosses: repeatedLossSymbols,
      strategiesWithHighRiskRatings: strategiesWithHighRiskRatings,
      premiumConcentrationByUnderlying: premiumConcentrationByUnderlying,
      wheelCyclesWithPoorOutcomes: wheelCyclesWithPoorOutcomes,
      insights: insights,
    );
  }

  static JournalStrategyType? _bestStrategy(Iterable<_StrategyScore> scores) {
    _StrategyScore? best;
    for (final score in scores) {
      if (best == null || score.netScore > best.netScore) {
        best = score;
      }
    }
    return best?.strategy;
  }

  static JournalStrategyType? _worstStrategy(Iterable<_StrategyScore> scores) {
    _StrategyScore? worst;
    for (final score in scores) {
      if (worst == null || score.netScore < worst.netScore) {
        worst = score;
      }
    }
    return worst?.strategy;
  }

  static JournalStrategyType? _mostJournaledStrategy(
    Iterable<_StrategyScore> scores,
  ) {
    _StrategyScore? most;
    for (final score in scores) {
      if (most == null || score.totalCount > most.totalCount) {
        most = score;
      }
    }
    return most?.strategy;
  }

  static String? _mostTradedAsset(List<PaperOrder> orders) {
    if (orders.isEmpty) {
      return null;
    }
    final bySymbol = <String, double>{};
    for (final order in orders) {
      bySymbol[order.assetSymbol] =
          (bySymbol[order.assetSymbol] ?? 0) + order.estimatedTotal;
    }
    final top = bySymbol.entries.reduce(
      (best, current) => current.value > best.value ? current : best,
    );
    return top.key;
  }

  static TraderInsightSeverity _concentrationSeverity(
    Map<String, double> values,
  ) {
    final share = _largestShare(values);
    if (share >= 0.6) {
      return TraderInsightSeverity.critical;
    }
    if (share >= AppConfig.insightsPremiumConcentrationThreshold) {
      return TraderInsightSeverity.warning;
    }
    return TraderInsightSeverity.info;
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

  static String _topUnderlying(Map<String, double> values) {
    if (values.isEmpty) {
      return 'no underlyings yet';
    }
    final entries = values.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first;
    final share = _largestShare(values) * 100;
    return '${top.key} (${share.toStringAsFixed(0)}% of premium)';
  }

  static int _severityRank(TraderInsightSeverity severity) {
    return switch (severity) {
      TraderInsightSeverity.info => 0,
      TraderInsightSeverity.positive => 1,
      TraderInsightSeverity.warning => 2,
      TraderInsightSeverity.critical => 3,
    };
  }

  static String _id(String prefix, Object value) => '$prefix-$value';
}

class _StrategyScore {
  _StrategyScore(this.strategy);

  final JournalStrategyType strategy;
  int totalCount = 0;
  int winCount = 0;
  int lossCount = 0;
  int breakevenCount = 0;

  int get netScore => winCount - lossCount;
}
