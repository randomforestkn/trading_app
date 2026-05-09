import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/features/asset_detail/asset_detail_screen.dart';
import 'package:trading_app/features/home/home_screen.dart';
import 'package:trading_app/features/portfolio/portfolio_screen.dart';
import 'package:trading_app/features/trade/trade_screen.dart';
import 'package:trading_app/features/watchlist/watchlist_screen.dart';

void main() {
  testWidgets('key screens render on compact layouts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final marketState = MarketState();
    final paperState = PaperTradingState();

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: const MaterialApp(home: WatchlistScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: const MaterialApp(home: PortfolioScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: MaterialApp(
            home: AssetDetailScreen(asset: MockMarketData.assets.first),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: MaterialApp(
            home: TradeScreen(
              asset: MockMarketData.assets.first,
              initialSide: PaperOrderSide.buy,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
