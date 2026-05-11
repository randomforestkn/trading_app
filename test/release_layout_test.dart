import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/data/auth_state.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/insights/insights_state.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/onboarding/local_onboarding_repository.dart';
import 'package:trading_app/core/onboarding/onboarding_progress.dart';
import 'package:trading_app/core/onboarding/onboarding_store.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/sync_state.dart';
import 'package:trading_app/features/export_reports/export_reports_screen.dart';
import 'package:trading_app/features/insights/insights_screen.dart';
import 'package:trading_app/features/journal/journal_screen.dart';
import 'package:trading_app/features/options_portfolio/options_portfolio_screen.dart';
import 'package:trading_app/features/settings/settings_screen.dart';

void main() {
  testWidgets('wide layout renders key screens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final onboardingRepository = LocalOnboardingRepository(
      store: MemoryOnboardingStore(),
    );
    await onboardingRepository.saveProgress(
      OnboardingProgress(
        viewedVersion: AppConfig.onboardingVersion,
        acceptedVersion: AppConfig.onboardingVersion,
        viewedAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      TradingApp(onboardingRepository: onboardingRepository),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final marketState = MarketState();
    final paperState = PaperTradingState();
    final journalState = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );
    final authState = AuthState(
      repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
    );
    final syncState = SyncState(
      repository: LocalSyncRepository(store: MemorySyncStore()),
    );
    final insightsState = InsightsState(
      journalState: journalState,
      paperTradingState: paperState,
      optionsState: optionsState,
      marketState: marketState,
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
    expect(tester.takeException(), isNull);

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
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      InsightsScope(
        state: insightsState,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const InsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      AuthScope(
        state: authState,
        child: SyncScope(
          state: syncState,
          child: MarketScope(
            state: marketState,
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
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
