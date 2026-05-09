import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/analytics/trading_analytics.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_store.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/models/portfolio_position.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/features/analytics/analytics_screen.dart';

void main() {
  test('portfolio analytics calculates live values and risk metrics', () {
    final marketState = MarketState();
    final asset = MockMarketData.assets.first;
    final etf = MockMarketData.assets[1];
    final paperState = PaperTradingState.fromAccount(
      PaperTradingAccount(
        startingCash: 5000,
        cashBalance: 4062.66,
        positions: [
          PortfolioPosition(asset: asset, quantity: 2, averagePrice: 100),
          PortfolioPosition(asset: etf, quantity: 1, averagePrice: 450),
        ],
        orders: [
          PaperOrder(
            assetSymbol: asset.symbol,
            assetName: asset.name,
            side: PaperOrderSide.sell,
            quantity: 1,
            executionPrice: 140,
            estimatedTotal: 140,
            timestamp: DateTime(2025, 1, 3, 10),
            status: PaperOrderStatus.filled,
            averageCostAtExecution: 100,
            realizedProfitLoss: 40,
          ),
        ],
        lastUpdated: DateTime(2025, 1, 3, 10),
      ),
      repository: const LocalPaperTradingRepository(),
    );

    final analytics = TradingAnalytics.portfolio(
      tradingState: paperState,
      marketState: marketState,
    );

    expect(analytics.openPositionsCount, 2);
    expect(analytics.totalPortfolioValue, closeTo(5000, 0.01));
    expect(analytics.realizedProfitLoss, closeTo(40, 0.01));
    expect(analytics.unrealizedProfitLoss, closeTo(287.34, 0.01));
    expect(analytics.totalProfitLoss, closeTo(327.34, 0.01));
    expect(analytics.concentrationRiskPercent, greaterThan(0));
    expect(analytics.largestPosition?.asset.symbol, etf.symbol);
    expect(analytics.bestPosition?.asset.symbol, asset.symbol);
  });

  test('activity analytics calculates buy and sell mix', () {
    final paperState = PaperTradingState.fromAccount(
      PaperTradingAccount(
        startingCash: 1000,
        cashBalance: 900,
        positions: const [],
        orders: [
          PaperOrder(
            assetSymbol: 'AAPL',
            assetName: 'Apple Inc.',
            side: PaperOrderSide.buy,
            quantity: 2,
            executionPrice: 100,
            estimatedTotal: 200,
            timestamp: DateTime(2025, 1, 1, 10),
            status: PaperOrderStatus.filled,
          ),
          PaperOrder(
            assetSymbol: 'AAPL',
            assetName: 'Apple Inc.',
            side: PaperOrderSide.sell,
            quantity: 1,
            executionPrice: 120,
            estimatedTotal: 120,
            timestamp: DateTime(2025, 1, 2, 10),
            status: PaperOrderStatus.filled,
            averageCostAtExecution: 100,
            realizedProfitLoss: 20,
          ),
          PaperOrder(
            assetSymbol: 'VOO',
            assetName: 'Vanguard S&P 500 ETF',
            side: PaperOrderSide.buy,
            quantity: 1,
            executionPrice: 500,
            estimatedTotal: 500,
            timestamp: DateTime(2025, 1, 3, 10),
            status: PaperOrderStatus.filled,
          ),
        ],
        lastUpdated: DateTime(2025, 1, 3, 10),
      ),
      repository: const LocalPaperTradingRepository(),
    );

    final activity = TradingAnalytics.activity(tradingState: paperState);

    expect(activity.totalOrders, 3);
    expect(activity.buyOrderCount, 2);
    expect(activity.sellOrderCount, 1);
    expect(activity.totalBuyVolume, closeTo(700, 0.01));
    expect(activity.totalSellVolume, closeTo(120, 0.01));
    expect(activity.averageOrderSize, closeTo(273.3333, 0.001));
    expect(activity.largestOrder?.assetSymbol, 'VOO');
    expect(activity.mostTradedAsset?.symbol, 'VOO');
    expect(activity.lastTradeDate, DateTime(2025, 1, 3, 10));
  });

  test('performance snapshot combines realized and unrealized p/l', () {
    final marketState = MarketState();
    final paperState = PaperTradingState.fromAccount(
      PaperTradingAccount(
        startingCash: 2000,
        cashBalance: 1000,
        positions: [
          PortfolioPosition(
            asset: MockMarketData.assets.first,
            quantity: 2,
            averagePrice: 100,
          ),
        ],
        orders: [
          PaperOrder(
            assetSymbol: 'AAPL',
            assetName: 'Apple Inc.',
            side: PaperOrderSide.sell,
            quantity: 1,
            executionPrice: 120,
            estimatedTotal: 120,
            timestamp: DateTime(2025, 1, 4, 10),
            status: PaperOrderStatus.filled,
            averageCostAtExecution: 100,
            realizedProfitLoss: 20,
          ),
        ],
        lastUpdated: DateTime(2025, 1, 4, 10),
      ),
      repository: const LocalPaperTradingRepository(),
    );

    final snapshot = TradingAnalytics.performance(
      tradingState: paperState,
      marketState: marketState,
    );

    expect(snapshot.realizedProfitLoss, closeTo(20, 0.01));
    expect(snapshot.unrealizedProfitLoss, closeTo(228.64, 0.01));
    expect(snapshot.totalProfitLoss, closeTo(248.64, 0.01));
    expect(snapshot.returnPercent, closeTo(12.432, 0.01));
  });

  test('analytics update after a buy and sell', () async {
    final state = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
      initialOrders: const [],
      repository: LocalPaperTradingRepository(store: MemoryPaperTradingStore()),
    );
    final marketState = MarketState();
    final asset = marketState.assetBySymbol('AAPL');

    final before = TradingAnalytics.performance(
      tradingState: state,
      marketState: marketState,
    );

    await state.executeOrder(
      asset: asset,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: 100,
    );
    await state.executeOrder(
      asset: asset,
      side: PaperOrderSide.sell,
      quantity: 1,
      executionPrice: 120,
    );

    final after = TradingAnalytics.performance(
      tradingState: state,
      marketState: marketState,
    );
    final activity = TradingAnalytics.activity(tradingState: state);

    expect(after.totalProfitLoss, greaterThan(before.totalProfitLoss));
    expect(after.realizedProfitLoss, closeTo(20, 0.01));
    expect(activity.totalOrders, 2);
    expect(activity.lastTradeDate, isNotNull);
  });

  testWidgets('analytics screen renders empty state safely', (tester) async {
    final marketState = MarketState();
    final paperState = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
      initialOrders: const [],
      repository: LocalPaperTradingRepository(),
    );

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: OptionsPortfolioScope(
            state: OptionsPortfolioState(
              repository: LocalOptionsPortfolioRepository(
                store: MemoryOptionsPortfolioStore(),
              ),
            ),
            child: const MaterialApp(home: AnalyticsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No analytics yet'), findsOneWidget);
    expect(find.text('Performance overview'), findsOneWidget);
  });

  testWidgets('analytics screen renders dashboard sections', (tester) async {
    final marketState = MarketState();
    final paperState = PaperTradingState();

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: OptionsPortfolioScope(
            state: OptionsPortfolioState(
              repository: LocalOptionsPortfolioRepository(
                store: MemoryOptionsPortfolioStore(),
              ),
            ),
            child: const MaterialApp(home: AnalyticsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Performance overview'), findsOneWidget);
    expect(find.text('P/L summary'), findsOneWidget);
    expect(find.text('Allocation breakdown'), findsOneWidget);
    expect(find.text('Trading activity'), findsOneWidget);
  });
}
