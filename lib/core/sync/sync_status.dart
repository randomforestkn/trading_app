enum SyncStatus { idle, syncing, synced, failed, offline, conflict }

extension SyncStatusLabel on SyncStatus {
  String get label {
    return switch (this) {
      SyncStatus.idle => 'Idle',
      SyncStatus.syncing => 'Syncing',
      SyncStatus.synced => 'Synced',
      SyncStatus.failed => 'Failed',
      SyncStatus.offline => 'Offline',
      SyncStatus.conflict => 'Conflict',
    };
  }
}

enum SyncMode { localOnly, mockCloud, remoteReady }

extension SyncModeLabel on SyncMode {
  String get label {
    return switch (this) {
      SyncMode.localOnly => 'Local only',
      SyncMode.mockCloud => 'Mock cloud',
      SyncMode.remoteReady => 'Remote ready',
    };
  }
}
