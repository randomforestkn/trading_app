import 'dart:convert';

import 'sync_status.dart';

class SyncMetadata {
  const SyncMetadata({
    required this.lastSyncedAt,
    required this.lastAttemptedAt,
    required this.pendingOperationsCount,
    required this.lastError,
    required this.deviceId,
    required this.userId,
    required this.syncMode,
  });

  factory SyncMetadata.defaultMetadata({
    SyncMode syncMode = SyncMode.localOnly,
  }) {
    return SyncMetadata(
      lastSyncedAt: null,
      lastAttemptedAt: null,
      pendingOperationsCount: 0,
      lastError: null,
      deviceId: 'local-device',
      userId: null,
      syncMode: syncMode,
    );
  }

  factory SyncMetadata.fromJson(Map<String, Object?> json) {
    return SyncMetadata(
      lastSyncedAt: _parseDateTime(_readString(json, ['lastSyncedAt'])),
      lastAttemptedAt: _parseDateTime(_readString(json, ['lastAttemptedAt'])),
      pendingOperationsCount: _readInt(json['pendingOperationsCount']),
      lastError: _readString(json, ['lastError']),
      deviceId: _readString(json, ['deviceId']) ?? 'local-device',
      userId: _readString(json, ['userId']),
      syncMode:
          _syncModeFromName(_readString(json, ['syncMode'])) ??
          SyncMode.localOnly,
    );
  }

  final DateTime? lastSyncedAt;
  final DateTime? lastAttemptedAt;
  final int pendingOperationsCount;
  final String? lastError;
  final String? deviceId;
  final String? userId;
  final SyncMode syncMode;

  SyncMetadata copyWith({
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    DateTime? lastAttemptedAt,
    bool clearLastAttemptedAt = false,
    int? pendingOperationsCount,
    String? lastError,
    bool clearLastError = false,
    String? deviceId,
    bool clearDeviceId = false,
    String? userId,
    bool clearUserId = false,
    SyncMode? syncMode,
  }) {
    return SyncMetadata(
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      lastAttemptedAt: clearLastAttemptedAt
          ? null
          : lastAttemptedAt ?? this.lastAttemptedAt,
      pendingOperationsCount:
          pendingOperationsCount ?? this.pendingOperationsCount,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      deviceId: clearDeviceId ? null : deviceId ?? this.deviceId,
      userId: clearUserId ? null : userId ?? this.userId,
      syncMode: syncMode ?? this.syncMode,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'lastAttemptedAt': lastAttemptedAt?.toIso8601String(),
      'pendingOperationsCount': pendingOperationsCount,
      'lastError': lastError,
      'deviceId': deviceId,
      'userId': userId,
      'syncMode': syncMode.name,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static SyncMetadata fromJsonString(String source) {
    return SyncMetadata.fromJson(
      Map<String, Object?>.from(jsonDecode(source) as Map),
    );
  }
}

SyncMode? _syncModeFromName(String? value) {
  return switch (value) {
    'localOnly' => SyncMode.localOnly,
    'mockCloud' => SyncMode.mockCloud,
    'remoteReady' => SyncMode.remoteReady,
    _ => null,
  };
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
