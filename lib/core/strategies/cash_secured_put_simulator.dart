import '../analytics/options_analytics.dart';
import 'option_contract.dart';
import 'strategy_simulator.dart';

class CashSecuredPutSimulationResult {
  const CashSecuredPutSimulationResult({
    required this.contract,
    required this.premiumIncome,
    required this.capitalRequired,
    required this.breakeven,
    required this.maxProfit,
    required this.maxLossEstimate,
    required this.returnOnCashSecuredPercent,
    required this.assignmentCost,
    required this.annualizedPremiumYieldPercent,
    required this.moneynessPercent,
    required this.assignmentRiskLabel,
    required this.daysToExpiration,
    this.validationWarning,
  });

  final OptionContract contract;
  final double premiumIncome;
  final double capitalRequired;
  final double breakeven;
  final double maxProfit;
  final double maxLossEstimate;
  final double returnOnCashSecuredPercent;
  final double assignmentCost;
  final double annualizedPremiumYieldPercent;
  final double moneynessPercent;
  final AssignmentRiskLevel assignmentRiskLabel;
  final int daysToExpiration;
  final String? validationWarning;
}

class CashSecuredPutSimulator
    implements StrategySimulator<CashSecuredPutSimulationResult> {
  const CashSecuredPutSimulator({
    required this.cashAvailable,
    required this.currentUnderlyingPrice,
    required this.strikePrice,
    required this.premium,
    required this.contractsCount,
    required this.expirationDate,
    this.multiplier = 100,
    this.underlyingSymbol = '',
  });

  final double cashAvailable;
  final double currentUnderlyingPrice;
  final double strikePrice;
  final double premium;
  final int contractsCount;
  final DateTime expirationDate;
  final int multiplier;
  final String underlyingSymbol;

  @override
  CashSecuredPutSimulationResult simulate() {
    final contract = OptionContract(
      underlyingSymbol: underlyingSymbol,
      underlyingPrice: currentUnderlyingPrice,
      optionType: OptionType.put,
      strikePrice: strikePrice,
      premium: premium,
      expirationDate: expirationDate,
      contractsCount: contractsCount,
      multiplier: multiplier,
      side: OptionSide.sell,
    );
    final capitalRequired = contract.strikePrice * contract.sharesControlled;
    final premiumIncome = contract.premiumIncome;
    return CashSecuredPutSimulationResult(
      contract: contract,
      premiumIncome: premiumIncome,
      capitalRequired: capitalRequired,
      breakeven: contract.breakeven,
      maxProfit: premiumIncome,
      maxLossEstimate: capitalRequired - premiumIncome,
      returnOnCashSecuredPercent: OptionsAnalytics.premiumYieldPercent(
        premiumIncome: premiumIncome,
        capitalRequired: capitalRequired,
      ),
      assignmentCost: capitalRequired,
      annualizedPremiumYieldPercent: contract.annualizedPremiumYieldPercent(),
      moneynessPercent: contract.moneynessPercent,
      assignmentRiskLabel: OptionsAnalytics.assignmentRiskLabel(
        optionType: OptionType.put,
        underlyingPrice: currentUnderlyingPrice,
        strikePrice: strikePrice,
      ),
      daysToExpiration: OptionsAnalytics.daysToExpiration(
        expirationDate: expirationDate,
      ),
      validationWarning: cashAvailable < capitalRequired
          ? 'This strategy requires \$${capitalRequired.toStringAsFixed(2)} in cash, but only \$${cashAvailable.toStringAsFixed(2)} is available.'
          : null,
    );
  }
}
