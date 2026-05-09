import 'dart:convert';

enum WheelCycleStatus {
  sellingPuts,
  assigned,
  sellingCalls,
  calledAway,
  closed,
}

extension WheelCycleStatusLabel on WheelCycleStatus {
  String get label {
    return switch (this) {
      WheelCycleStatus.sellingPuts => 'Selling puts',
      WheelCycleStatus.assigned => 'Assigned',
      WheelCycleStatus.sellingCalls => 'Selling calls',
      WheelCycleStatus.calledAway => 'Called away',
      WheelCycleStatus.closed => 'Closed',
    };
  }
}

WheelCycleStatus? wheelCycleStatusFromName(String? value) {
  return switch (value) {
    'sellingPuts' => WheelCycleStatus.sellingPuts,
    'assigned' => WheelCycleStatus.assigned,
    'sellingCalls' => WheelCycleStatus.sellingCalls,
    'calledAway' => WheelCycleStatus.calledAway,
    'closed' => WheelCycleStatus.closed,
    _ => null,
  };
}

class WheelCycle {
  const WheelCycle({
    required this.id,
    required this.underlyingSymbol,
    required this.startedAt,
    required this.status,
    this.putPositionIds = const [],
    this.callPositionIds = const [],
    this.assignedShares = 0,
    this.assignedCostBasis = 0,
    this.totalPremiumCollected = 0,
    this.realizedPnl = 0,
    this.notes,
  });

  factory WheelCycle.fromJson(Map<String, Object?> json) {
    return WheelCycle(
      id: _readString(json, ['id']) ?? '',
      underlyingSymbol: _readString(json, ['underlyingSymbol']) ?? '',
      startedAt:
          _parseDateTime(_readString(json, ['startedAt'])) ?? DateTime.now(),
      status:
          wheelCycleStatusFromName(_readString(json, ['status'])) ??
          WheelCycleStatus.sellingPuts,
      putPositionIds: _parseStringList(json['putPositionIds']),
      callPositionIds: _parseStringList(json['callPositionIds']),
      assignedShares: _readDouble(json, ['assignedShares']),
      assignedCostBasis: _readDouble(json, ['assignedCostBasis']),
      totalPremiumCollected: _readDouble(json, ['totalPremiumCollected']),
      realizedPnl: _readDouble(json, ['realizedPnl']),
      notes: _readString(json, ['notes']),
    );
  }

  final String id;
  final String underlyingSymbol;
  final DateTime startedAt;
  final WheelCycleStatus status;
  final List<String> putPositionIds;
  final List<String> callPositionIds;
  final double assignedShares;
  final double assignedCostBasis;
  final double totalPremiumCollected;
  final double realizedPnl;
  final String? notes;

  WheelCycle copyWith({
    String? id,
    String? underlyingSymbol,
    DateTime? startedAt,
    WheelCycleStatus? status,
    List<String>? putPositionIds,
    List<String>? callPositionIds,
    double? assignedShares,
    double? assignedCostBasis,
    double? totalPremiumCollected,
    double? realizedPnl,
    String? notes,
    bool clearNotes = false,
  }) {
    return WheelCycle(
      id: id ?? this.id,
      underlyingSymbol: underlyingSymbol ?? this.underlyingSymbol,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
      putPositionIds: putPositionIds ?? this.putPositionIds,
      callPositionIds: callPositionIds ?? this.callPositionIds,
      assignedShares: assignedShares ?? this.assignedShares,
      assignedCostBasis: assignedCostBasis ?? this.assignedCostBasis,
      totalPremiumCollected:
          totalPremiumCollected ?? this.totalPremiumCollected,
      realizedPnl: realizedPnl ?? this.realizedPnl,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'underlyingSymbol': underlyingSymbol,
      'startedAt': startedAt.toIso8601String(),
      'status': status.name,
      'putPositionIds': putPositionIds,
      'callPositionIds': callPositionIds,
      'assignedShares': assignedShares,
      'assignedCostBasis': assignedCostBasis,
      'totalPremiumCollected': totalPremiumCollected,
      'realizedPnl': realizedPnl,
      'notes': notes,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static WheelCycle fromJsonString(String source) {
    return WheelCycle.fromJson(
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

List<String> _parseStringList(Object? value) {
  if (value is List) {
    return value
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}
