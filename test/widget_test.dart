import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/trading_app.dart';

void main() {
  testWidgets('shows trading app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const TradingApp());

    expect(find.text('ClearTrade'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
  });
}
