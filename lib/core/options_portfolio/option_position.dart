import 'dart:convert';

import '../analytics/options_analytics.dart';
import '../strategies/option_contract.dart';
import '../strategies/option_strategy.dart';

enum OptionPositionStatus { open, expired, assigned, closed, exercised }

extension OptionPositionStatusLabel on OptionPositionStatus {
  String get label {
    return switch (this) {
      OptionPositionStatus.open => 'Open',
      OptionPositionStatus.expired => 'Expired',
      OptionPositionStatus.assigned => 'Assigned',
      OptionPositionStatus.closed => 'Closed',
      OptionPositionStatus.exercised => 'Exercised',
    };
  }
}

OptionPositionStatus? optionPositionStatusFromName(String? value) {
  return switch (value) {
    'open' => OptionPositionStatus.open,
    'expired' => OptionPositionStatus.expired,
    'assigned' => OptionPositionStatus.assigned,
    'closed' => OptionPositionStatus.closed,
    'exercised' => OptionPositionStatus.exercised,
    _ => null,
  };
}

class OptionPosition {
  const OptionPosition({
    required this.id,
    required this.underlyingSymbol,
    required this.optionType,
    required this.side,
    required this.strikePrice,
    required this.premium,
    required this.contractsCount,
    required this.openedAt,
    required this.expirationDate,
    required this.status,
    this.underlyingName,
    this.multiplier = 100,
    this.linkedStrategy,
    this.linkedUnderlyingPositionId,
    this.notes,
  });

  factory OptionPosition.fromJson(Map<String, Object?> json) {
    return OptionPosition(
      id: _readString(json, ['id']) ?? '',
      underlyingSymbol: _readString(json, ['underlyingSymbol']) ?? '',
      underlyingName: _readString(json, ['underlyingName']),
      optionType: _readString(json, ['optionType']) == 'put'
          ? OptionType.put
          : OptionType.call,
      side: _readString(json, ['side']) == 'buy'
          ? OptionSide.buy
          : OptionSide.sell,
      strikePrice: _readDouble(json, ['strikePrice']),
      premium: _readDouble(json, ['premium']),
      contractsCount: _readInt(json, ['contractsCount']),
      multiplier: _readInt(json, ['multiplier'], fallback: 100),
      openedAt:
          _parseDateTime(_readString(json, ['openedAt'])) ?? DateTime.now(),
      expirationDate:
          _parseDateTime(_readString(json, ['expirationDate'])) ??
          DateTime.now(),
      status:
          optionPositionStatusFromName(_readString(json, ['status'])) ??
          OptionPositionStatus.open,
      linkedStrategy: optionStrategyFromName(
        _readString(json, ['linkedStrategy']),
      ),
      linkedUnderlyingPositionId: _readString(json, [
        'linkedUnderlyingPositionId',
      ]),
      notes: _readString(json, ['notes']),
    );
  }

  final String id;
  final String underlyingSymbol;
  final String? underlyingName;
  final OptionType optionType;
  final OptionSide side;
  final double strikePrice;
  final double premium;
  final int contractsCount;
  final int multiplier;
  final DateTime openedAt;
  final DateTime expirationDate;
  final OptionPositionStatus status;
  final OptionStrategy? linkedStrategy;
  final String? linkedUnderlyingPositionId;
  final String? notes;

  int get sharesControlled => contractsCount * multiplier;

  double get totalPremium => premium * sharesControlled;

  double get capitalAtRisk {
    return switch (side) {
      OptionSide.sell => switch (optionType) {
        OptionType.call => (strikePrice * sharesControlled) - totalPremium,
        OptionType.put => (strikePrice * sharesControlled) - totalPremium,
      },
      OptionSide.buy => totalPremium,
    };
  }

  double get breakeven {
    return switch (optionType) {
      OptionType.call => strikePrice + premium,
      OptionType.put => strikePrice - premium,
    };
  }

