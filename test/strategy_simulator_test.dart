import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/analytics/options_analytics.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/strategies/cash_secured_put_simulator.dart';
import 'package:trading_app/core/strategies/covered_call_simulator.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/strategies/wheel_strategy_simulator.dart';
import 'package:trading_app/features/strategy_simulator/strategy_simulator_screen.dart';

void main() {
  test('option contract calculations work', () {
    final contract = OptionContract(
      underlyingSymbol: 'AAPL',
      underlyingPrice: 100,
      optionType: OptionType.call,
      strikePrice: 105,
      premium: 2,
      expirationDate: DateTime(2026, 2, 1),
      contractsCount: 2,
    );

    expect(contract.sharesControlled, 200);
    expect(contract.premiumIncome, 400);
    expect(contract.breakeven, 107);
    expect(contract.assignmentPrice, 105);
    expect(contract.notionalValue, 20000);
  });

  test('covered call simulator validates coverage and returns metrics', () {
    final result = CoveredCallSimulator(
      underlyingSymbol: 'AAPL',
      ownedShares: 200,
      currentUnderlyingPrice: 100,
      strikePrice: 105,
      premium: 2,
      contractsCount: 2,
      expirationDate: DateTime(2026, 2, 1),
    ).simulate();

    expect(result.validationWarning, isNull);
    expect(result.premiumIncome, 400);
    expect(result.maxProfit, 1400);
    expect(result.breakeven, 98);
    expect(result.calledAwayReturn, 1400);
    expect(result.requiredShares, 200);
    expect(result.assignmentRiskLabel, AssignmentRiskLevel.medium);
  });

  test('covered call simulator warns when contracts exceed shares', () {
    final result = CoveredCallSimulator(
      underlyingSymbol: 'AAPL',
      ownedShares: 50,
      currentUnderlyingPrice: 100,
      strikePrice: 105,
      premium: 2,
      contractsCount: 1,
      expirationDate: DateTime(2026, 2, 1),
    ).simulate();

    expect(result.validationWarning, contains('only own 50'));
  });

  test('cash secured put simulator validates cash and computes yield', () {
    final result = CashSecuredPutSimulator(
      underlyingSymbol: 'AAPL',
      cashAvailable: 20000,
      currentUnderlyingPrice: 100,
      strikePrice: 95,
      premium: 3,
      contractsCount: 2,
      expirationDate: DateTime(2026, 2, 1),
    ).simulate();

    expect(result.validationWarning, isNull);
    expect(result.premiumIncome, 600);
    expect(result.capitalRequired, 19000);
    expect(result.breakeven, 92);
    expect(result.maxProfit, 600);
    expect(result.maxLossEstimate, 18400);
    expect(result.assignmentRiskLabel, AssignmentRiskLevel.medium);
  });

  test('cash secured put simulator warns on insufficient cash', () {
    final result = CashSecuredPutSimulator(
      underlyingSymbol: 'AAPL',
      cashAvailable: 1000,
      currentUnderlyingPrice: 100,
      strikePrice: 95,
      premium: 3,
      contractsCount: 1,
      expirationDate: DateTime(2026, 2, 1),
    ).simulate();

    expect(result.validationWarning, contains('cash'));
  });

  test('wheel strategy simulator returns cycle outputs', () {
    final result = WheelStrategySimulator(
      underlyingSymbol: 'AAPL',
      currentUnderlyingPrice: 100,
      putStrikePrice: 95,
      putPremium: 3,
      callStrikePrice: 110,
      callPremium: 2,
      contractsCount: 1,
      expirationDate: DateTime(2026, 2, 1),
    ).simulate();

    expect(result.totalPremiumCycleIncome, 500);
    expect(result.estimatedCapitalRequired, 9500);
    expect(result.putBreakeven, 92);
    expect(result.coveredCallBreakeven, 90);
    expect(result.assignedCostBasisAfterPutPremium, 92);
    expect(result.exitCalledAwayProfitEstimate, 2000);
    expect(result.scenarios.length, 3);
  });

  test('options analytics helpers compute yields and risk labels', () {
    final expiration = DateTime(2026, 2, 1);
    expect(
      OptionsAnalytics.daysToExpiration(
        expirationDate: expiration,
        asOf: DateTime(2026, 1, 2),
      ),
      30,
    );
    expect(
      OptionsAnalytics.premiumYieldPercent(
        premiumIncome: 200,
        capitalRequired: 10000,
      ),
      closeTo(2, 0.0001),
    );
    expect(
      OptionsAnalytics.annualizedPremiumYieldPercent(
        premiumIncome: 200,
        capitalRequired: 10000,
        daysToExpiration: 30,
      ),
      closeTo(24.3333, 0.01),
    );
    expect(
      OptionsAnalytics.assignmentRiskLabel(
        optionType: OptionType.call,
        underlyingPrice: 100,
        strikePrice: 130,
      ),
      AssignmentRiskLevel.low,
    );
    expect(
      OptionsAnalytics.assignmentRiskLabel(
        optionType: OptionType.call,
        underlyingPrice: 100,
        strikePrice: 105,
      ),
      AssignmentRiskLevel.medium,
    );
    expect(
      OptionsAnalytics.assignmentRiskLabel(
        optionType: OptionType.call,
        underlyingPrice: 100,
        strikePrice: 85,
      ),
      AssignmentRiskLevel.high,
    );
  });

  testWidgets('strategy simulator screen renders', (tester) async {
    final marketState = MarketState();
    final paperState = PaperTradingState();

    await tester.pumpWidget(
      MarketScope(
        state: marketState,
        child: PaperTradingScope(
          state: paperState,
          child: const MaterialApp(home: StrategySimulatorScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Strategy simulator'), findsOneWidget);
    expect(find.text('Covered Call'), findsOneWidget);
    expect(find.text('Run simulation'), findsOneWidget);
    expect(find.text('Simulation only'), findsOneWidget);
  });
}
