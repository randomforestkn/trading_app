import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/core/config/app_config.dart';

void main() {
  testWidgets('shows trading app shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TradingApp());
    await tester.pumpAndSettle();

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
  });
}
