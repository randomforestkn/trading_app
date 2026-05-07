import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_store.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/core/models/portfolio_position.dart';

void main() {
  test('LocalPaperTradingRepository loads default account', () async {
    final repository = LocalPaperTradingRepository(
      store: MemoryPaperTradingStore(),
    );

    final result = await repository.loadAccount();

    result.when(
      success: (account) {
        expect(account.cashBalance, PaperTradingAccount.defaultStartingCash);
        expect(account.positions.length, MockMarketData.positions.length);
        expect(account.orders, isEmpty);
      },
      failure: fail,
    );
  });

  test('save/load roundtrip works', () async {
    final store = MemoryPaperTradingStore();
    final repository = LocalPaperTradingRepository(store: store);
    final asset = MockMarketData.assets.first;
    final account = PaperTradingAccount(
      cashBalance: 900,
      positions: [
        PortfolioPosition(asset: asset, quantity: 1, averagePrice: 100),
      ],
      orders: [
        PaperOrder(
          assetSymbol: asset.symbol,
          assetName: asset.name,
          side: PaperOrderSide.buy,
          quantity: 1,
          executionPrice: 100,
          estimatedTotal: 100,
          timestamp: DateTime(2026),
          status: PaperOrderStatus.filled,
        ),
      ],
      lastUpdated: DateTime(2026),
    );

    await repository.saveAccount(account);
    final loaded = await repository.loadAccount();

    loaded.when(
      success: (account) {
        expect(account.cashBalance, 900);
        expect(account.positions.single.quantity, 1);
        expect(account.orders.single.assetSymbol, asset.symbol);
      },
      failure: fail,
    );
  });

  test('reset works through repository', () async {
    final store = MemoryPaperTradingStore();
    final repository = LocalPaperTradingRepository(store: store);
    await repository.saveAccount(
      const PaperTradingAccount(
        cashBalance: 1,
        positions: [],
        orders: [],
        lastUpdated: null,
      ),
    );

    final reset = await repository.resetAccount();

    reset.when(
      success: (account) {
        expect(store.value, isNull);
        expect(account.cashBalance, PaperTradingAccount.defaultStartingCash);
        expect(account.positions.length, MockMarketData.positions.length);
      },
      failure: fail,
    );
  });

  test('clear history works through repository', () async {
    final store = MemoryPaperTradingStore();
    final repository = LocalPaperTradingRepository(store: store);
    final asset = MockMarketData.assets.first;
    final account = PaperTradingAccount(
      cashBalance: 900,
      positions: [
        PortfolioPosition(asset: asset, quantity: 1, averagePrice: 100),
      ],
      orders: [
        PaperOrder(
          assetSymbol: asset.symbol,
          assetName: asset.name,
          side: PaperOrderSide.buy,
          quantity: 1,
          executionPrice: 100,
          estimatedTotal: 100,
          timestamp: DateTime(2026),
          status: PaperOrderStatus.filled,
        ),
      ],
      lastUpdated: DateTime(2026),
    );

    final result = await repository.clearOrderHistory(account);

    result.when(
      success: (account) {
        expect(account.orders, isEmpty);
        expect(account.cashBalance, 900);
        expect(account.positions.single.quantity, 1);
        expect(store.value, isNotNull);
      },
      failure: fail,
    );
  });
}
