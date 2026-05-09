import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'sync_metadata.dart';
import 'sync_operation.dart';
import 'sync_repository.dart';
import 'sync_result.dart';
import 'sync_status.dart';

abstract class SyncStore {
  Future<String?> readMetadata();
  Future<void> writeMetadata(String value);
  Future<String?> readOperations();
  Future<void> writeOperations(String value);
  Future<void> clear();
}

class SharedPreferencesSyncStore implements SyncStore {
  static const _metadataKey = 'sync_metadata_v1';
  static const _operationsKey = 'sync_operations_v1';

  @override
  Future<String?> readMetadata() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_metadataKey);
  }

  @override
  Future<void> writeMetadata(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_metadataKey, value);
  }

  @override
  Future<String?> readOperations() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_operationsKey);
  }

  @override
  Future<void> writeOperations(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_operationsKey, value);
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_metadataKey);
    await preferences.remove(_operationsKey);
  }
}

class MemorySyncStore implements SyncStore {
  String? metadata;
  String? operations;

  @override
  Future<String?> readMetadata() async => metadata;

  @override
  Future<void> writeMetadata(String value) async {
    metadata = value;
  }

  @override
  Future<String?> readOperations() async => operations;

  @override
  Future<void> writeOperations(String value) async {
    operations = value;
  }

  @override
  Future<void> clear() async {
    metadata = null;
    operations = null;
  }
}

class LocalSyncRepository implements SyncRepository {
  const LocalSyncRepository({
    this.store,
    this.syncMode = SyncMode.localOnly,
    this.syncNowBehavior,
  });

  final SyncStore? store;
  final SyncMode syncMode;
  final bool Function(List<SyncOperation> operations)? syncNowBehavior;

