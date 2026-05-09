import '../analytics/options_analytics.dart';
import 'option_contract.dart';
import 'strategy_simulator.dart';

class WheelStrategySimulationResult {
  const WheelStrategySimulationResult({
    required this.putContract,
    required this.callContract,
    required this.totalPremiumCycleIncome,
    required this.estimatedCapitalRequired,
    required this.putBreakeven,
    required this.coveredCallBreakeven,
    required this.assignedCostBasisAfterPutPremium,
    required this.exitCalledAwayProfitEstimate,
    required this.returnOnCapitalPercent,
    required this.scenarios,
    required this.daysToExpiration,
    this.validationWarning,
  });

  final OptionContract putContract;
  final OptionContract callContract;
  final double totalPremiumCycleIncome;
  final double estimatedCapitalRequired;
  final double putBreakeven;
  final double coveredCallBreakeven;
  final double assignedCostBasisAfterPutPremium;
  final double exitCalledAwayProfitEstimate;
  final double returnOnCapitalPercent;
  final List<StrategyScenario> scenarios;
  final int daysToExpiration;
  final String? validationWarning;
}

class WheelStrategySimulator
    implements StrategySimulator<WheelStrategySimulationResult> {
  const WheelStrategySimulator({
    required this.currentUnderlyingPrice,
    required this.putStrikePrice,
    required this.putPremium,
    required this.callStrikePrice,
    required this.callPremium,
    required this.contractsCount,
    required this.expirationDate,
    this.assignedSharePrice,
    this.multiplier = 100,
    this.underlyingSymbol = '',
  });

  final double currentUnderlyingPrice;
  final double putStrikePrice;
  final double putPremium;
  final double callStrikePrice;
  final double callPremium;
  final int contractsCount;
  final DateTime expirationDate;
  final double? assignedSharePrice;
  final int multiplier;
  final String underlyingSymbol;

  @override
  WheelStrategySimulationResult simulate() {
    final putContract = OptionContract(
      underlyingSymbol: underlyingSymbol,
      underlyingPrice: currentUnderlyingPrice,
      optionType: OptionType.put,
      strikePrice: putStrikePrice,
      premium: putPremium,
      expirationDate: expirationDate,
      contractsCount: contractsCount,
      multiplier: multiplier,
      side: OptionSide.sell,
    );
    final callContract = OptionContract(
      underlyingSymbol: underlyingSymbol,
      underlyingPrice: currentUnderlyingPrice,
      optionType: OptionType.call,
      strikePrice: callStrikePrice,
      premium: callPremium,
      expirationDate: expirationDate,
      contractsCount: contractsCount,
      multiplier: multiplier,
      side: OptionSide.sell,
    );
    final shares = putContract.sharesControlled;
    final totalPremiumCycleIncome =
        putContract.premiumIncome + callContract.premiumIncome;
    final estimatedCapitalRequired = putContract.strikePrice * shares;
    final assignedCostBasisAfterPutPremium =
        (assignedSharePrice ?? putStrikePrice) - putPremium;
    final coveredCallBreakeven = assignedCostBasisAfterPutPremium - callPremium;
    final exitCalledAwayProfitEstimate =
        (callStrikePrice - assignedCostBasisAfterPutPremium + callPremium) *
        shares;
    final assignedPrice = assignedSharePrice;
    final validationWarning = assignedPrice != null && assignedPrice <= 0
        ? 'Assigned share price must be greater than zero.'
        : null;

    return WheelStrategySimulationResult(
      putContract: putContract,
      callContract: callContract,
      totalPremiumCycleIncome: totalPremiumCycleIncome,
      estimatedCapitalRequired: estimatedCapitalRequired,
      putBreakeven: putContract.breakeven,
      coveredCallBreakeven: coveredCallBreakeven,
      assignedCostBasisAfterPutPremium: assignedCostBasisAfterPutPremium,
      exitCalledAwayProfitEstimate: exitCalledAwayProfitEstimate,
      returnOnCapitalPercent: OptionsAnalytics.premiumYieldPercent(
        premiumIncome: totalPremiumCycleIncome,
        capitalRequired: estimatedCapitalRequired,
      ),
      scenarios: [
        StrategyScenario(
          title: 'Expires worthless',
          description:
              'Keep the put premium and stay in cash. Total cycle income: \$${totalPremiumCycleIncome.toStringAsFixed(2)}.',
        ),
        StrategyScenario(
          title: 'Assigned',
          description:
              'Buy shares at \$${putStrikePrice.toStringAsFixed(2)} and carry a cost basis near \$${assignedCostBasisAfterPutPremium.toStringAsFixed(2)} per share.',
        ),
        StrategyScenario(
          title: 'Called away',
          description:
              'If shares are called away at \$${callStrikePrice.toStringAsFixed(2)}, the exit profit estimate is \$${exitCalledAwayProfitEstimate.toStringAsFixed(2)}.',
        ),
      ],
      daysToExpiration: OptionsAnalytics.daysToExpiration(
        expirationDate: expirationDate,
      ),
      validationWarning: validationWarning,
    );
  }
}
