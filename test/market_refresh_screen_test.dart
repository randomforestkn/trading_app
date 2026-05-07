import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/models/asset.dart';
import 'package:trading_app/features/home/home_screen.dart';
import 'package:trading_app/features/portfolio/portfolio_screen.dart';
import 'package:trading_app/features/watchlist/watchlist_screen.dart';

void main() {
  testWidgets('Home renders after price refresh', (tester) async {
    final marketState = MarketState(movementGenerator: (_) => 0.01);
    await marketState.refreshPrices();

    await tester.pumpWidget(_harness(marketState, const HomeScreen()));

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('Refresh prices'), findsOneWidget);
    expect(find.text('Biggest gainer'), findsOneWidget);
    expect(
      find.textContaining(AppConfig.paperTradingDisclaimer),
      findsOneWidget,
    );
  });

  testWidgets('Watchlist renders after price refresh', (tester) async {
    final marketState = MarketState(movementGenerator: (_) => 0.01);
    await marketState.refreshPrices();

    await tester.pumpWidget(_harness(marketState, const WatchlistScreen()));

    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('watchlist no-results state renders', (tester) async {
    final marketState = MarketState();

    await tester.pumpWidget(_harness(marketState, const WatchlistScreen()));
    await tester.enterText(find.byType(TextField), 'ZZZ-NO-MATCH');
    await tester.pump();

    expect(find.text('No assets match this search.'), findsOneWidget);
  });

  testWidgets('portfolio empty state renders when no positions exist', (
    tester,
  ) async {
    final marketState = MarketState();
    final paperState = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
    );

    await tester.pumpWidget(
      _harness(marketState, const PortfolioScreen(), paperState: paperState),
    );

    expect(
      find.text('No open positions yet. Place a paper trade to begin.'),
      findsOneWidget,
    );
  });

  testWidgets('Home shows safe repository failure state', (tester) async {
    final marketState = MarketState(repository: _FailingMarketRepository());

    await tester.pumpWidget(_harness(marketState, const HomeScreen()));
    await tester.tap(find.byTooltip('Refresh prices'));
    await tester.pumpAndSettle();

    expect(find.text('Market data unavailable'), findsWidgets);
    expect(find.text(AppConfig.appName), findsOneWidget);
  });
}

Widget _harness(
  MarketState marketState,
  Widget child, {
  PaperTradingState? paperState,
}) {
  return MarketScope(
    state: marketState,
    child: PaperTradingScope(
      state: paperState ?? PaperTradingState(),
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: child,
      ),
    ),
  );
}

class _FailingMarketRepository implements MarketRepository {
  @override
  MarketDataMode get mode => MarketDataMode.remote;

  @override
  Future<AppResult<List<TradingAsset>>> loadAssets() async {
    return const AppFailure('Market data unavailable');
  }

  @override
  Future<AppResult<List<TradingAsset>>> refreshPrices(
    List<TradingAsset> currentAssets,
  ) async {
    return const AppFailure('Market data unavailable');
  }
}
