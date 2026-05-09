import '../analytics/options_analytics.dart';
import 'option_contract.dart';
import 'strategy_simulator.dart';

class CoveredCallSimulationResult {
  const CoveredCallSimulationResult({
    required this.contract,
    required this.premiumIncome,
    required this.maxProfit,
    required this.breakeven,
    required this.calledAwayReturn,
    required this.downsideBufferPercent,
    required this.requiredShares,
    required this.annualizedPremiumYieldPercent,
    required this.moneynessPercent,
    required this.assignmentRiskLabel,
    required this.daysToExpiration,
    this.validationWarning,
  });

  final OptionContract contract;
  final double premiumIncome;
  final double maxProfit;
  final double breakeven;
  final double calledAwayReturn;
  final double downsideBufferPercent;
  final int requiredShares;
  final double annualizedPremiumYieldPercent;
  final double moneynessPercent;
  final AssignmentRiskLevel assignmentRiskLabel;
  final int daysToExpiration;
  final String? validationWarning;
}

class CoveredCallSimulator
    implements StrategySimulator<CoveredCallSimulationResult> {
  const CoveredCallSimulator({
    required this.ownedShares,
    required this.currentUnderlyingPrice,
    required this.strikePrice,
    required this.premium,
    required this.contractsCount,
    required this.expirationDate,
    this.multiplier = 100,
    this.underlyingSymbol = '',
  });

  final int ownedShares;
  final double currentUnderlyingPrice;
  final double strikePrice;
  final double premium;
  final int contractsCount;
  final DateTime expirationDate;
  final int multiplier;
  final String underlyingSymbol;

  @override
  CoveredCallSimulationResult simulate() {
    final contract = OptionContract(
      underlyingSymbol: underlyingSymbol,
      underlyingPrice: currentUnderlyingPrice,
      optionType: OptionType.call,
      strikePrice: strikePrice,
      premium: premium,
      expirationDate: expirationDate,
      contractsCount: contractsCount,
      multiplier: multiplier,
      side: OptionSide.sell,
    );
    final requiredShares = contract.sharesControlled;
    final premiumIncome = contract.premiumIncome;
    final calledAwayReturn =
        ((strikePrice - currentUnderlyingPrice) * requiredShares) +
        premiumIncome;
    final breakeven = currentUnderlyingPrice - premium;
    return CoveredCallSimulationResult(
      contract: contract,
      premiumIncome: premiumIncome,
      maxProfit: calledAwayReturn,
      breakeven: breakeven,
      calledAwayReturn: calledAwayReturn,
      downsideBufferPercent: OptionsAnalytics.downsideBufferPercent(
        underlyingPrice: currentUnderlyingPrice,
        breakeven: breakeven,
      ),
      requiredShares: requiredShares,
      annualizedPremiumYieldPercent: contract.annualizedPremiumYieldPercent(),
      moneynessPercent: contract.moneynessPercent,
      assignmentRiskLabel: OptionsAnalytics.assignmentRiskLabel(
        optionType: OptionType.call,
        underlyingPrice: currentUnderlyingPrice,
        strikePrice: strikePrice,
      ),
      daysToExpiration: OptionsAnalytics.daysToExpiration(
        expirationDate: expirationDate,
      ),
      validationWarning: ownedShares < requiredShares
          ? 'This strategy requires $requiredShares shares, but you only own $ownedShares.'
          : null,
    );
  }
}
