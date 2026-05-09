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

OptionStrategy? optionStrategyFromName(String? value) {
  return switch (value) {
    'coveredCall' => OptionStrategy.coveredCall,
    'cashSecuredPut' => OptionStrategy.cashSecuredPut,
    'wheel' => OptionStrategy.wheel,
    _ => null,
  };
}
