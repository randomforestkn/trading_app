import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/onboarding/local_onboarding_repository.dart';
import 'package:trading_app/core/onboarding/onboarding_progress.dart';
import 'package:trading_app/core/onboarding/onboarding_store.dart';

void main() {
  testWidgets('shows trading app shell', (WidgetTester tester) async {
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
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.byTooltip('Refresh prices'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Activity'), findsOneWidget);
  });
}
