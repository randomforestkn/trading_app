import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/widgets/mini_trend_chart.dart';

void main() {
  testWidgets('mini trend chart renders compactly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 80,
            height: 44,
            child: MiniTrendChart(
              points: [100, 101, 99, 102, 103],
              isPositive: true,
              width: 64,
              height: 36,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MiniTrendChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
