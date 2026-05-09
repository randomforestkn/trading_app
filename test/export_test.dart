import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/analytics/performance_snapshot.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/data/auth_state.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/export/csv_exporter.dart';
import 'package:trading_app/core/export/export_bundle.dart';
import 'package:trading_app/core/export/export_format.dart';
import 'package:trading_app/core/export/json_backup_exporter.dart';
import 'package:trading_app/core/export/local_export_repository.dart';
import 'package:trading_app/core/export/report_generator.dart';
import 'package:trading_app/core/insights/insights_state.dart';
import 'package:trading_app/core/insights/journal_pattern_analyzer.dart';
import 'package:trading_app/core/insights/strategy_performance_analyzer.dart';
import 'package:trading_app/core/insights/trader_behavior_analytics.dart';
import 'package:trading_app/core/insights/trader_insight.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/options_portfolio/option_position.dart';
import 'package:trading_app/core/options_portfolio/option_trade.dart';
import 'package:trading_app/core/options_portfolio/options_income_analytics.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_account.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/wheel_cycle.dart';
import 'package:trading_app/core/models/app_user.dart';
import 'package:trading_app/core/models/auth_session.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/models/portfolio_position.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/sync_metadata.dart';
import 'package:trading_app/core/sync/sync_state.dart';
import 'package:trading_app/core/sync/sync_status.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/strategies/option_strategy.dart';
import 'package:trading_app/core/widgets/app_buttons.dart';
import 'package:trading_app/features/export_reports/export_reports_screen.dart';
import 'package:trading_app/features/settings/settings_screen.dart';

void main() {
  test('CSV escaping preserves commas, quotes, and newlines', () {
    final csv = CsvExporter.journalEntries([
      JournalEntry(
        id: 'j-1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        title: 'Title, with comma',
        body: 'Line 1\n"He said, go"',
        linkedAssetSymbol: 'NVO',
        linkedStrategy: JournalStrategyType.wheel,
        mood: JournalMood.confident,
        convictionRating: 4,
        riskRating: 2,
        outcome: JournalOutcome.win,
        lessonsLearned: 'Keep going',
        tags: const ['discipline', 'review'],
      ),
    ]);

    expect(csv, contains('"Title, with comma"'));
    expect(csv, contains('"Line 1'));
    expect(csv, contains('""He said, go""'));
    expect(csv, contains('discipline; review'));
  });

  test('JSON backup contains expected sections', () {
    final bundle = _sampleBundle(ExportFormat.jsonBackup);
    final json = JsonBackupExporter.encode(bundle);

    expect(json, contains('"paperTrading"'));
    expect(json, contains('"journal"'));
    expect(json, contains('"optionsPortfolio"'));
    expect(json, contains('"performance"'));
    expect(json, contains('"sync"'));
    expect(json, contains('"auth"'));
  });

  test('paper trades CSV generation works', () {
    final bundle = _sampleBundle(ExportFormat.paperTradesCsv);
    final csv = CsvExporter.paperOrders(bundle.paperTradingAccount!.orders);

    expect(csv, contains('assetSymbol'));
    expect(csv, contains(bundle.paperTradingAccount!.orders.first.assetSymbol));
    expect(csv, contains('realizedProfitLoss'));
  });

  test('journal CSV generation works', () {
    final bundle = _sampleBundle(ExportFormat.journalCsv);
    final csv = CsvExporter.journalEntries(bundle.journalEntries);

    expect(csv, contains('linkedStrategy'));
    expect(csv, contains('wheel'));
    expect(csv, contains('tags'));
  });

  test('options positions CSV generation works', () {
    final bundle = _sampleBundle(ExportFormat.optionsPositionsCsv);
    final csv = CsvExporter.optionPositions(
      bundle.optionsPortfolioAccount!.positions,
    );

    expect(csv, contains('underlyingSymbol'));
    expect(csv, contains('optionType'));
    expect(csv, contains('cashSecuredPut'));
  });

  test('performance report contains key sections', () {
    final bundle = _sampleBundle(ExportFormat.performanceReport);
    final report = ReportGenerator.generate(bundle);

    expect(report, contains('# ClearTrade performance report'));
    expect(report, contains('## Portfolio summary'));
    expect(report, contains('## Options income'));
    expect(report, contains('## Trader behavior'));
    expect(report, contains('educational only'));
  });

  test('repository returns filename mime type and content', () async {
    final repository = LocalExportRepository();
    final result = await repository.exportJsonBackup(
      _sampleBundle(ExportFormat.jsonBackup),
    );

    expect(
      result.when(success: (data) => data.filename, failure: (_) => ''),
      contains('cleartrade_backup_'),
    );
    expect(
      result.when(success: (data) => data.mimeType, failure: (_) => ''),
      'application/json',
    );
    expect(
      result.when(success: (data) => data.content, failure: (_) => ''),
      isNotEmpty,
    );
  });

  testWidgets('Export screen renders and generates a report', (tester) async {
    await tester.pumpWidget(_exportHarness());
    await tester.pumpAndSettle();

    expect(find.text('Export & reports'), findsOneWidget);
    expect(find.text('Generate JSON backup'), findsOneWidget);
    expect(find.text('Generate report'), findsOneWidget);

    final reportButton = tester.widget<AppPrimaryButton>(
      find.widgetWithText(AppPrimaryButton, 'Generate report'),
    );
    reportButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Latest export'), findsOneWidget);
    expect(find.textContaining('.md'), findsWidgets);
  });

  testWidgets('Settings screen shows export section', (tester) async {
    await tester.pumpWidget(_settingsHarness());

    expect(find.text('Export data / reports'), findsOneWidget);
  });
}

