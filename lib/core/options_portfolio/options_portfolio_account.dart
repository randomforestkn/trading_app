import 'dart:convert';

import 'option_position.dart';
import 'option_trade.dart';
import 'wheel_cycle.dart';

class OptionsPortfolioAccount {
  const OptionsPortfolioAccount({
    required this.positions,
    required this.trades,
    required this.wheelCycles,
    required this.lastUpdated,
  });

  factory OptionsPortfolioAccount.defaultAccount() {
    return OptionsPortfolioAccount(
      positions: const [],
      trades: const [],
      wheelCycles: const [],
      lastUpdated: DateTime.now(),
    );
  }

  factory OptionsPortfolioAccount.fromJson(Map<String, Object?> json) {
    return OptionsPortfolioAccount(
      positions: _parsePositions(json['positions']),
      trades: _parseTrades(json['trades']),
      wheelCycles: _parseCycles(json['wheelCycles']),
      lastUpdated:
          _parseDateTime(_readString(json, ['lastUpdated'])) ?? DateTime.now(),
    );
  }

  factory OptionsPortfolioAccount.fromJsonString(String source) {
    return OptionsPortfolioAccount.fromJson(
      Map<String, Object?>.from(jsonDecode(source) as Map),
    );
  }

  final List<OptionPosition> positions;
  final List<OptionTrade> trades;
  final List<WheelCycle> wheelCycles;
  final DateTime lastUpdated;

  OptionsPortfolioAccount copyWith({
    List<OptionPosition>? positions,
    List<OptionTrade>? trades,
    List<WheelCycle>? wheelCycles,
    DateTime? lastUpdated,
  }) {
    return OptionsPortfolioAccount(
      positions: positions ?? this.positions,
      trades: trades ?? this.trades,
      wheelCycles: wheelCycles ?? this.wheelCycles,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'positions': positions.map((position) => position.toJson()).toList(),
      'trades': trades.map((trade) => trade.toJson()).toList(),
      'wheelCycles': wheelCycles.map((cycle) => cycle.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String? _readString(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

List<OptionPosition> _parsePositions(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map(
        (item) => OptionPosition.fromJson(
          Map<String, Object?>.from(item.cast<String, dynamic>()),
        ),
      )
      .toList(growable: false);
}

List<OptionTrade> _parseTrades(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map(
        (item) => OptionTrade.fromJson(
          Map<String, Object?>.from(item.cast<String, dynamic>()),
        ),
      )
      .toList(growable: false);
}

List<WheelCycle> _parseCycles(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map(
        (item) => WheelCycle.fromJson(
          Map<String, Object?>.from(item.cast<String, dynamic>()),
        ),
      )
      .toList(growable: false);
}
