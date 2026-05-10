import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/onboarding/local_onboarding_repository.dart';
import 'package:trading_app/core/onboarding/onboarding_progress.dart';
import 'package:trading_app/core/onboarding/onboarding_state.dart';
import 'package:trading_app/core/onboarding/onboarding_store.dart';
import 'package:trading_app/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('onboarding screen renders', (tester) async {
    final onboardingState = OnboardingState(
      repository: LocalOnboardingRepository(store: MemoryOnboardingStore()),
    );

    await tester.pumpWidget(
      OnboardingScope(
        state: onboardingState,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('Welcome to ${AppConfig.appName}'), findsOneWidget);
    expect(find.text('Agree and continue'), findsOneWidget);
    expect(find.text('Paper trading only'), findsWidgets);
  });

  testWidgets('onboarding acceptance persists', (tester) async {
    final store = MemoryOnboardingStore();
    final onboardingState = OnboardingState(
      repository: LocalOnboardingRepository(store: store),
    );

    await tester.pumpWidget(
      OnboardingScope(
        state: onboardingState,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const OnboardingScreen(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Agree and continue'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        CheckboxListTile,
        'I understand this is paper trading only.',
      ),
    );
    await tester.pump();
    await tester.tap(
      find.widgetWithText(
        CheckboxListTile,
        'I understand this is not investment advice.',
      ),
    );
    await tester.pump();
    await tester.tap(
      find.widgetWithText(
        CheckboxListTile,
        'I understand local data and backups are my responsibility.',
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Agree and continue'));
    await tester.pumpAndSettle();

    final reloaded = OnboardingState(
      repository: LocalOnboardingRepository(store: store),
    );
    await reloaded.load();

    expect(reloaded.isAccepted, isTrue);
    expect(reloaded.acceptedAt, isNotNull);
  });

  testWidgets('TradingApp shows onboarding before acceptance', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TradingApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to ${AppConfig.appName}'), findsOneWidget);
    expect(find.text('Agree and continue'), findsOneWidget);
  });

  testWidgets('TradingApp skips onboarding after acceptance', (tester) async {
    SharedPreferences.setMockInitialValues({});
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

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
