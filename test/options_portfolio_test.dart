import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/models/asset.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/option_position.dart';
import 'package:trading_app/core/options_portfolio/option_trade.dart';
import 'package:trading_app/core/options_portfolio/options_income_analytics.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_account.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/core/options_portfolio/wheel_cycle.dart';
import 'package:trading_app/core/analytics/options_analytics.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/strategies/option_strategy.dart';

void main() {
  test('OptionPosition serializes and computes derived values', () {
    final position = OptionPosition(
      id: 'opt-1',
      underlyingSymbol: 'AAPL',
      underlyingName: 'Apple Inc.',
      optionType: OptionType.put,
      side: OptionSide.sell,
      strikePrice: 95,
      premium: 3,
      contractsCount: 2,
      multiplier: 100,
      openedAt: DateTime(2026, 1, 1),
      expirationDate: DateTime(2026, 2, 1),
      status: OptionPositionStatus.open,
      linkedStrategy: OptionStrategy.cashSecuredPut,
      notes: 'Demo note',
    );

    expect(position.sharesControlled, 200);
    expect(position.totalPremium, 600);
    expect(position.breakeven, 92);
    expect(position.capitalAtRisk, 18400);
    expect(position.moneynessPercent(100), closeTo(-5.26315789, 0.001));
    expect(position.assignmentRiskLabel(100), AssignmentRiskLevel.medium);

    final restored = OptionPosition.fromJson(position.toJson());
    expect(restored.displayTitle, position.displayTitle);
    expect(restored.notes, 'Demo note');
    expect(restored.linkedStrategy, OptionStrategy.cashSecuredPut);
  });

  test('LocalOptionsPortfolioRepository save/load roundtrip works', () async {
    final repository = LocalOptionsPortfolioRepository(
      store: MemoryOptionsPortfolioStore(),
    );
    final account = OptionsPortfolioAccount(
      positions: [
        OptionPosition(
          id: 'opt-1',
          underlyingSymbol: 'AAPL',
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
      ],
      trades: [
        OptionTrade(
          id: 'trade-1',
          positionId: 'opt-1',
          createdAt: DateTime(2026, 1, 1),
          eventType: OptionTradeEventType.open,
          premium: 300,
          quantity: 1,
        ),
      ],
      wheelCycles: [
        WheelCycle(
          id: 'cycle-1',
          underlyingSymbol: 'AAPL',
          startedAt: DateTime(2026, 1, 1),
          status: WheelCycleStatus.sellingPuts,
          putPositionIds: const ['opt-1'],
        ),
      ],
      lastUpdated: DateTime(2026, 1, 2),
    );

    await repository.saveAccount(account);
    final loaded = await repository.loadAccount();

    loaded.when(
      success: (data) {
        expect(data.positions, hasLength(1));
        expect(data.trades, hasLength(1));
        expect(data.wheelCycles, hasLength(1));
      },
      failure: (message) => fail(message),
    );
  });

  test(
    'OptionsPortfolioState add close expire assign delete update state',
    () async {
      final state = OptionsPortfolioState(
        repository: LocalOptionsPortfolioRepository(
          store: MemoryOptionsPortfolioStore(),
        ),
      );

      final put = OptionPosition(
        id: 'put-1',
        underlyingSymbol: 'AAPL',
        optionType: OptionType.put,
        side: OptionSide.sell,
        strikePrice: 95,
        premium: 3,
        contractsCount: 1,
        openedAt: DateTime(2026, 1, 1),
        expirationDate: DateTime(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.wheel,
      );
      final call = OptionPosition(
        id: 'call-1',
        underlyingSymbol: 'AAPL',
        optionType: OptionType.call,
        side: OptionSide.sell,
        strikePrice: 110,
        premium: 2,
        contractsCount: 1,
        openedAt: DateTime(2026, 1, 2),
        expirationDate: DateTime(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.wheel,
      );
      final expired = OptionPosition(
        id: 'expired-1',
        underlyingSymbol: 'MSFT',
        optionType: OptionType.put,
        side: OptionSide.sell,
        strikePrice: 200,
        premium: 4,
        contractsCount: 1,
        openedAt: DateTime(2026, 1, 3),
        expirationDate: DateTime(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.cashSecuredPut,
      );
      final closed = OptionPosition(
        id: 'closed-1',
        underlyingSymbol: 'NVDA',
        optionType: OptionType.call,
        side: OptionSide.sell,
        strikePrice: 120,
        premium: 5,
        contractsCount: 1,
        openedAt: DateTime(2026, 1, 4),
        expirationDate: DateTime(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.coveredCall,
      );
      final deleted = OptionPosition(
        id: 'deleted-1',
        underlyingSymbol: 'TSLA',
        optionType: OptionType.put,
        side: OptionSide.sell,
        strikePrice: 250,
        premium: 6,
        contractsCount: 1,
        openedAt: DateTime(2026, 1, 5),
        expirationDate: DateTime(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.cashSecuredPut,
      );

      await state.addPosition(put);
      await state.markAssigned(put.id, currentUnderlyingPrice: 90);
      expect(state.positionById(put.id)?.status, OptionPositionStatus.assigned);
      expect(state.trades, hasLength(2));
      expect(state.wheelCycles.first.status, WheelCycleStatus.assigned);

      await state.addPosition(call);
      await state.markAssigned(call.id, currentUnderlyingPrice: 115);
      expect(
        state.positionById(call.id)?.status,
        OptionPositionStatus.assigned,
      );
      expect(state.wheelCycles.first.status, WheelCycleStatus.calledAway);

      await state.addPosition(expired);
      await state.markExpired(expired.id);
      expect(
        state.positionById(expired.id)?.status,
        OptionPositionStatus.expired,
      );

      await state.addPosition(closed);
      await state.closePosition(closed.id, currentUnderlyingPrice: 118);
      expect(
        state.positionById(closed.id)?.status,
        OptionPositionStatus.closed,
      );

      await state.addPosition(deleted);
      await state.deletePosition(deleted.id);
      expect(state.positionById(deleted.id), isNull);
      expect(state.closedPositions, hasLength(4));
    },
  );

  test(
    'Options income analytics summarises premium and lifecycle counts',
    () async {
      final marketState = MarketState(
        initialAssets: [
          TradingAsset(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            type: AssetType.stock,
            price: 100,
            dailyChangePercent: 0.5,
            open: 99,
            high: 101,
            low: 98,
            volume: '1.2B',
            marketCap: '3.2T',
            trend: const [96, 98, 100],
            explanation: 'Apple',
            stats: const {},
          ),
        ],
      );
      final state = OptionsPortfolioState(
        repository: LocalOptionsPortfolioRepository(
          store: MemoryOptionsPortfolioStore(),
        ),
      );

      await state.addPosition(
        OptionPosition(
          id: 'opt-1',
          underlyingSymbol: 'AAPL',
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

      final analytics = OptionsIncomeAnalytics.fromState(
        state: state,
        marketState: marketState,
        asOf: DateTime(2026, 1, 15),
      );

      expect(analytics.totalPremiumCollected, 300);
      expect(analytics.openPremiumAtRisk, 300);
      expect(analytics.openContractsCount, 1);
      expect(analytics.premiumByStrategy[OptionStrategy.cashSecuredPut], 300);
      expect(analytics.premiumByUnderlying['AAPL'], 300);
    },
  );
}
