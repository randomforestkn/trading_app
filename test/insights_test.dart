import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/insights/journal_pattern_analyzer.dart';
import 'package:trading_app/core/insights/strategy_performance_analyzer.dart';
import 'package:trading_app/core/insights/trader_insight.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/options_portfolio/option_position.dart';
import 'package:trading_app/core/options_portfolio/options_income_analytics.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/core/strategies/option_strategy.dart';
import 'package:trading_app/core/insights/insights_state.dart';

void main() {
  test('TraderInsight serializes and deserializes', () {
    final insight = TraderInsight(
      id: 'insight-1',
      title: 'Sample insight',
      description: 'Rule-based summary',
      category: TraderInsightCategory.psychology,
      severity: TraderInsightSeverity.warning,
      createdAt: DateTime(2025, 1, 1),
      relatedSymbol: 'NVO',
      relatedStrategy: 'wheel',
      metricValue: 2.5,
      actionSuggestion: 'Review your rules.',
    );

    final decoded = TraderInsight.fromJson(insight.toJson());

    expect(decoded.id, insight.id);
    expect(decoded.title, insight.title);
    expect(decoded.category, insight.category);
    expect(decoded.severity, insight.severity);
    expect(decoded.relatedSymbol, insight.relatedSymbol);
    expect(decoded.metricValue, insight.metricValue);
  });

  test('journal pattern analyzer detects recurring behavior', () {
    final entries = [
      _entry(
        id: '1',
        strategy: JournalStrategyType.coveredCall,
        mood: JournalMood.confident,
        outcome: JournalOutcome.win,
        conviction: 5,
        risk: 2,
        asset: 'NVO',
        tags: const ['plan', 'discipline'],
        lessons: 'Stayed patient and followed the process.',
      ),
      _entry(
        id: '2',
        strategy: JournalStrategyType.coveredCall,
        mood: JournalMood.confident,
        outcome: JournalOutcome.win,
        conviction: 4,
        risk: 2,
        asset: 'NVO',
        tags: const ['plan', 'review'],
        lessons: 'Good checklist execution.',
      ),
      _entry(
        id: '3',
        strategy: JournalStrategyType.wheel,
        mood: JournalMood.anxious,
        outcome: JournalOutcome.loss,
        conviction: 4,
        risk: 4,
        asset: 'NVO',
        tags: const ['fomo', 'fomo'],
        lessons: 'Ignored the plan and felt rushed.',
      ),
      _entry(
        id: '4',
        strategy: JournalStrategyType.wheel,
        mood: JournalMood.anxious,
        outcome: JournalOutcome.loss,
        conviction: 5,
        risk: 5,
        asset: 'NVO',
        tags: const ['fomo'],
        lessons: 'Oversized the trade.',
      ),
    ];

    final analysis = JournalPatternAnalyzer.analyze(
      entries,
      asOf: DateTime(2025),
    );

    expect(analysis.totalEntries, 4);
    expect(analysis.averageConviction, closeTo(4.5, 0.01));
    expect(analysis.averageRisk, closeTo(3.25, 0.01));
    expect(analysis.mostCommonMood, JournalMood.confident);
    expect(analysis.highConvictionPoorOutcomeCount, 2);
    expect(analysis.highRiskEntryCount, 2);
    expect(analysis.repeatedTags, contains('fomo'));
    expect(analysis.disciplineSignalCount, greaterThan(0));
    expect(
      analysis.insights.any(
        (insight) =>
            insight.title.contains('High conviction') &&
            insight.severity == TraderInsightSeverity.warning,
      ),
      isTrue,
    );
  });

  test(
    'strategy performance analyzer combines journal, trade, and options data',
    () async {
      final marketState = MarketState();
      final journalEntries = [
        _entry(
          id: '1',
          strategy: JournalStrategyType.coveredCall,
          mood: JournalMood.disciplined,
          outcome: JournalOutcome.win,
          conviction: 5,
          risk: 2,
          asset: 'NVO',
        ),
        _entry(
          id: '2',
          strategy: JournalStrategyType.coveredCall,
          mood: JournalMood.disciplined,
          outcome: JournalOutcome.win,
          conviction: 4,
          risk: 2,
          asset: 'NVO',
        ),
        _entry(
          id: '3',
          strategy: JournalStrategyType.coveredCall,
          mood: JournalMood.confident,
          outcome: JournalOutcome.loss,
          conviction: 4,
          risk: 3,
          asset: 'NVO',
        ),
        _entry(
          id: '4',
          strategy: JournalStrategyType.wheel,
          mood: JournalMood.anxious,
          outcome: JournalOutcome.loss,
          conviction: 4,
          risk: 5,
          asset: 'NVDA',
        ),
        _entry(
          id: '5',
          strategy: JournalStrategyType.wheel,
          mood: JournalMood.anxious,
          outcome: JournalOutcome.loss,
          conviction: 5,
          risk: 5,
          asset: 'NVDA',
        ),
      ];

      final orders = [
        PaperOrder(
          assetSymbol: 'AAPL',
          assetName: 'Apple Inc.',
          side: PaperOrderSide.buy,
          quantity: 1,
          executionPrice: 100,
          estimatedTotal: 100,
          timestamp: DateTime(2025, 1, 1),
          status: PaperOrderStatus.filled,
        ),
        PaperOrder(
          assetSymbol: 'VOO',
          assetName: 'Vanguard S&P 500 ETF',
          side: PaperOrderSide.buy,
          quantity: 3,
          executionPrice: 500,
          estimatedTotal: 1500,
          timestamp: DateTime(2025, 1, 2),
          status: PaperOrderStatus.filled,
        ),
      ];

      final optionsState = OptionsPortfolioState(
        repository: LocalOptionsPortfolioRepository(
          store: MemoryOptionsPortfolioStore(),
        ),
      );
      await optionsState.addPosition(
        OptionPosition(
          id: '',
          underlyingSymbol: 'NVO',
          optionType: OptionType.put,
          side: OptionSide.sell,
          strikePrice: 100,
          premium: 1,
          contractsCount: 1,
          openedAt: DateTime(2025, 1, 1),
          expirationDate: DateTime(2025, 1, 15),
          status: OptionPositionStatus.open,
          linkedStrategy: OptionStrategy.wheel,
        ),
      );
      await optionsState.addPosition(
        OptionPosition(
          id: '',
          underlyingSymbol: 'NVO',
          optionType: OptionType.put,
          side: OptionSide.sell,
          strikePrice: 95,
          premium: 1.2,
          contractsCount: 1,
          openedAt: DateTime(2025, 1, 2),
          expirationDate: DateTime(2025, 1, 18),
          status: OptionPositionStatus.open,
          linkedStrategy: OptionStrategy.wheel,
        ),
      );
      final openPositionId = optionsState.openPositions.first.id;
      await optionsState.markAssigned(
        openPositionId,
        currentUnderlyingPrice: 90,
      );

      final optionsAnalytics = OptionsIncomeAnalytics.fromState(
        state: optionsState,
        marketState: marketState,
        asOf: DateTime(2025, 1, 3),
      );

      final analysis = StrategyPerformanceAnalyzer.analyze(
        journalEntries: journalEntries,
        orders: orders,
        optionsState: optionsState,
        optionsAnalytics: optionsAnalytics,
        asOf: DateTime(2025, 1, 3),
      );

      expect(analysis.bestStrategy, JournalStrategyType.coveredCall);
      expect(analysis.worstStrategy, JournalStrategyType.wheel);
      expect(analysis.mostJournaledStrategy, JournalStrategyType.coveredCall);
      expect(analysis.mostTradedAssetSymbol, 'VOO');
      expect(analysis.symbolsWithRepeatedLosses, contains('NVDA'));
      expect(
        analysis.strategiesWithHighRiskRatings,
        contains(JournalStrategyType.wheel),
      );
      expect(analysis.premiumConcentrationByUnderlying['NVO'], isNotNull);
      expect(analysis.wheelCyclesWithPoorOutcomes, isNotEmpty);
      expect(
        analysis.insights.any(
          (insight) => insight.category == TraderInsightCategory.optionsIncome,
        ),
        isTrue,
      );
    },
  );

  test('InsightsState refreshes from source states', () async {
    final journalState = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );
    final paperState = PaperTradingState.fromAccount(
      PaperTradingAccount.defaultAccount(),
      repository: const LocalPaperTradingRepository(),
    );
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );
    final marketState = MarketState();
    final insightsState = InsightsState(
      journalState: journalState,
      paperTradingState: paperState,
      optionsState: optionsState,
      marketState: marketState,
    );

    await insightsState.refreshInsights();
    expect(insightsState.insights, isEmpty);

    await journalState.addEntry(
      _entry(
        id: '1',
        strategy: JournalStrategyType.coveredCall,
        mood: JournalMood.confident,
        outcome: JournalOutcome.win,
        conviction: 5,
        risk: 2,
        asset: 'NVO',
      ),
    );
    await insightsState.refreshInsights();

    expect(insightsState.insights, isNotEmpty);
    expect(insightsState.positiveInsights, isNotEmpty);
  });
}

JournalEntry _entry({
  required String id,
  required JournalStrategyType strategy,
  required JournalMood mood,
  required JournalOutcome outcome,
  required int conviction,
  required int risk,
  required String asset,
  List<String> tags = const [],
  String? lessons,
}) {
  return JournalEntry(
    id: id,
    createdAt: DateTime(2025, 1, int.parse(id)),
    updatedAt: DateTime(2025, 1, int.parse(id)),
    title: 'Entry $id',
    body: 'Journal body $id',
    linkedAssetSymbol: asset,
    linkedStrategy: strategy,
    mood: mood,
    convictionRating: conviction,
    riskRating: risk,
    outcome: outcome,
    lessonsLearned: lessons,
    tags: tags,
  );
}
