import 'dart:convert';

enum SyncEntityType {
  paperAccount,
  journal,
  optionsPortfolio,
  authSession,
  settings,
}

extension SyncEntityTypeLabel on SyncEntityType {
  String get label {
    return switch (this) {
      SyncEntityType.paperAccount => 'Paper account',
      SyncEntityType.journal => 'Journal',
      SyncEntityType.optionsPortfolio => 'Options portfolio',
      SyncEntityType.authSession => 'Auth session',
      SyncEntityType.settings => 'Settings',
    };
  }
}

SyncEntityType? syncEntityTypeFromName(String? value) {
  return switch (value) {
    'paperAccount' => SyncEntityType.paperAccount,
    'journal' => SyncEntityType.journal,
    'optionsPortfolio' => SyncEntityType.optionsPortfolio,
    'authSession' => SyncEntityType.authSession,
    'settings' => SyncEntityType.settings,
    _ => null,
  };
}

enum SyncOperationType { create, update, delete, reset, clear }

extension SyncOperationTypeLabel on SyncOperationType {
  String get label {
    return switch (this) {
      SyncOperationType.create => 'Create',
      SyncOperationType.update => 'Update',
      SyncOperationType.delete => 'Delete',
      SyncOperationType.reset => 'Reset',
      SyncOperationType.clear => 'Clear',
    };
  }
}

SyncOperationType? syncOperationTypeFromName(String? value) {
  return switch (value) {
    'create' => SyncOperationType.create,
    'update' => SyncOperationType.update,
    'delete' => SyncOperationType.delete,
    'reset' => SyncOperationType.reset,
    'clear' => SyncOperationType.clear,
    _ => null,
  };
}

enum SyncOperationStatus { pending, syncing, synced, failed }

extension SyncOperationStatusLabel on SyncOperationStatus {
  String get label {
    return switch (this) {
      SyncOperationStatus.pending => 'Pending',
      SyncOperationStatus.syncing => 'Syncing',
      SyncOperationStatus.synced => 'Synced',
      SyncOperationStatus.failed => 'Failed',
    };
  }
}

SyncOperationStatus? syncOperationStatusFromName(String? value) {
  return switch (value) {
    'pending' => SyncOperationStatus.pending,
    'syncing' => SyncOperationStatus.syncing,
    'synced' => SyncOperationStatus.synced,
    'failed' => SyncOperationStatus.failed,
    _ => null,
  };
}

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.createdAt,
    required this.status,
    this.entityId,
    this.payloadHash,
    this.errorMessage,
    this.retryCount = 0,
    this.payload,
  });

  factory SyncOperation.fromJson(Map<String, Object?> json) {
    return SyncOperation(
      id: _readString(json, ['id']) ?? '',
      entityType:
          syncEntityTypeFromName(_readString(json, ['entityType'])) ??
          SyncEntityType.settings,
      operationType:
          syncOperationTypeFromName(_readString(json, ['operationType'])) ??
          SyncOperationType.update,
      entityId: _readString(json, ['entityId']),
      createdAt:
          DateTime.tryParse(_readString(json, ['createdAt']) ?? '') ??
          DateTime.now(),
      payloadHash: _readString(json, ['payloadHash']),
      status:
          syncOperationStatusFromName(_readString(json, ['status'])) ??
          SyncOperationStatus.pending,
      errorMessage: _readString(json, ['errorMessage']),
      retryCount: _readInt(json['retryCount']),
      payload: _readMap(json['payload']),
    );
  }

  final String id;
  final SyncEntityType entityType;
  final SyncOperationType operationType;
  final String? entityId;
  final DateTime createdAt;
  final String? payloadHash;
  final SyncOperationStatus status;
  final String? errorMessage;
  final int retryCount;
  final Map<String, Object?>? payload;

  SyncOperation copyWith({
    String? id,
    SyncEntityType? entityType,
    SyncOperationType? operationType,
    String? entityId,
    bool clearEntityId = false,
    DateTime? createdAt,
    String? payloadHash,
    bool clearPayloadHash = false,
    SyncOperationStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? retryCount,
    Map<String, Object?>? payload,
    bool clearPayload = false,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      entityId: clearEntityId ? null : entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
      payloadHash: clearPayloadHash ? null : payloadHash ?? this.payloadHash,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      payload: clearPayload ? null : payload ?? this.payload,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'entityType': entityType.name,
      'operationType': operationType.name,
      'entityId': entityId,
      'createdAt': createdAt.toIso8601String(),
      'payloadHash': payloadHash,
      'status': status.name,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'payload': payload,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static SyncOperation fromJsonString(String source) {
    return SyncOperation.fromJson(
      Map<String, Object?>.from(jsonDecode(source) as Map),
    );
  }
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

Map<String, Object?>? _readMap(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value.cast<String, dynamic>());
  }
  return null;
}
