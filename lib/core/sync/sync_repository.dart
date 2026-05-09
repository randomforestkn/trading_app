import 'sync_metadata.dart';
import 'sync_operation.dart';
import 'sync_result.dart';
import '../data/app_result.dart';

abstract class SyncRepository {
  Future<AppResult<SyncMetadata>> loadMetadata();

  Future<AppResult<void>> saveMetadata(SyncMetadata metadata);

  Future<AppResult<SyncOperation>> enqueueOperation(SyncOperation operation);

  Future<AppResult<List<SyncOperation>>> pendingOperations();

  Future<AppResult<void>> markOperationSynced(String operationId);

  Future<AppResult<void>> markOperationFailed(
    String operationId, {
    String? errorMessage,
  });

  Future<AppResult<void>> clearSyncedOperations();

  Future<AppResult<SyncResult>> syncNow();
}
