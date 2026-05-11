import 'dart:convert';

import '../strategies/option_contract.dart';

class OptionGreeks {
  const OptionGreeks({this.delta, this.gamma, this.theta, this.vega});

  final double? delta;
  final double? gamma;
  final double? theta;
  final double? vega;

  factory OptionGreeks.fromJson(Map<String, Object?> json) {
    return OptionGreeks(
      delta: _readDouble(json['delta']),
      gamma: _readDouble(json['gamma']),
      theta: _readDouble(json['theta']),
      vega: _readDouble(json['vega']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (delta != null) 'delta': delta,
      if (gamma != null) 'gamma': gamma,
      if (theta != null) 'theta': theta,
      if (vega != null) 'vega': vega,
    };
  }
}

class OptionQuote {
  const OptionQuote({
    required this.underlyingSymbol,
    required this.expirationDate,
    required this.strike,
    required this.optionType,
    required this.updatedAt,
    required this.bid,
    required this.ask,
    required this.last,
    required this.mark,
    required this.volume,
    required this.openInterest,
    required this.inTheMoney,
    this.impliedVolatility,
    this.greeks,
  });

  factory OptionQuote.fromJson(Map<String, Object?> json) {
    return OptionQuote(
      underlyingSymbol: _readString(json, ['underlyingSymbol']) ?? '',
      expirationDate:
          DateTime.tryParse(_readString(json, ['expirationDate']) ?? '') ??
          DateTime.now(),
      strike: _readDouble(_readValue(json, ['strike'])) ?? 0,
      optionType:
          _optionTypeFromName(_readString(json, ['optionType'])) ??
          OptionType.call,
      updatedAt:
          DateTime.tryParse(_readString(json, ['updatedAt']) ?? '') ??
          DateTime.now(),
      bid: _readDouble(_readValue(json, ['bid'])) ?? 0,
      ask: _readDouble(_readValue(json, ['ask'])) ?? 0,
      last: _readDouble(_readValue(json, ['last'])) ?? 0,
      mark:
          _readDouble(_readValue(json, ['mark'])) ??
          _readDouble(_readValue(json, ['mid'])) ??
          0,
      volume: _readInt(_readValue(json, ['volume'])),
      openInterest: _readInt(_readValue(json, ['openInterest'])),
      impliedVolatility: _readDouble(_readValue(json, ['impliedVolatility'])),
      inTheMoney: _readBool(_readValue(json, ['inTheMoney'])) ?? false,
      greeks: _readMap(_readValue(json, ['greeks'])) == null
          ? null
          : OptionGreeks.fromJson(_readMap(_readValue(json, ['greeks']))!),
    );
  }

  final String underlyingSymbol;
  final DateTime expirationDate;
  final double strike;
  final OptionType optionType;
  final DateTime updatedAt;
  final double bid;
  final double ask;
  final double last;
  final double mark;
  final int volume;
  final int openInterest;
  final double? impliedVolatility;
  final OptionGreeks? greeks;
  final bool inTheMoney;

  double get spread => ask - bid;
  double get mid => mark;

  Map<String, Object?> toJson() {
    return {
      'underlyingSymbol': underlyingSymbol,
      'expirationDate': expirationDate.toIso8601String(),
      'strike': strike,
      'optionType': optionType.name,
      'updatedAt': updatedAt.toIso8601String(),
      'bid': bid,
      'ask': ask,
      'last': last,
      'mark': mark,
      'volume': volume,
      'openInterest': openInterest,
      'inTheMoney': inTheMoney,
      if (impliedVolatility != null) 'impliedVolatility': impliedVolatility,
      if (greeks != null) 'greeks': greeks!.toJson(),
    };
  }
}

class OptionChainExpiration {
  const OptionChainExpiration({
    required this.date,
    required this.dayCount,
    required this.quotes,
  });

  factory OptionChainExpiration.fromJson(Map<String, Object?> json) {
    return OptionChainExpiration(
      date:
          DateTime.tryParse(_readString(json, ['date']) ?? '') ??
          DateTime.now(),
      dayCount: _readInt(_readValue(json, ['dayCount'])),
      quotes: _readList(_readValue(json, ['quotes']))
          .whereType<Map>()
          .map(
            (item) => OptionQuote.fromJson(
              Map<String, Object?>.from(item.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false),
    );
  }

  final DateTime date;
  final int dayCount;
  final List<OptionQuote> quotes;

  Map<String, Object?> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayCount': dayCount,
      'quotes': quotes.map((quote) => quote.toJson()).toList(growable: false),
    };
  }
}

class OptionChain {
  const OptionChain({
    required this.underlyingSymbol,
    required this.expirationDate,
    required this.quotes,
    required this.updatedAt,
  });

  factory OptionChain.fromJson(Map<String, Object?> json) {
    return OptionChain(
      underlyingSymbol: _readString(json, ['underlyingSymbol']) ?? '',
      expirationDate:
          DateTime.tryParse(_readString(json, ['expirationDate']) ?? '') ??
          DateTime.now(),
      quotes: _readList(_readValue(json, ['quotes']))
          .whereType<Map>()
          .map(
            (item) => OptionQuote.fromJson(
              Map<String, Object?>.from(item.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false),
      updatedAt:
          DateTime.tryParse(_readString(json, ['updatedAt']) ?? '') ??
          DateTime.now(),
    );
  }

  factory OptionChain.fromJsonString(String source) {
    return OptionChain.fromJson(
      Map<String, Object?>.from(jsonDecode(source) as Map),
    );
  }

  final String underlyingSymbol;
  final DateTime expirationDate;
  final List<OptionQuote> quotes;
  final DateTime updatedAt;

  List<OptionQuote> quotesForType(OptionType type) {
    return quotes
        .where((quote) => quote.optionType == type)
        .toList(growable: false);
  }

  OptionQuote? quoteFor({required OptionType type, required double strike}) {
    for (final quote in quotes) {
      if (quote.optionType == type && (quote.strike - strike).abs() < 0.0001) {
        return quote;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return {
      'underlyingSymbol': underlyingSymbol,
      'expirationDate': expirationDate.toIso8601String(),
      'quotes': quotes.map((quote) => quote.toJson()).toList(growable: false),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

class OptionsChainResult {
  const OptionsChainResult({
    required this.symbol,
    required this.expirations,
    required this.selectedExpiration,
    required this.chain,
    required this.mode,
    required this.updatedAt,
    this.errorMessage,
  });

  final String symbol;
  final List<OptionChainExpiration> expirations;
  final DateTime? selectedExpiration;
  final OptionChain? chain;
  final OptionsChainDataMode mode;
  final DateTime updatedAt;
  final String? errorMessage;

  bool get hasData => chain != null && chain!.quotes.isNotEmpty;
}

enum OptionsChainDataMode { manual, remote }

extension OptionsChainDataModeLabel on OptionsChainDataMode {
  String get label => switch (this) {
    OptionsChainDataMode.manual => 'Manual options input',
    OptionsChainDataMode.remote => 'Remote options data',
  };
}

OptionType? _optionTypeFromName(String? value) {
  return switch (value) {
    'call' => OptionType.call,
    'put' => OptionType.put,
    _ => null,
  };
}

Object? _readValue(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

String? _readString(Map<String, Object?> json, List<String> keys) {
  final value = _readValue(json, keys);
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

double? _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

bool? _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return null;
}

List<Object?> _readList(Object? value) {
  if (value is List) {
    return value;
  }
  return const [];
}

Map<String, Object?>? _readMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return null;
}
