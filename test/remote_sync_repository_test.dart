import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/remote_sync_repository.dart';
import 'package:trading_app/core/sync/sync_api_client.dart';
import 'package:trading_app/core/sync/sync_operation.dart';
import 'package:trading_app/core/sync/sync_provider_config.dart';
import 'package:trading_app/core/sync/sync_result.dart';
import 'package:trading_app/core/sync/sync_status.dart';

void main() {
  test('RemoteSyncRepository syncs queued operations on success', () async {
    final store = MemorySyncStore();
    final apiClient = _FakeSyncApiClient(
      config: SyncProviderConfig.fromValues(
        provider: 'supabase',
        useRemoteSync: true,
        baseUrl: 'https://sync.example.com',
        publicKey: '',
        namespace: 'cleartrade_demo',
      ),
    );
    final repository = RemoteSyncRepository(
      apiClient: apiClient,
      store: store,
      currentUserIdProvider: () => 'user-1',
    );

    await repository.enqueueOperation(
      SyncOperation(
        id: 'op-1',
        entityType: SyncEntityType.paperAccount,
        operationType: SyncOperationType.update,
        createdAt: DateTime.utc(2026, 1, 1),
        status: SyncOperationStatus.pending,
      ),
    );

    final result = await repository.syncNow();

    expect(
      result.when(
        success: (data) => data.status,
        failure: (_) => SyncStatus.failed,
      ),
      SyncStatus.synced,
    );
    expect(apiClient.pushedOperations, hasLength(1));

    final pending = await repository.pendingOperations();
    expect(pending.when(success: (data) => data.length, failure: (_) => 0), 0);

    final metadata = await repository.loadMetadata();
    expect(
      metadata.when(
        success: (data) => data.lastSyncedAt != null,
        failure: (_) => false,
      ),
      isTrue,
    );
  });

  test(
    'RemoteSyncRepository preserves pending operations on failure',
    () async {
      final store = MemorySyncStore();
      final apiClient = _FakeSyncApiClient(
        config: SyncProviderConfig.fromValues(
          provider: 'supabase',
          useRemoteSync: true,
          baseUrl: 'https://sync.example.com',
          publicKey: '',
          namespace: 'cleartrade_demo',
        ),
        failPush: true,
      );
      final repository = RemoteSyncRepository(
        apiClient: apiClient,
        store: store,
        currentUserIdProvider: () => 'user-1',
      );

      await repository.enqueueOperation(
        SyncOperation(
          id: 'op-2',
          entityType: SyncEntityType.settings,
          operationType: SyncOperationType.update,
          createdAt: DateTime.utc(2026, 1, 1),
          status: SyncOperationStatus.pending,
        ),
      );

      final result = await repository.syncNow();

      expect(
        result.when(
          success: (data) => data.status,
          failure: (_) => SyncStatus.synced,
        ),
        SyncStatus.failed,
      );
      expect(apiClient.pushedOperations, hasLength(1));

      final pending = await repository.pendingOperations();
      expect(
        pending.when(
          success: (data) => data.single.status,
          failure: (_) => SyncOperationStatus.synced,
        ),
        SyncOperationStatus.failed,
      );
    },
  );

  test(
    'RemoteSyncRepository returns safe failure without a user session',
    () async {
      final repository = RemoteSyncRepository(
        apiClient: _FakeSyncApiClient(
          config: SyncProviderConfig.fromValues(
            provider: 'supabase',
            useRemoteSync: true,
            baseUrl: 'https://sync.example.com',
            publicKey: '',
            namespace: 'cleartrade_demo',
          ),
        ),
        store: MemorySyncStore(),
        currentUserIdProvider: () => null,
      );

      await repository.enqueueOperation(
        SyncOperation(
          id: 'op-3',
          entityType: SyncEntityType.journal,
          operationType: SyncOperationType.create,
          createdAt: DateTime.utc(2026, 1, 1),
          status: SyncOperationStatus.pending,
        ),
      );

      final result = await repository.syncNow();
      final syncResult = result.when(
        success: (data) => data,
        failure: (message) => SyncResult(
          status: SyncStatus.failed,
          syncedCount: 0,
          failedCount: 0,
          message: message,
        ),
      );

      expect(syncResult.status, SyncStatus.failed);
      expect(syncResult.message, contains('Sign in required'));

      final pending = await repository.pendingOperations();
      expect(
        pending.when(success: (data) => data.length, failure: (_) => 0),
        1,
      );
    },
  );
}

class _FakeSyncApiClient implements SyncApiClient {
  _FakeSyncApiClient({required this.config, this.failPush = false});

  @override
  final SyncProviderConfig config;

  final bool failPush;
  final List<SyncOperation> pushedOperations = [];

  @override
  Future<AppResult<void>> uploadSnapshot(
    String userId,
    Map<String, Object?> snapshot,
  ) async {
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<Map<String, Object?>>> downloadSnapshot(
    String userId,
  ) async {
    return const AppSuccess(<String, Object?>{});
  }

  @override
  Future<AppResult<void>> pushOperation(
    String userId,
    SyncOperation operation,
  ) async {
    pushedOperations.add(operation);
    if (failPush) {
      return const AppFailure('Push failed.');
    }
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<Map<String, Object?>>> fetchRemoteMetadata(
    String userId,
  ) async {
    return AppSuccess(<String, Object?>{'userId': userId});
  }

  @override
  Future<AppResult<Map<String, Object?>>> resolveConflict(
    String userId,
    Map<String, Object?> localSnapshot,
    Map<String, Object?> remoteSnapshot,
  ) async {
    return AppSuccess(<String, Object?>{
      'userId': userId,
      'localSnapshot': localSnapshot,
      'remoteSnapshot': remoteSnapshot,
    });
  }
}
