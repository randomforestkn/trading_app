import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/models/asset.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/option_position.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/strategies/option_strategy.dart';
import 'package:trading_app/features/options_portfolio/option_position_editor_screen.dart';
import 'package:trading_app/features/options_portfolio/options_portfolio_screen.dart';

void main() {
  testWidgets('Options portfolio screen renders empty state', (tester) async {
    final marketState = MarketState();
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );

    await tester.pumpWidget(
      _harness(
        marketState: marketState,
        optionsState: optionsState,
        child: const OptionsPortfolioScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Options portfolio'), findsOneWidget);
    expect(find.text('No option positions yet'), findsOneWidget);
  });

  testWidgets('Options portfolio screen renders populated positions', (
    tester,
  ) async {
    final marketState = MarketState(
      initialAssets: [_asset('AAPL', 'Apple Inc.', 100)],
    );
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );
    await optionsState.addPosition(
      OptionPosition(
        id: 'opt-1',
        underlyingSymbol: 'AAPL',
        underlyingName: 'Apple Inc.',
        optionType: OptionType.put,
        side: OptionSide.sell,
        strikePrice: 95,
        premium: 3,
        contractsCount: 1,
        openedAt: DateTime(2026, 1, 1),
        expirationDate: DateTime(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.cashSecuredPut,
      ),
    );

    await tester.pumpWidget(
      _harness(
        marketState: marketState,
        optionsState: optionsState,
        child: const OptionsPortfolioScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Premium income overview'), findsOneWidget);
    expect(find.text('AAPL 95 Put'), findsWidgets);
    expect(find.text('Open positions'), findsOneWidget);
  });

  testWidgets('Create option position validation blocks invalid input', (
    tester,
  ) async {
    final marketState = MarketState();
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );

    await tester.pumpWidget(
      _harness(
        marketState: marketState,
        optionsState: optionsState,
        child: const OptionPositionEditorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), '0');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Contracts must be greater than zero.'), findsOneWidget);
    expect(optionsState.allPositions, isEmpty);
  });

  testWidgets('Lifecycle confirmation closes a position', (tester) async {
    final marketState = MarketState(
      initialAssets: [_asset('AAPL', 'Apple Inc.', 100)],
    );
    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );
    await optionsState.addPosition(
      OptionPosition(
        id: 'opt-1',
        underlyingSymbol: 'AAPL',
        underlyingName: 'Apple Inc.',
        optionType: OptionType.put,
        side: OptionSide.sell,
        strikePrice: 95,
        premium: 3,
        contractsCount: 1,
        openedAt: DateTime(2026, 1, 1),
        expirationDate: DateTime(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.cashSecuredPut,
      ),
    );

    await tester.pumpWidget(
      _harness(
        marketState: marketState,
        optionsState: optionsState,
        child: const OptionsPortfolioScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final closeButton = find.text('Close').first;
    await tester.ensureVisible(closeButton);
    await tester.pumpAndSettle();
    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(find.text('Close option position?'), findsOneWidget);
    await tester.tap(find.text('Close position'));
    await tester.pumpAndSettle();

    expect(
      optionsState.positionById('opt-1')?.status,
      OptionPositionStatus.closed,
    );
  });
}

Widget _harness({
  required MarketState marketState,
  required OptionsPortfolioState optionsState,
  required Widget child,
}) {
  return MarketScope(
    state: marketState,
    child: OptionsPortfolioScope(
      state: optionsState,
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: child,
      ),
    ),
  );
}

TradingAsset _asset(String symbol, String name, double price) {
  return TradingAsset(
    symbol: symbol,
    name: name,
    type: AssetType.stock,
    price: price,
    dailyChangePercent: 0.5,
    open: price - 1,
    high: price + 1,
    low: price - 2,
    volume: '1.2B',
    marketCap: '3.2T',
    trend: const [96, 98, 100],
    explanation: name,
    stats: const {},
  );
}
