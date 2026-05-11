import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/data/auth_state.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/export/export_bundle.dart';
import 'package:trading_app/core/export/export_format.dart';
import 'package:trading_app/core/export/json_backup_exporter.dart';
import 'package:trading_app/core/import/backup_parser.dart';
import 'package:trading_app/core/insights/insights_state.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/models/app_user.dart';
import 'package:trading_app/core/models/auth_session.dart';
import 'package:trading_app/core/models/asset.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/models/portfolio_position.dart';
import 'package:trading_app/core/onboarding/local_onboarding_repository.dart';
import 'package:trading_app/core/onboarding/onboarding_state.dart';
import 'package:trading_app/core/onboarding/onboarding_store.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/option_position.dart';
import 'package:trading_app/core/options_portfolio/option_trade.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_account.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/sync_metadata.dart';
import 'package:trading_app/core/sync/sync_state.dart';
import 'package:trading_app/core/sync/sync_status.dart';
import 'package:trading_app/features/activity/activity_screen.dart';
import 'package:trading_app/features/export_reports/export_reports_screen.dart';
import 'package:trading_app/features/journal/journal_screen.dart';
import 'package:trading_app/features/options_portfolio/options_portfolio_screen.dart';
import 'package:trading_app/features/portfolio/portfolio_screen.dart';
import 'package:trading_app/features/settings/settings_screen.dart';

