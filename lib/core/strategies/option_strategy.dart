enum OptionStrategy { coveredCall, cashSecuredPut, wheel }

extension OptionStrategyLabel on OptionStrategy {
  String get label {
    return switch (this) {
      OptionStrategy.coveredCall => 'Covered Call',
      OptionStrategy.cashSecuredPut => 'Cash-Secured Put',
      OptionStrategy.wheel => 'Wheel',
    };
  }
}
