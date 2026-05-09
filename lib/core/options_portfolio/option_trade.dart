import 'dart:convert';

enum OptionTradeEventType { open, close, expireWorthless, assignment, exercise }

extension OptionTradeEventTypeLabel on OptionTradeEventType {
  String get label {
    return switch (this) {
      OptionTradeEventType.open => 'Open',
      OptionTradeEventType.close => 'Close',
      OptionTradeEventType.expireWorthless => 'Expire worthless',
      OptionTradeEventType.assignment => 'Assignment',
      OptionTradeEventType.exercise => 'Exercise',
    };
  }
}

OptionTradeEventType? optionTradeEventTypeFromName(String? value) {
  return switch (value) {
    'open' => OptionTradeEventType.open,
    'close' => OptionTradeEventType.close,
    'expireWorthless' => OptionTradeEventType.expireWorthless,
    'assignment' => OptionTradeEventType.assignment,
    'exercise' => OptionTradeEventType.exercise,
    _ => null,
  };
}

class OptionTrade {
  const OptionTrade({
    required this.id,
    required this.positionId,
    required this.createdAt,
    required this.eventType,
    required this.premium,
    required this.quantity,
    this.realizedPnl,
    this.notes,
  });

  factory OptionTrade.fromJson(Map<String, Object?> json) {
    return OptionTrade(
      id: _readString(json, ['id']) ?? '',
      positionId: _readString(json, ['positionId']) ?? '',
      createdAt:
          _parseDateTime(_readString(json, ['createdAt'])) ?? DateTime.now(),
      eventType:
          optionTradeEventTypeFromName(_readString(json, ['eventType'])) ??
          OptionTradeEventType.open,
      premium: _readDouble(json, ['premium']),
      quantity: _readDouble(json, ['quantity']),
      realizedPnl: _readNullableDouble(json, ['realizedPnl']),
      notes: _readString(json, ['notes']),
    );
  }

  final String id;
  final String positionId;
  final DateTime createdAt;
  final OptionTradeEventType eventType;
  final double premium;
  final double quantity;
  final double? realizedPnl;
  final String? notes;

  OptionTrade copyWith({
    String? id,
    String? positionId,
    DateTime? createdAt,
    OptionTradeEventType? eventType,
    double? premium,
    double? quantity,
    double? realizedPnl,
    bool clearRealizedPnl = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return OptionTrade(
      id: id ?? this.id,
      positionId: positionId ?? this.positionId,
      createdAt: createdAt ?? this.createdAt,
      eventType: eventType ?? this.eventType,
      premium: premium ?? this.premium,
      quantity: quantity ?? this.quantity,
      realizedPnl: clearRealizedPnl ? null : realizedPnl ?? this.realizedPnl,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'positionId': positionId,
      'createdAt': createdAt.toIso8601String(),
      'eventType': eventType.name,
      'premium': premium,
      'quantity': quantity,
      'realizedPnl': realizedPnl,
      'notes': notes,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static OptionTrade fromJsonString(String source) {
    return OptionTrade.fromJson(
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

double? _readNullableDouble(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
  }
  return null;
}
