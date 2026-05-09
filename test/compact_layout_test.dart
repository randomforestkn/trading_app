import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/core/insights/insights_state.dart';
import 'package:trading_app/core/models/paper_order.dart';
import 'package:trading_app/features/asset_detail/asset_detail_screen.dart';
import 'package:trading_app/features/home/home_screen.dart';
import 'package:trading_app/features/insights/insights_screen.dart';
import 'package:trading_app/features/journal/journal_editor_screen.dart';
import 'package:trading_app/features/journal/journal_screen.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/features/options_portfolio/option_position_editor_screen.dart';
import 'package:trading_app/features/options_portfolio/options_portfolio_screen.dart';
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

    final journalState = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );

    await tester.pumpWidget(
      JournalScope(
        state: journalState,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const JournalScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final optionsState = OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    );

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: OptionsPortfolioScope(
          state: optionsState,
          child: const MaterialApp(home: OptionsPortfolioScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      JournalScope(
        state: journalState,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const JournalEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: OptionsPortfolioScope(
          state: optionsState,
          child: MaterialApp(home: const OptionPositionEditorScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      InsightsScope(
        state: InsightsState(
          journalState: journalState,
          paperTradingState: paperState,
          optionsState: optionsState,
          marketState: marketState,
        ),
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
