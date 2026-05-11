import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/data/auth_state.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/data/paper_trading_store.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/onboarding/onboarding_state.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/sync_state.dart';
import 'package:trading_app/features/settings/settings_screen.dart';

void main() {
  testWidgets('Settings screen renders', (tester) async {
    await tester.pumpWidget(_settingsHarness(PaperTradingState()));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Paper account'), findsOneWidget);
    expect(find.text('App information'), findsOneWidget);
    expect(find.text(AppConfig.appVersionLabel), findsOneWidget);
    expect(find.text(AppConfig.buildModeLabel), findsWidgets);
    expect(find.text(AppConfig.buildConfig.buildLabel), findsWidgets);
    expect(find.text('Flavor'), findsOneWidget);
    expect(find.text('Test/demo mode'), findsOneWidget);
    expect(find.text(AppConfig.paperTradingDisclaimer), findsOneWidget);
    expect(find.text(AppConfig.syncDisclaimer), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Local only'), findsWidgets);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Disclaimer'), findsWidgets);
    expect(find.text('Data & privacy'), findsOneWidget);
    expect(find.text('View onboarding again'), findsOneWidget);
    expect(find.text('Export data / reports'), findsOneWidget);
    expect(find.text('Import / restore backup'), findsOneWidget);
    expect(find.text(AppConfig.supportUrlPlaceholder), findsOneWidget);
  });

  testWidgets('Settings shows signed-in user', (tester) async {
    final authState = AuthState(
      repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
    );
    await authState.signInDemo();

    await tester.pumpWidget(
      _settingsHarness(PaperTradingState(), authState: authState),
    );

    expect(find.text('Demo Trader'), findsOneWidget);
    expect(find.text('demo@cleartrade.local'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Settings shows signed-out state', (tester) async {
    await tester.pumpWidget(_settingsHarness(PaperTradingState()));

    expect(find.text('Signed out'), findsWidgets);
    expect(find.text('Sign in demo account'), findsOneWidget);
  });

  testWidgets('sign out does not erase paper trading portfolio', (
    tester,
  ) async {
    final authState = AuthState(
      repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
    );
    await authState.signInDemo();
    final paperState = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
    );
    await paperState.executeOrder(
      asset: MockMarketData.assets.first,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: 100,
    );
    final cashBeforeSignOut = paperState.cashBalance;
    final quantityBeforeSignOut = paperState.positions.single.quantity;

    await tester.pumpWidget(_settingsHarness(paperState, authState: authState));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(authState.isAuthenticated, isFalse);
    expect(paperState.cashBalance, cashBeforeSignOut);
    expect(paperState.positions.single.quantity, quantityBeforeSignOut);
  });

  testWidgets('reset portfolio works from Settings', (tester) async {
    final state = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
    );
    await state.executeOrder(
      asset: MockMarketData.assets.first,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: 100,
    );

    await tester.pumpWidget(_settingsHarness(state));
    await _scrollSettings(tester, -360);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset').first);
    await tester.pumpAndSettle();
    expect(find.text('Reset paper portfolio?'), findsOneWidget);
    await tester.tap(find.text('Reset portfolio'));
    await tester.pumpAndSettle();

    expect(state.cashBalance, PaperTradingState.defaultCashBalance);
    expect(state.positions.length, MockMarketData.positions.length);
    expect(state.orders, isEmpty);
  });

  testWidgets('clear order history keeps cash and positions', (tester) async {
    final store = MemoryPaperTradingStore();
    final repository = LocalPaperTradingRepository(store: store);
    final state = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
      repository: repository,
    );
    await state.executeOrder(
      asset: MockMarketData.assets.first,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: 100,
    );
    final cashAfterTrade = state.cashBalance;
    final quantityAfterTrade = state.positions.single.quantity;

    await tester.pumpWidget(_settingsHarness(state));
    await _scrollSettings(tester, -460);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Clear order history?'), findsOneWidget);
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();

    final restored = await PaperTradingState.load(repository: repository);
    expect(state.orders, isEmpty);
    expect(state.cashBalance, cashAfterTrade);
    expect(state.positions.single.quantity, quantityAfterTrade);
    expect(restored.orders, isEmpty);
    expect(restored.cashBalance, cashAfterTrade);
    expect(restored.positions.single.quantity, quantityAfterTrade);
  });
}

Future<void> _scrollSettings(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView), Offset(0, dy));
  await tester.pumpAndSettle();
}

Widget _settingsHarness(PaperTradingState state, {AuthState? authState}) {
  final onboardingState = OnboardingState();
  return AuthScope(
    state:
        authState ??
        AuthState(
          repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
        ),
    child: SyncScope(
      state: SyncState(
        repository: LocalSyncRepository(store: MemorySyncStore()),
      ),
      child: MarketScope(
        state: MarketState(),
        child: OnboardingScope(
          state: onboardingState,
          child: PaperTradingScope(
            state: state,
            child: MaterialApp(
              theme: ThemeData.dark(useMaterial3: true),
              home: const SettingsScreen(),
            ),
          ),
        ),
      ),
    ),
  );
}
