import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/local_mock_market_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/data/paper_trading_store.dart';
import 'package:trading_app/core/models/asset.dart';
import 'package:trading_app/core/models/paper_order.dart';

void main() {
  test('MarketRepository local implementation returns assets', () async {
    final repository = LocalMockMarketRepository();

    final result = await repository.loadAssets();

    result.when(success: (assets) => expect(assets, isNotEmpty), failure: fail);
  });

  test('MarketState can load assets through repository', () async {
    final marketState = MarketState(
      initialAssets: const [],
      repository: LocalMockMarketRepository(),
    );

    await marketState.loadAssets();

    expect(marketState.assets, isNotEmpty);
    expect(marketState.errorMessage, isNull);
  });

  test('price refresh changes at least some prices', () async {
    final marketState = MarketState(movementGenerator: (_) => 0.01);
    final before = {
      for (final asset in marketState.assets) asset.symbol: asset.price,
    };

    await marketState.refreshPrices();

    final changed = marketState.assets.any(
      (asset) => asset.price != before[asset.symbol],
    );
    expect(changed, isTrue);
  });

  test('price history grows after refresh', () async {
    final asset = MockMarketData.assets.first;
    final marketState = MarketState(movementGenerator: (_) => 0.01);
    final beforeLength = marketState.historyFor(asset.symbol).length;

    await marketState.refreshPrices();

    expect(marketState.historyFor(asset.symbol).length, beforeLength + 1);
  });

  test('history length stays bounded', () async {
    final asset = MockMarketData.assets.first;
    final marketState = MarketState(movementGenerator: (_) => 0.01);

    for (var i = 0; i < MarketState.maxHistoryLength + 10; i++) {
      await marketState.refreshPrices();
    }

    expect(
      marketState.historyFor(asset.symbol).length,
      MarketState.maxHistoryLength,
    );
  });

  test('portfolio value changes after price refresh', () async {
    final marketState = MarketState(movementGenerator: (_) => 0.01);
    final paperState = PaperTradingState();
    final before = paperState.totalPortfolioValueFor(marketState);

    await marketState.refreshPrices();

    expect(paperState.totalPortfolioValueFor(marketState), isNot(before));
    expect(paperState.unrealizedProfitLossFor(marketState), isNot(0));
  });

  test('trade execution uses latest simulated price', () async {
    final originalAsset = MockMarketData.assets.first;
    final marketState = MarketState(movementGenerator: (_) => 0.01);
    final paperState = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
    );

    await marketState.refreshPrices();
    final latestAsset = marketState.assetBySymbol(originalAsset.symbol);

    await paperState.executeOrder(
      asset: latestAsset,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: latestAsset.price,
    );

    expect(paperState.positions.single.averagePrice, latestAsset.price);
    expect(paperState.cashBalance, closeTo(1000 - latestAsset.price, 0.001));
  });

  test('refresh does not break persisted paper trading state', () async {
    final asset = MockMarketData.assets.first;
    final store = MemoryPaperTradingStore();
    final repository = LocalPaperTradingRepository(store: store);
    final paperState = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
      repository: repository,
    );
    final marketState = MarketState(movementGenerator: (_) => 0.01);

    await paperState.executeOrder(
      asset: asset,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: 100,
    );
    final savedBeforeRefresh = store.value;

    await marketState.refreshPrices();
    final restored = await PaperTradingState.load(repository: repository);

    expect(store.value, savedBeforeRefresh);
    expect(restored.cashBalance, 900);
    expect(restored.quantityFor(asset.symbol), 1);
    expect(restored.orders.length, 1);
  });

  test('failure state can be represented without crashing UI', () async {
    final marketState = MarketState(repository: _FailingMarketRepository());

    final result = await marketState.refreshPrices();

    result.when(
      success: (_) => fail('Expected refresh failure'),
      failure: (message) => expect(message, 'Market data unavailable'),
    );
    expect(marketState.errorMessage, 'Market data unavailable');
    expect(marketState.isLoading, isFalse);
  });
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
