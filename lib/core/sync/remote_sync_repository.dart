import '../data/app_result.dart';
import 'local_sync_repository.dart';
import 'sync_api_client.dart';
import 'sync_metadata.dart';
import 'sync_operation.dart';
import 'sync_repository.dart';
import 'sync_result.dart';
import 'sync_status.dart';

class RemoteSyncRepository implements SyncRepository {
  RemoteSyncRepository({
    required SyncApiClient apiClient,
    SyncStore? store,
    String? Function()? currentUserIdProvider,
  }) : _apiClient = apiClient,
       _local = LocalSyncRepository(
         store: store,
         syncMode: SyncMode.remoteReady,
       ),
       _currentUserIdProvider = currentUserIdProvider;

  final SyncApiClient _apiClient;
  final LocalSyncRepository _local;
  final String? Function()? _currentUserIdProvider;

  @override
  bool get isRemoteSync => true;

  @override
  Future<AppResult<SyncMetadata>> loadMetadata() => _local.loadMetadata();

  @override
  Future<AppResult<void>> saveMetadata(SyncMetadata metadata) =>
      _local.saveMetadata(metadata);

  @override
  Future<AppResult<SyncOperation>> enqueueOperation(SyncOperation operation) =>
      _local.enqueueOperation(operation);

  @override
  Future<AppResult<List<SyncOperation>>> pendingOperations() =>
      _local.pendingOperations();

  @override
  Future<AppResult<void>> markOperationSynced(String operationId) =>
      _local.markOperationSynced(operationId);

  @override
  Future<AppResult<void>> markOperationFailed(
    String operationId, {
    String? errorMessage,
  }) => _local.markOperationFailed(operationId, errorMessage: errorMessage);

  @override
  Future<AppResult<void>> clearSyncedOperations() =>
      _local.clearSyncedOperations();

  @override
  Future<AppResult<SyncResult>> syncNow() async {
    final userId = _currentUserIdProvider?.call();
    if (userId == null || userId.trim().isEmpty) {
      const message = 'Sign in required for cloud sync.';
      await _local.saveMetadata(
        (await _local.loadMetadata()).when(
          success: (metadata) => metadata.copyWith(
            lastAttemptedAt: DateTime.now(),
            lastError: message,
            clearLastSyncedAt: false,
          ),
          failure: (_) => SyncMetadata.defaultMetadata(
            syncMode: SyncMode.remoteReady,
          ).copyWith(lastAttemptedAt: DateTime.now(), lastError: message),
        ),
      );
      return const AppSuccess(
        SyncResult(
          status: SyncStatus.failed,
          syncedCount: 0,
          failedCount: 0,
          message: message,
        ),
      );
    }

    final metadataResult = await _local.loadMetadata();
    final operationsResult = await _local.pendingOperations();
    final metadata = metadataResult.when(
      success: (value) => value,
      failure: (_) =>
          SyncMetadata.defaultMetadata(syncMode: SyncMode.remoteReady),
    );
    final operations = operationsResult.when(
      success: (value) => value,
      failure: (_) => const <SyncOperation>[],
    );

    final now = DateTime.now();
    final failureMessages = <String>[];
    var syncedCount = 0;
    for (final operation in operations) {
      if (operation.status == SyncOperationStatus.synced) {
        continue;
      }
      final result = await _apiClient.pushOperation(userId, operation);
      if (result is AppSuccess<void>) {
        syncedCount += 1;
        await _local.markOperationSynced(operation.id);
      } else {
        final message = (result as AppFailure<void>).message;
        failureMessages.add(message);
        await _local.markOperationFailed(operation.id, errorMessage: message);
      }
    }

    final snapshot = {
      'createdAt': now.toIso8601String(),
      'namespace': _apiClient.config.namespace,
      'metadata': metadata.toJson(),
      'operations': operations.map((operation) => operation.toJson()).toList(),
      'pendingOperationsCount': operations
          .where((operation) => operation.status != SyncOperationStatus.synced)
          .length,
    };
    final uploadSnapshotResult = await _apiClient.uploadSnapshot(
      userId,
      snapshot,
    );
    uploadSnapshotResult.when(
      success: (_) {},
      failure: (message) => failureMessages.add(message),
    );

    final remoteMetadataResult = await _apiClient.fetchRemoteMetadata(userId);
    remoteMetadataResult.when(
      success: (_) {},
      failure: (message) => failureMessages.add(message),
    );

    if (failureMessages.isEmpty) {
      await _local.saveMetadata(
        metadata.copyWith(
          lastAttemptedAt: now,
          lastSyncedAt: now,
          lastError: null,
          pendingOperationsCount: 0,
          userId: userId,
          syncMode: SyncMode.remoteReady,
        ),
      );
      return AppSuccess(
        SyncResult(
          status: SyncStatus.synced,
          syncedCount: syncedCount,
          failedCount: 0,
        ),
      );
    }

    final failureMessage = failureMessages.first;
    await _local.saveMetadata(
      metadata.copyWith(
        lastAttemptedAt: now,
        lastError: failureMessage,
        pendingOperationsCount: operations
            .where(
              (operation) => operation.status != SyncOperationStatus.synced,
            )
            .length,
        userId: userId,
        syncMode: SyncMode.remoteReady,
      ),
    );
    return AppSuccess(
      SyncResult(
        status: SyncStatus.failed,
        syncedCount: syncedCount,
        failedCount: operations.length - syncedCount,
        message: failureMessage,
      ),
    );
  }
}
