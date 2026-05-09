import '../strategies/option_contract.dart';

enum AssignmentRiskLevel { low, medium, high }

extension AssignmentRiskLevelLabel on AssignmentRiskLevel {
  String get label {
    return switch (this) {
      AssignmentRiskLevel.low => 'Low',
      AssignmentRiskLevel.medium => 'Medium',
      AssignmentRiskLevel.high => 'High',
    };
  }
}

class OptionsAnalytics {
  const OptionsAnalytics._();

  static int daysToExpiration({
    required DateTime expirationDate,
    DateTime? asOf,
  }) {
    final reference = asOf ?? DateTime.now();
    final days = expirationDate.difference(reference).inDays;
    return days < 0 ? 0 : days;
  }

  static double premiumYieldPercent({
    required double premiumIncome,
    required double capitalRequired,
  }) {
    if (capitalRequired <= 0) {
      return 0;
    }
    return (premiumIncome / capitalRequired) * 100;
  }

  static double annualizedPremiumYieldPercent({
    required double premiumIncome,
    required double capitalRequired,
    required int daysToExpiration,
  }) {
    if (daysToExpiration <= 0) {
      return premiumYieldPercent(
        premiumIncome: premiumIncome,
        capitalRequired: capitalRequired,
      );
    }
    return premiumYieldPercent(
          premiumIncome: premiumIncome,
          capitalRequired: capitalRequired,
        ) *
        (365 / daysToExpiration);
  }

  static double moneynessPercent({
    required OptionType optionType,
    required double underlyingPrice,
    required double strikePrice,
  }) {
    if (strikePrice == 0) {
      return 0;
    }
    return switch (optionType) {
      OptionType.call => ((underlyingPrice - strikePrice) / strikePrice) * 100,
      OptionType.put => ((strikePrice - underlyingPrice) / strikePrice) * 100,
    };
  }

  static double downsideBufferPercent({
    required double underlyingPrice,
    required double breakeven,
  }) {
    if (underlyingPrice == 0) {
      return 0;
    }
    return ((underlyingPrice - breakeven) / underlyingPrice) * 100;
  }

  static AssignmentRiskLevel assignmentRiskLabel({
    required OptionType optionType,
    required double underlyingPrice,
    required double strikePrice,
  }) {
    final moneyness = moneynessPercent(
      optionType: optionType,
      underlyingPrice: underlyingPrice,
      strikePrice: strikePrice,
    );
    if (moneyness >= 5) {
      return AssignmentRiskLevel.high;
    }
    if (moneyness >= 0) {
      return AssignmentRiskLevel.medium;
    }
    if (moneyness > -10) {
      return AssignmentRiskLevel.medium;
    }
    return AssignmentRiskLevel.low;
  }
}
