import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/data/paper_trading_store.dart';
import 'package:trading_app/core/models/paper_order.dart';

void main() {
  group('PaperTradingState', () {
    test('buy reduces cash and creates a position', () async {
      final asset = MockMarketData.assets.first;
      final state = PaperTradingState(
        initialCashBalance: 1000,
        initialPositions: const [],
      );

      final result = await state.executeOrder(
        asset: asset,
        side: PaperOrderSide.buy,
        quantity: 2,
        executionPrice: 100,
      );

      expect(result.success, isTrue);
      expect(state.cashBalance, 800);
      expect(state.quantityFor(asset.symbol), 2);
      expect(state.positions.single.averagePrice, 100);
      expect(state.orders.single.status, PaperOrderStatus.filled);
    });

    test('sell reduces quantity and increases cash', () async {
      final asset = MockMarketData.assets.first;
      final state = PaperTradingState(
        initialCashBalance: 1000,
        initialPositions: const [],
      );

      await state.executeOrder(
        asset: asset,
        side: PaperOrderSide.buy,
        quantity: 2,
        executionPrice: 100,
      );
      final result = await state.executeOrder(
        asset: asset,
        side: PaperOrderSide.sell,
        quantity: 0.5,
        executionPrice: 120,
      );

      expect(result.success, isTrue);
      expect(state.cashBalance, 860);
      expect(state.quantityFor(asset.symbol), 1.5);
      expect(state.orders.length, 2);
    });

    test('rejects insufficient cash and oversized sells', () async {
      final asset = MockMarketData.assets.first;
      final state = PaperTradingState(
        initialCashBalance: 50,
        initialPositions: const [],
      );

      final buyResult = await state.executeOrder(
        asset: asset,
        side: PaperOrderSide.buy,
        quantity: 1,
        executionPrice: 100,
      );
      final sellResult = await state.executeOrder(
        asset: asset,
        side: PaperOrderSide.sell,
        quantity: 1,
        executionPrice: 100,
      );

      expect(buyResult.success, isFalse);
      expect(sellResult.success, isFalse);
      expect(state.cashBalance, 50);
      expect(state.positions, isEmpty);
      expect(state.orders, isEmpty);
    });

    test(
      'serializes and deserializes cash positions and order history',
      () async {
        final asset = MockMarketData.assets.first;
        final original = PaperTradingState(
          initialCashBalance: 1000,
          initialPositions: const [],
        );

        await original.executeOrder(
          asset: asset,
          side: PaperOrderSide.buy,
          quantity: 2,
          executionPrice: 100,
        );

        final restored = PaperTradingState.fromJsonString(
          original.toJsonString(),
        );

        expect(restored.cashBalance, 800);
        expect(restored.quantityFor(asset.symbol), 2);
        expect(restored.positions.single.averagePrice, 100);
        expect(restored.orders.single.assetSymbol, asset.symbol);
        expect(restored.orders.single.side, PaperOrderSide.buy);
        expect(restored.lastUpdated, isNotNull);
      },
    );

    test(
      'reset clears persisted state and restores defaults after persistence',
      () async {
        final asset = MockMarketData.assets.first;
        final store = MemoryPaperTradingStore();
        final repository = LocalPaperTradingRepository(store: store);
        final state = PaperTradingState(
          initialCashBalance: 1000,
          initialPositions: const [],
          repository: repository,
        );

        await state.executeOrder(
          asset: asset,
          side: PaperOrderSide.buy,
          quantity: 1,
          executionPrice: 100,
        );
        expect(store.value, isNotNull);

        await state.reset();

        expect(store.value, isNull);
        expect(state.cashBalance, PaperTradingState.defaultCashBalance);
        expect(state.positions.length, MockMarketData.positions.length);
        expect(state.orders, isEmpty);
      },
    );

    test('successful buy and sell update persisted state', () async {
      final asset = MockMarketData.assets.first;
      final store = MemoryPaperTradingStore();
      final repository = LocalPaperTradingRepository(store: store);
      final state = PaperTradingState(
        initialCashBalance: 1000,
        initialPositions: const [],
        repository: repository,
      );

      await state.executeOrder(
        asset: asset,
        side: PaperOrderSide.buy,
        quantity: 2,
        executionPrice: 100,
      );
      final afterBuy = await PaperTradingState.load(repository: repository);

      expect(afterBuy.cashBalance, 800);
      expect(afterBuy.quantityFor(asset.symbol), 2);
      expect(afterBuy.orders.length, 1);

      await state.executeOrder(
        asset: asset,
        side: PaperOrderSide.sell,
        quantity: 0.5,
        executionPrice: 120,
      );
      final afterSell = await PaperTradingState.load(repository: repository);

      expect(afterSell.cashBalance, 860);
      expect(afterSell.quantityFor(asset.symbol), 1.5);
      expect(afterSell.orders.length, 2);
    });
  });
}
