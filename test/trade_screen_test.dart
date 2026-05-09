import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/widgets/app_buttons.dart';
import 'package:trading_app/features/trade/trade_screen.dart';

void main() {
  testWidgets('invalid quantity disables submit and shows validation', (
    tester,
  ) async {
    final state = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
    );

    await tester.pumpWidget(_tradeHarness(state));
    await tester.enterText(find.byKey(const Key('trade_quantity_field')), '0');
    await tester.pump();

    expect(find.text('Quantity must be greater than zero.'), findsOneWidget);
    final submit = tester.widget<AppPrimaryButton>(
      find.byKey(const Key('trade_submit_button')),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('valid trade opens confirmation flow', (tester) async {
    final state = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
    );

    await tester.pumpWidget(_tradeHarness(state));
    await _scrollToSubmit(tester);
    await tester.tap(find.byKey(const Key('trade_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Review paper order'), findsOneWidget);
    expect(find.text('Cash after order'), findsOneWidget);
    expect(
      find.byKey(const Key('trade_confirm_execution_button')),
      findsOneWidget,
    );
  });

  testWidgets('confirmed trade updates portfolio state', (tester) async {
    final asset = MockMarketData.assets.first;
    final state = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
    );

    await tester.pumpWidget(_tradeHarness(state));
    await _scrollToSubmit(tester);
    await tester.tap(find.byKey(const Key('trade_submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trade_confirm_execution_button')));
    await tester.pumpAndSettle();

    expect(state.quantityFor(asset.symbol), 1);
    expect(state.cashBalance, closeTo(1000 - asset.price, 0.001));
    expect(state.orders.single.side, PaperOrderSide.buy);
  });
}

Future<void> _scrollToSubmit(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -360));
  await tester.pumpAndSettle();
}

Widget _tradeHarness(PaperTradingState state) {
  final asset = MockMarketData.assets.first;

  return MarketScope(
    state: MarketState(),
    child: PaperTradingScope(
      state: state,
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: TradeScreen(asset: asset, initialSide: PaperOrderSide.buy),
      ),
    ),
  );
}
