import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/auth_state.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/onboarding/onboarding_state.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/sync_state.dart';
import 'package:trading_app/features/legal/disclaimer_screen.dart';
import 'package:trading_app/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('disclaimer screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DisclaimerScreen()));
    expect(find.text('Disclaimer'), findsOneWidget);
    expect(find.text('Not financial advice'), findsOneWidget);
    expect(find.text('Paper trading only'), findsWidgets);
  });

  testWidgets('data privacy screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DataPrivacyScreen()));
    expect(find.text('Data & privacy'), findsOneWidget);
    expect(find.text('Local-first by default'), findsOneWidget);
    expect(find.text('Support contact'), findsOneWidget);
  });

  testWidgets('settings can reopen onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final onboardingState = OnboardingState();

    await tester.pumpWidget(
      AuthScope(
        state: AuthState(
          repository: LocalDemoAuthRepository(store: MemoryAuthStore()),
        ),
        child: OnboardingScope(
          state: onboardingState,
          child: SyncScope(
            state: SyncState(
              repository: LocalSyncRepository(store: MemorySyncStore()),
            ),
            child: MarketScope(
              state: MarketState(),
              child: PaperTradingScope(
                state: PaperTradingState(),
                child: const MaterialApp(home: SettingsScreen()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('View onboarding again'));
    await tester.pumpAndSettle();
    final onboardingCard = find.ancestor(
      of: find.text('View onboarding again'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: onboardingCard, matching: find.byType(FilledButton)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to ClearTrade'), findsOneWidget);
  });
}
