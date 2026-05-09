enum OptionType { call, put }

extension OptionTypeLabel on OptionType {
  String get label {
    return switch (this) {
      OptionType.call => 'Call',
      OptionType.put => 'Put',
    };
  }
}

enum OptionSide { sell, buy }

extension OptionSideLabel on OptionSide {
  String get label {
    return switch (this) {
      OptionSide.sell => 'Sell',
      OptionSide.buy => 'Buy',
    };
  }
}

class OptionContract {
  const OptionContract({
    required this.underlyingSymbol,
    required this.underlyingPrice,
    required this.optionType,
    required this.strikePrice,
    required this.premium,
    required this.expirationDate,
    required this.contractsCount,
    this.multiplier = 100,
    this.side = OptionSide.sell,
  });

  final String underlyingSymbol;
  final double underlyingPrice;
  final OptionType optionType;
  final double strikePrice;
  final double premium;
  final DateTime expirationDate;
  final int contractsCount;
  final int multiplier;
  final OptionSide side;

  int get sharesControlled => contractsCount * multiplier;

  double get premiumIncome => premium * sharesControlled;

  double get breakeven {
    return switch (optionType) {
      OptionType.call => strikePrice + premium,
      OptionType.put => strikePrice - premium,
    };
  }

  double get assignmentPrice => strikePrice;

  double get notionalValue => underlyingPrice * sharesControlled;

  double get premiumYieldPercent =>
      notionalValue <= 0 ? 0 : (premiumIncome / notionalValue) * 100;

  double annualizedPremiumYieldPercent([DateTime? asOf]) {
    final days = daysToExpiration(asOf);
    if (days <= 0) {
      return premiumYieldPercent;
    }
    return premiumYieldPercent * (365 / days);
  }

  double get moneynessPercent {
    if (strikePrice == 0) {
      return 0;
    }
    return switch (optionType) {
      OptionType.call => ((underlyingPrice - strikePrice) / strikePrice) * 100,
      OptionType.put => ((strikePrice - underlyingPrice) / strikePrice) * 100,
    };
  }

  double get downsideBufferPercent => underlyingPrice == 0
      ? 0
      : ((underlyingPrice - breakeven) / underlyingPrice) * 100;

  int daysToExpiration([DateTime? asOf]) {
    final reference = asOf ?? DateTime.now();
    final days = expirationDate.difference(reference).inDays;
    return days < 0 ? 0 : days;
  }

  OptionContract copyWith({
    double? underlyingPrice,
    double? strikePrice,
    double? premium,
    DateTime? expirationDate,
    int? contractsCount,
    int? multiplier,
    OptionType? optionType,
    OptionSide? side,
  }) {
    return OptionContract(
      underlyingSymbol: underlyingSymbol,
      underlyingPrice: underlyingPrice ?? this.underlyingPrice,
      optionType: optionType ?? this.optionType,
      strikePrice: strikePrice ?? this.strikePrice,
      premium: premium ?? this.premium,
      expirationDate: expirationDate ?? this.expirationDate,
      contractsCount: contractsCount ?? this.contractsCount,
      multiplier: multiplier ?? this.multiplier,
      side: side ?? this.side,
    );
  }
}