  @override
  Future<AppResult<SyncMetadata>> loadMetadata() async {
    final savedMetadata = await store?.readMetadata();
    if (savedMetadata == null) {
      return AppSuccess(SyncMetadata.defaultMetadata(syncMode: syncMode));
    }
    try {
      return AppSuccess(SyncMetadata.fromJsonString(savedMetadata));
    } on FormatException catch (error, stackTrace) {
      AppLogger.warn(
        'Sync metadata contained invalid data',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return AppSuccess(SyncMetadata.defaultMetadata(syncMode: syncMode));
    } on TypeError catch (error, stackTrace) {
      AppLogger.warn(
        'Sync metadata contained invalid types',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return AppSuccess(SyncMetadata.defaultMetadata(syncMode: syncMode));
    }
  }

  @override
  Future<AppResult<void>> saveMetadata(SyncMetadata metadata) async {
    await store?.writeMetadata(metadata.toJsonString());
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<SyncOperation>> enqueueOperation(
    SyncOperation operation,
  ) async {
    final operations = await _readOperations();
    final pending = operation.copyWith(
      status: SyncOperationStatus.pending,
      retryCount: operation.retryCount,
    );
    operations.removeWhere((item) => item.id == pending.id);
    operations.insert(0, pending);
    await _writeOperations(operations);
    await _updateMetadata(pendingOperationsCount: _countPending(operations));
    return AppSuccess(pending);
  }

  @override
  Future<AppResult<List<SyncOperation>>> pendingOperations() async {
    final operations = await _readOperations();
    return AppSuccess(
      operations
          .where((operation) => operation.status != SyncOperationStatus.synced)
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<void>> markOperationSynced(String operationId) async {
    final operations = await _readOperations();
    final index = operations.indexWhere(
      (operation) => operation.id == operationId,
    );
    if (index == -1) {
      return const AppFailure('Sync operation not found.');
    }
    operations[index] = operations[index].copyWith(
      status: SyncOperationStatus.synced,
      clearErrorMessage: true,
    );
    await _writeOperations(operations);
    await _updateMetadata(pendingOperationsCount: _countPending(operations));
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> markOperationFailed(
    String operationId, {
    String? errorMessage,
  }) async {
    final operations = await _readOperations();
    final index = operations.indexWhere(
      (operation) => operation.id == operationId,
    );
    if (index == -1) {
      return const AppFailure('Sync operation not found.');
    }
    operations[index] = operations[index].copyWith(
      status: SyncOperationStatus.failed,
      errorMessage: errorMessage,
      retryCount: operations[index].retryCount + 1,
    );
    await _writeOperations(operations);
    await _updateMetadata(
      lastError: errorMessage,
      pendingOperationsCount: _countPending(operations),
    );
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> clearSyncedOperations() async {
    final operations = await _readOperations();
    final remaining = operations
        .where((operation) => operation.status != SyncOperationStatus.synced)
        .toList(growable: false);
    await _writeOperations(remaining);
    await _updateMetadata(pendingOperationsCount: _countPending(remaining));
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<SyncResult>> syncNow() async {
    final now = DateTime.now();
    final operations = await _readOperations();
    await _updateMetadata(lastAttemptedAt: now);

    if (syncMode == SyncMode.localOnly) {
      final metadataResult = await loadMetadata();
      final metadata = metadataResult is AppSuccess<SyncMetadata>
          ? metadataResult.data.copyWith(
              lastAttemptedAt: now,
              pendingOperationsCount: _countPending(operations),
              lastError: null,
              syncMode: syncMode,
            )
          : SyncMetadata.defaultMetadata(syncMode: syncMode).copyWith(
              lastAttemptedAt: now,
              pendingOperationsCount: _countPending(operations),
            );
      await saveMetadata(metadata);
      return AppSuccess(
        SyncResult(
          status: SyncStatus.offline,
          syncedCount: 0,
          failedCount: 0,
          message: 'Local-only sync mode is offline.',
        ),
      );
    }

    final shouldFail = syncNowBehavior?.call(operations) ?? false;
    if (shouldFail) {
      final failedMessage = 'Mock cloud sync failed.';
      await _updateMetadata(
        lastError: failedMessage,
        pendingOperationsCount: _countPending(operations),
      );
      return AppSuccess(
        SyncResult(
          status: SyncStatus.failed,
          syncedCount: 0,
          failedCount: operations.length,
          message: failedMessage,
        ),
      );
    }

    var syncedCount = 0;
    for (final operation in operations) {
      if (operation.status != SyncOperationStatus.synced) {
        syncedCount += 1;
      }
    }
    final syncedOperations = operations
        .map(
          (operation) => operation.copyWith(status: SyncOperationStatus.synced),
        )
        .toList(growable: false);
    await _writeOperations(syncedOperations);
    await _updateMetadata(
      lastSyncedAt: now,
      lastError: null,
      pendingOperationsCount: _countPending(syncedOperations),
    );
    return AppSuccess(
      SyncResult(
        status: SyncStatus.synced,
        syncedCount: syncedCount,
        failedCount: 0,
      ),
    );
  }

  Future<List<SyncOperation>> _readOperations() async {
    final savedOperations = await store?.readOperations();
    if (savedOperations == null) {
      return <SyncOperation>[];
    }
    try {
      final decoded = jsonDecode(savedOperations);
      if (decoded is! List) {
        throw const FormatException('Saved sync operations must be a list.');
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => SyncOperation.fromJson(
              Map<String, Object?>.from(item.cast<String, dynamic>()),
            ),
          )
          .toList(growable: true);
    } on FormatException catch (error, stackTrace) {
      AppLogger.warn(
        'Sync operations contained invalid data',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return <SyncOperation>[];
    } on TypeError catch (error, stackTrace) {
      AppLogger.warn(
        'Sync operations contained invalid types',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return <SyncOperation>[];
    }
  }

  Future<void> _writeOperations(List<SyncOperation> operations) async {
    await store?.writeOperations(
      jsonEncode(operations.map((operation) => operation.toJson()).toList()),
    );
  }

  Future<void> _updateMetadata({
    DateTime? lastSyncedAt,
    DateTime? lastAttemptedAt,
    int? pendingOperationsCount,
    String? lastError,
    bool clearLastError = false,
    SyncMode? syncMode,
  }) async {
    final currentMetadataResult = await loadMetadata();
    final currentMetadata = currentMetadataResult.when(
      success: (metadata) => metadata,
      failure: (_) => SyncMetadata.defaultMetadata(syncMode: this.syncMode),
    );
    final updated = currentMetadata.copyWith(
      lastSyncedAt: lastSyncedAt,
      lastAttemptedAt: lastAttemptedAt,
      pendingOperationsCount:
          pendingOperationsCount ?? currentMetadata.pendingOperationsCount,
      lastError: lastError,
      clearLastError: clearLastError,
      syncMode: syncMode ?? this.syncMode,
    );
    await saveMetadata(updated);
  }

  int _countPending(List<SyncOperation> operations) {
    return operations
        .where((operation) => operation.status != SyncOperationStatus.synced)
        .length;
  }
}
