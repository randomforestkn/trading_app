import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/data/auth_state.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/paper_trading_store.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/export/export_bundle.dart';
import 'package:trading_app/core/export/export_format.dart';
import 'package:trading_app/core/export/json_backup_exporter.dart';
import 'package:trading_app/core/import/backup_parser.dart';
import 'package:trading_app/core/import/local_import_repository.dart';
import 'package:trading_app/core/insights/insights_state.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/models/app_user.dart';
import 'package:trading_app/core/models/auth_session.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/models/portfolio_position.dart';
import 'package:trading_app/core/options_portfolio/option_position.dart';
import 'package:trading_app/core/options_portfolio/option_trade.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_account.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/core/options_portfolio/wheel_cycle.dart';
import 'package:trading_app/core/sync/sync_metadata.dart';
import 'package:trading_app/core/sync/sync_state.dart';
import 'package:trading_app/core/sync/sync_status.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/strategies/option_strategy.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/features/export_reports/export_reports_screen.dart';

void main() {
  test('valid JSON backup parses into a restore plan', () {
    final result = BackupParser.parse(_sampleBackupJson());

    final plan = result.when(success: (plan) => plan, failure: (_) => null);

    expect(plan, isNotNull);
    expect(plan!.backupVersion, AppConfig.backupFormatVersion);
    expect(plan.paperOrdersCount, 1);
    expect(plan.journalEntriesCount, 1);
    expect(plan.optionsPositionsCount, 1);
    expect(plan.optionsTradesCount, 1);
    expect(plan.wheelCyclesCount, 1);
  });

  test('invalid JSON fails safely', () {
    final result = BackupParser.parse('{bad json');

    expect(
      result.when(success: (_) => false, failure: (message) => message),
      isA<String>(),
    );
  });

  test('missing required sections fails safely', () {
    final result = BackupParser.parse(
      '{"backupVersion":1,"export":{"createdAt":"2026-01-01T00:00:00.000Z","format":"jsonBackup","includedSections":["Paper trading"]}}',
    );

    expect(
      result.when(success: (_) => false, failure: (message) => message),
      isA<String>(),
    );
  });

  test('restore replaces paper trading journal and options data', () async {
    SharedPreferences.setMockInitialValues({});

    final paperStore = MemoryPaperTradingStore();
    final journalStore = MemoryJournalStore();
    final optionsStore = MemoryOptionsPortfolioStore();
    final syncStore = MemorySyncStore();
    final authStore = MemoryAuthStore();

    final syncState = SyncState(
      repository: LocalSyncRepository(store: syncStore),
    );
    final paperState = PaperTradingState(
      initialCashBalance: 1,
      initialPositions: const [],
      repository: LocalPaperTradingRepository(store: paperStore),
      syncState: syncState,
    );
    final journalState = JournalState(
      repository: LocalJournalRepository(store: journalStore),
      syncState: syncState,
    );
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(store: optionsStore),
      syncState: syncState,
    );
    final authState = AuthState(
      repository: LocalDemoAuthRepository(store: authStore),
      syncState: syncState,
    );
    await authState.signInDemo();
    await journalState.addEntry(
      JournalEntry(
        id: 'old',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        title: 'Old note',
        body: 'Old body',
      ),
    );

    final repository = LocalImportRepository(
      paperTradingState: paperState,
      journalState: journalState,
      optionsPortfolioState: optionsState,
      authState: authState,
      syncState: syncState,
    );
    final result = await repository.restoreBackup(_sampleBackupJson());

    final restored = result.when(success: (data) => data, failure: (_) => null);
    expect(restored, isNotNull);
    expect(restored!.message, contains('Restored'));
    expect(paperState.cashBalance, 9450);
    expect(paperState.orders, hasLength(1));
    expect(journalState.entries, hasLength(1));
    expect(optionsState.openPositions, hasLength(1));
    expect(authState.isAuthenticated, isTrue);
    expect(syncState.pendingOperations, isNotEmpty);
  });

  testWidgets('ExportReportsScreen restore flow validates and applies backup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final paperState = PaperTradingState();
    final journalState = JournalState();
    final optionsState = OptionsPortfolioState();
    final marketState = MarketState();
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

    await tester.pumpWidget(
      AuthScope(
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
                      home: const ExportReportsScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), _sampleBackupJson());
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Validate backup'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Validate backup'));
    await tester.pumpAndSettle();

    expect(find.text('Restore preview'), findsOneWidget);
    expect(find.text('Paper orders'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Restore backup'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Restore backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restore backup').last);
    await tester.pumpAndSettle();

    expect(paperState.cashBalance, 9450);
    expect(journalState.entries, hasLength(1));
    expect(optionsState.openPositions, hasLength(1));
  });
}

String _sampleBackupJson() {
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

  final bundle = ExportBundle(
    createdAt: DateTime.utc(2026, 1, 2),
    appVersionLabel: AppConfig.appVersionLabel,
    buildModeLabel: AppConfig.buildModeLabel,
    marketModeLabel: MarketDataMode.demo.label,
    exportFormat: ExportFormat.jsonBackup,
    includedSections: const [
      'Paper trading',
      'Journal',
      'Options portfolio',
      'Sync',
      'Auth',
    ],
    paperTradingAccount: paperTradingAccount,
    journalEntries: journalEntries,
    optionsPortfolioAccount: optionsPortfolioAccount,
    syncMetadata: SyncMetadata(
      lastSyncedAt: DateTime.utc(2026, 1, 2),
      lastAttemptedAt: DateTime.utc(2026, 1, 2),
      pendingOperationsCount: 1,
      lastError: null,
      deviceId: 'device-1',
      userId: 'demo-user',
      syncMode: SyncMode.localOnly,
    ),
    authSession: AuthSession(
      user: AppUser(
        id: AppConfig.demoUserId,
        email: AppConfig.demoUserEmail,
        displayName: AppConfig.demoUserDisplayName,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      createdAt: DateTime.utc(2026, 1, 2),
    ),
  );

  return JsonBackupExporter.encode(bundle);
}