  int daysToExpiration([DateTime? asOf]) {
    final reference = asOf ?? DateTime.now();
    final days = expirationDate.difference(reference).inDays;
    return days < 0 ? 0 : days;
  }

  double moneynessPercent(double latestUnderlyingPrice) {
    return OptionsAnalytics.moneynessPercent(
      optionType: optionType,
      underlyingPrice: latestUnderlyingPrice,
      strikePrice: strikePrice,
    );
  }

  double annualizedPremiumYieldPercent([DateTime? asOf]) {
    final days = daysToExpiration(asOf);
    if (days <= 0) {
      return premiumYieldPercent;
    }
    return premiumYieldPercent * (365 / days);
  }

  double get premiumYieldPercent =>
      capitalAtRisk <= 0 ? 0 : (totalPremium / capitalAtRisk) * 100;

  AssignmentRiskLevel assignmentRiskLabel(double latestUnderlyingPrice) {
    return OptionsAnalytics.assignmentRiskLabel(
      optionType: optionType,
      underlyingPrice: latestUnderlyingPrice,
      strikePrice: strikePrice,
    );
  }

  bool get isOpen => status == OptionPositionStatus.open;

  bool get isClosed =>
      status == OptionPositionStatus.closed ||
      status == OptionPositionStatus.expired ||
      status == OptionPositionStatus.assigned ||
      status == OptionPositionStatus.exercised;

  String get displayTitle {
    final strike = strikePrice == strikePrice.roundToDouble()
        ? strikePrice.toStringAsFixed(0)
        : strikePrice.toStringAsFixed(2);
    return '$underlyingSymbol $strike ${optionType.label}';
  }

  OptionPosition copyWith({
    String? id,
    String? underlyingSymbol,
    String? underlyingName,
    bool clearUnderlyingName = false,
    OptionType? optionType,
    OptionSide? side,
    double? strikePrice,
    double? premium,
    int? contractsCount,
    int? multiplier,
    DateTime? openedAt,
    DateTime? expirationDate,
    OptionPositionStatus? status,
    OptionStrategy? linkedStrategy,
    bool clearLinkedStrategy = false,
    String? linkedUnderlyingPositionId,
    bool clearLinkedUnderlyingPositionId = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return OptionPosition(
      id: id ?? this.id,
      underlyingSymbol: underlyingSymbol ?? this.underlyingSymbol,
      underlyingName: clearUnderlyingName
          ? null
          : underlyingName ?? this.underlyingName,
      optionType: optionType ?? this.optionType,
      side: side ?? this.side,
      strikePrice: strikePrice ?? this.strikePrice,
      premium: premium ?? this.premium,
      contractsCount: contractsCount ?? this.contractsCount,
      multiplier: multiplier ?? this.multiplier,
      openedAt: openedAt ?? this.openedAt,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      linkedStrategy: clearLinkedStrategy
          ? null
          : linkedStrategy ?? this.linkedStrategy,
      linkedUnderlyingPositionId: clearLinkedUnderlyingPositionId
          ? null
          : linkedUnderlyingPositionId ?? this.linkedUnderlyingPositionId,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'underlyingSymbol': underlyingSymbol,
      'underlyingName': underlyingName,
      'optionType': optionType.name,
      'side': side.name,
      'strikePrice': strikePrice,
      'premium': premium,
      'contractsCount': contractsCount,
      'multiplier': multiplier,
      'openedAt': openedAt.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'status': status.name,
      'linkedStrategy': linkedStrategy?.name,
      'linkedUnderlyingPositionId': linkedUnderlyingPositionId,
      'notes': notes,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static OptionPosition fromJsonString(String source) {
    return OptionPosition.fromJson(
      Map<String, Object?>.from(jsonDecode(source) as Map),
    );
  }
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

double _readDouble(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
  }
  return 0;
}

int _readInt(Map<String, Object?> json, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
  }
  return fallback;
}