ExportBundle _sampleBundle(ExportFormat format) {
  final asset = MockMarketData.assets.first;
  final paperTradingAccount = PaperTradingAccount(
    startingCash: 10000,
    cashBalance: 9450,
    positions: [
      PortfolioPosition(asset: asset, quantity: 5, averagePrice: asset.price),
    ],
    orders: [
      PaperOrder(
        assetSymbol: asset.symbol,
        assetName: asset.name,
        side: PaperOrderSide.buy,
        quantity: 5,
        executionPrice: asset.price,
        estimatedTotal: asset.price * 5,
        timestamp: DateTime.utc(2026, 1, 1),
        status: PaperOrderStatus.filled,
      ),
    ],
    lastUpdated: DateTime.utc(2026, 1, 2),
  );

  final journalEntries = [
    JournalEntry(
      id: 'j-1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      title: 'Wheel review',
      body: 'Executed according to plan.',
      linkedAssetSymbol: asset.symbol,
      linkedStrategy: JournalStrategyType.wheel,
      mood: JournalMood.disciplined,
      convictionRating: 4,
      riskRating: 2,
      outcome: JournalOutcome.win,
      lessonsLearned: 'Keep discipline and size consistent.',
      tags: const ['discipline', 'wheel'],
    ),
  ];

  final optionPosition = OptionPosition(
    id: 'opt-1',
    underlyingSymbol: asset.symbol,
    underlyingName: asset.name,
    optionType: OptionType.put,
    side: OptionSide.sell,
    strikePrice: asset.price * 0.95,
    premium: 1.25,
    contractsCount: 1,
    openedAt: DateTime.utc(2026, 1, 1),
    expirationDate: DateTime.utc(2026, 2, 1),
    status: OptionPositionStatus.open,
    linkedStrategy: OptionStrategy.cashSecuredPut,
    notes: 'Sample note',
  );
  final optionsPortfolioAccount = OptionsPortfolioAccount(
    positions: [optionPosition],
    trades: [
      OptionTrade(
        id: 'trade-1',
        positionId: optionPosition.id,
        createdAt: DateTime.utc(2026, 1, 1),
        eventType: OptionTradeEventType.open,
        premium: optionPosition.totalPremium,
        quantity: optionPosition.contractsCount.toDouble(),
      ),
    ],
    wheelCycles: [
      WheelCycle(
        id: 'cycle-1',
        underlyingSymbol: asset.symbol,
        startedAt: DateTime.utc(2026, 1, 1),
        status: WheelCycleStatus.sellingPuts,
        putPositionIds: [optionPosition.id],
        totalPremiumCollected: optionPosition.totalPremium,
      ),
    ],
    lastUpdated: DateTime.utc(2026, 1, 2),
  );

  final performance = PerformanceSnapshot(
    realizedProfitLoss: 125,
    unrealizedProfitLoss: 225,
    totalProfitLoss: 350,
    returnPercent: 3.5,
    cashAllocationPercent: 45,
    investedAllocationPercent: 55,
    concentrationRiskPercent: 55,
    hasConcentrationWarning: true,
    startingCash: 10000,
    totalPortfolioValue: 10350,
  );

  final optionsIncome = OptionsIncomeAnalytics(
    totalPremiumCollected: 250,
    premiumCollectedThisMonth: 125,
    realizedOptionsProfitLoss: 75,
    openPremiumAtRisk: optionPosition.totalPremium,
    averagePremiumPerTrade: optionPosition.totalPremium,
    annualizedPremiumYieldAverage: 18.2,
    premiumByStrategy: {
      OptionStrategy.cashSecuredPut: optionPosition.totalPremium,
    },
    premiumByUnderlying: {asset.symbol: optionPosition.totalPremium},
    openContractsCount: 1,
    upcomingExpirations: [optionPosition],
    assignmentsCount: 0,
    expiredWorthlessCount: 0,
    openPositionsCount: 1,
    latestUpdatedAt: DateTime.utc(2026, 1, 2),
  );

  final behaviorAnalytics = TraderBehaviorAnalytics(
    journalAnalysis: JournalPatternAnalytics(
      totalEntries: journalEntries.length,
      averageConviction: 4,
      averageRisk: 2,
      mostCommonMood: JournalMood.disciplined,
      moodOutcomeCounts: const {},
      highConvictionPoorOutcomeCount: 0,
      highRiskEntryCount: 0,
      repeatedTags: const ['discipline'],
      disciplineSignals: const ['discipline'],
      disciplineSignalCount: 1,
      insights: [
        TraderInsight(
          id: 'journal-1',
          title: 'Disciplined notes detected',
          description: 'Your notes show disciplined language.',
          category: TraderInsightCategory.consistency,
          severity: TraderInsightSeverity.positive,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      ],
    ),
    strategyAnalysis: StrategyPerformanceAnalytics(
      bestStrategy: JournalStrategyType.wheel,
      worstStrategy: JournalStrategyType.stockTrade,
      mostJournaledStrategy: JournalStrategyType.wheel,
      mostTradedAssetSymbol: asset.symbol,
      symbolsWithRepeatedLosses: const [],
      strategiesWithHighRiskRatings: const [],
      premiumConcentrationByUnderlying: {
        asset.symbol: optionPosition.totalPremium,
      },
      wheelCyclesWithPoorOutcomes: const [],
      insights: [
        TraderInsight(
          id: 'strategy-1',
          title: 'Wheel is the primary playbook',
          description: 'The wheel strategy appears most often.',
          category: TraderInsightCategory.strategy,
          severity: TraderInsightSeverity.info,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      ],
    ),
    optionsInsights: [
      TraderInsight(
        id: 'options-1',
        title: 'Premium concentration warning',
        description: 'Most premium is coming from one underlying.',
        category: TraderInsightCategory.optionsIncome,
        severity: TraderInsightSeverity.warning,
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    ],
    insights: [
      TraderInsight(
        id: 'overall-1',
        title: 'Keep tracking the journal',
        description: 'Regular notes help preserve discipline.',
        category: TraderInsightCategory.consistency,
        severity: TraderInsightSeverity.positive,
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    ],
    generatedAt: DateTime.utc(2026, 1, 2),
  );

  final authSession = AuthSession(
    user: AppUser(
      id: 'demo-user',
      email: 'demo@cleartrade.local',
      displayName: 'Demo Trader',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final syncMetadata = SyncMetadata(
    lastSyncedAt: DateTime.utc(2026, 1, 2),
    lastAttemptedAt: DateTime.utc(2026, 1, 2),
    pendingOperationsCount: 1,
    lastError: null,
    deviceId: 'device-1',
    userId: 'demo-user',
    syncMode: SyncMode.localOnly,
  );

  return ExportBundle(
    createdAt: DateTime.utc(2026, 1, 2),
    appVersionLabel: AppConfig.appVersionLabel,
    buildModeLabel: AppConfig.buildModeLabel,
    marketModeLabel: MarketDataMode.demo.label,
    exportFormat: format,
    includedSections: const [
      'Paper trading',
      'Journal',
      'Options portfolio',
      'Performance',
      'Sync',
      'Auth',
    ],
    paperTradingAccount: paperTradingAccount,
    journalEntries: journalEntries,
    optionsPortfolioAccount: optionsPortfolioAccount,
    performanceSnapshot: performance,
    optionsIncomeAnalytics: optionsIncome,
    behaviorAnalytics: behaviorAnalytics,
    syncMetadata: syncMetadata,
    authSession: authSession,
  );
}

Widget _exportHarness() {
  final marketState = MarketState();
  final paperState = PaperTradingState();
  final journalState = JournalState();
  final optionsState = OptionsPortfolioState();
  final syncState = SyncState(
    repository: LocalSyncRepository(store: MemorySyncStore()),
  );
  final authState = AuthState(
    repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
    syncState: syncState,
  );
  final insightsState = InsightsState(
    journalState: journalState,
    paperTradingState: paperState,
    optionsState: optionsState,
    marketState: marketState,
  );

  return AuthScope(
    state: authState,
    child: SyncScope(
      state: syncState,
      child: MarketScope(
        state: marketState,
        child: JournalScope(
          state: journalState,
          child: OptionsPortfolioScope(
            state: optionsState,
            child: PaperTradingScope(
              state: paperState,
              child: InsightsScope(
                state: insightsState,
                child: MaterialApp(
                  theme: ThemeData.dark(useMaterial3: true),
                  routes: {
                    ExportReportsScreen.routeName: (_) =>
                        const ExportReportsScreen(),
                    SettingsScreen.routeName: (_) => const SettingsScreen(),
                  },
                  home: const ExportReportsScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _settingsHarness() {
  final marketState = MarketState();
  final paperState = PaperTradingState();
  final journalState = JournalState();
  final optionsState = OptionsPortfolioState();
  final syncState = SyncState(
    repository: LocalSyncRepository(store: MemorySyncStore()),
  );
  final authState = AuthState(
    repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
    syncState: syncState,
  );
  final insightsState = InsightsState(
    journalState: journalState,
    paperTradingState: paperState,
    optionsState: optionsState,
    marketState: marketState,
  );

  return AuthScope(
    state: authState,
    child: SyncScope(
      state: syncState,
      child: MarketScope(
        state: marketState,
        child: JournalScope(
          state: journalState,
          child: OptionsPortfolioScope(
            state: optionsState,
            child: PaperTradingScope(
              state: paperState,
              child: InsightsScope(
                state: insightsState,
                child: MaterialApp(
                  theme: ThemeData.dark(useMaterial3: true),
                  routes: {
                    ExportReportsScreen.routeName: (_) =>
                        const ExportReportsScreen(),
                  },
                  home: const SettingsScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