void main() {
  testWidgets('first launch onboarding accepts and opens home shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final onboardingRepository = LocalOnboardingRepository(
      store: MemoryOnboardingStore(),
    );
    final onboardingState = OnboardingState(repository: onboardingRepository);
    await onboardingState.accept();

    await tester.pumpWidget(
      TradingApp(onboardingRepository: onboardingRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Refresh prices'), findsOneWidget);
  });

  testWidgets('buy paper trade updates portfolio and activity', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final marketState = MarketState();
    final paperState = PaperTradingState(
      initialCashBalance: 10000,
      initialPositions: const [],
    );
    final asset = MockMarketData.assets.first;
    await marketState.loadAssets();

    await paperState.executeOrder(
      asset: marketState.latestFor(asset),
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: marketState.latestFor(asset).price,
    );

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: const PortfolioScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(asset.symbol), findsOneWidget);
    expect(find.text('Cash balance'), findsOneWidget);

    await tester.pumpWidget(
      PaperTradingScope(
        state: paperState,
        child: const MaterialApp(home: ActivityScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filled'), findsWidgets);
    expect(find.text('Buy'), findsWidgets);
  });

  testWidgets('create journal entry adds it to the list', (tester) async {
    final journalState = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );
    await journalState.addEntry(
      JournalEntry(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        title: 'Trade review',
        body: 'I followed the plan.',
      ),
    );

    await tester.pumpWidget(
      JournalScope(
        state: journalState,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const JournalScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(journalState.entries, hasLength(1));
    expect(find.text('Trade review'), findsWidgets);
  });

  testWidgets('create option position adds it to the portfolio', (
    tester,
  ) async {
    final marketState = MarketState();
    await marketState.loadAssets();
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );
    final asset = MockMarketData.assets.first;

    await optionsState.addPosition(
      OptionPosition(
        id: '',
        underlyingSymbol: asset.symbol,
        optionType: OptionType.put,
        side: OptionSide.sell,
        strikePrice: asset.price * 0.95,
        premium: 1.25,
        contractsCount: 1,
        openedAt: DateTime.now(),
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        status: OptionPositionStatus.open,
      ),
    );

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: OptionsPortfolioScope(
          state: optionsState,
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: const OptionsPortfolioScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(optionsState.openPositions, hasLength(1));
    expect(find.text('Open positions'), findsOneWidget);
  });

  testWidgets('generate export and validate restore preview', (tester) async {
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
    await marketState.loadAssets();

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
      paperTradingAccount: PaperTradingAccount(
        startingCash: 10000,
        cashBalance: 9450,
        positions: [
          PortfolioPosition(
            asset: assetForExport,
            quantity: 5,
            averagePrice: assetForExport.price,
          ),
        ],
        orders: [
          PaperOrder(
            assetSymbol: assetForExport.symbol,
            assetName: assetForExport.name,
            side: PaperOrderSide.buy,
            quantity: 5,
            executionPrice: assetForExport.price,
            estimatedTotal: assetForExport.price * 5,
            timestamp: DateTime.utc(2026, 1, 1),
            status: PaperOrderStatus.filled,
          ),
        ],
        lastUpdated: DateTime.utc(2026, 1, 2),
      ),
      journalEntries: [
        JournalEntry(
          id: 'j-1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
          title: 'Wheel review',
          body: 'Executed according to plan.',
        ),
      ],
      optionsPortfolioAccount: OptionsPortfolioAccount(
        positions: [
          OptionPosition(
            id: 'opt-1',
            underlyingSymbol: assetForExport.symbol,
            optionType: OptionType.put,
            side: OptionSide.sell,
            strikePrice: assetForExport.price * 0.95,
            premium: 1.25,
            contractsCount: 1,
            openedAt: DateTime.utc(2026, 1, 1),
            expirationDate: DateTime.utc(2026, 2, 1),
            status: OptionPositionStatus.open,
          ),
        ],
        trades: [
          OptionTrade(
            id: 'trade-1',
            positionId: 'opt-1',
            createdAt: DateTime.utc(2026, 1, 1),
            eventType: OptionTradeEventType.open,
            premium: 125,
            quantity: 1,
          ),
        ],
        wheelCycles: const [],
        lastUpdated: DateTime.utc(2026, 1, 2),
      ),
      syncMetadata: SyncMetadata(
        lastSyncedAt: DateTime.utc(2026, 1, 2),
        lastAttemptedAt: DateTime.utc(2026, 1, 2),
        pendingOperationsCount: 0,
        lastError: null,
        deviceId: 'device-1',
        userId: AppConfig.demoUserId,
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

    final json = JsonBackupExporter.encode(bundle);
    final result = BackupParser.parse(json);
    expect(result.when(success: (_) => true, failure: (_) => false), isTrue);

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
    expect(find.text('Export & reports'), findsOneWidget);
  });

  testWidgets('demo sign in and sign out confirmation work', (tester) async {
    final authState = AuthState(
      repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
    );
    await authState.signInDemo();
    final syncState = SyncState(
      repository: LocalSyncRepository(store: MemorySyncStore()),
    );
    final marketState = MarketState();
    final paperState = PaperTradingState();
    final journalState = JournalState();
    final optionsState = OptionsPortfolioState();
    final onboardingState = OnboardingState();
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
            child: OnboardingScope(
              state: onboardingState,
              child: PaperTradingScope(
                state: paperState,
                child: JournalScope(
                  state: journalState,
                  child: OptionsPortfolioScope(
                    state: optionsState,
                    child: InsightsScope(
                      state: insightsState,
                      child: MaterialApp(
                        theme: ThemeData.dark(useMaterial3: true),
                        home: const SettingsScreen(),
                      ),
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

    expect(find.text('Demo Trader'), findsOneWidget);
    await authState.signOut();
    await tester.pumpAndSettle();

    expect(find.text('Signed out'), findsWidgets);
    expect(find.text('Disclaimer'), findsOneWidget);
    expect(find.text('Data & privacy'), findsOneWidget);
    expect(find.text('RC readiness'), findsOneWidget);
  });

  testWidgets('settings legal and diagnostics render', (tester) async {
    final authState = AuthState(
      repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
    );
    final onboardingState = OnboardingState();
    final syncState = SyncState(
      repository: LocalSyncRepository(store: MemorySyncStore()),
    );
    final marketState = MarketState();
    final paperState = PaperTradingState();
    final journalState = JournalState();
    final optionsState = OptionsPortfolioState();
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
            child: OnboardingScope(
              state: onboardingState,
              child: PaperTradingScope(
                state: paperState,
                child: JournalScope(
                  state: journalState,
                  child: OptionsPortfolioScope(
                    state: optionsState,
                    child: InsightsScope(
                      state: insightsState,
                      child: MaterialApp(
                        theme: ThemeData.dark(useMaterial3: true),
                        home: const SettingsScreen(),
                      ),
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

    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('RC readiness'), findsOneWidget);
  });
}

final TradingAsset assetForExport = MockMarketData.assets.first;
