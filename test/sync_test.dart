import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/data/paper_trading_store.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/option_position.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/core/strategies/option_strategy.dart';
import 'package:trading_app/core/strategies/option_contract.dart';
import 'package:trading_app/core/sync/local_sync_repository.dart';
import 'package:trading_app/core/sync/sync_metadata.dart';
import 'package:trading_app/core/sync/sync_operation.dart';
import 'package:trading_app/core/sync/sync_repository.dart';
import 'package:trading_app/core/sync/sync_state.dart';
import 'package:trading_app/core/sync/sync_status.dart';
import 'package:trading_app/core/sync/sync_result.dart';
import 'package:trading_app/core/models/paper_order.dart';

void main() {
  test('SyncOperation roundtrip serialization', () {
    final operation = SyncOperation(
      id: 'op-1',
      entityType: SyncEntityType.journal,
      operationType: SyncOperationType.update,
      entityId: 'journal-1',
      createdAt: DateTime.utc(2026, 1, 1),
      payloadHash: 'hash',
      status: SyncOperationStatus.failed,
      errorMessage: 'boom',
      retryCount: 2,
      payload: {'key': 'value'},
    );

    final roundTrip = SyncOperation.fromJsonString(operation.toJsonString());

    expect(roundTrip.id, operation.id);
    expect(roundTrip.entityType, operation.entityType);
    expect(roundTrip.operationType, operation.operationType);
    expect(roundTrip.entityId, operation.entityId);
    expect(roundTrip.payloadHash, operation.payloadHash);
    expect(roundTrip.status, operation.status);
    expect(roundTrip.errorMessage, operation.errorMessage);
    expect(roundTrip.retryCount, operation.retryCount);
    expect(roundTrip.payload?['key'], 'value');
  });

  test('SyncMetadata roundtrip serialization', () {
    final metadata = SyncMetadata(
      lastSyncedAt: DateTime.utc(2026, 1, 2),
      lastAttemptedAt: DateTime.utc(2026, 1, 3),
      pendingOperationsCount: 4,
      lastError: 'offline',
      deviceId: 'device-1',
      userId: 'user-1',
      syncMode: SyncMode.mockCloud,
    );

    final roundTrip = SyncMetadata.fromJsonString(metadata.toJsonString());

    expect(roundTrip.lastSyncedAt, metadata.lastSyncedAt);
    expect(roundTrip.lastAttemptedAt, metadata.lastAttemptedAt);
    expect(roundTrip.pendingOperationsCount, metadata.pendingOperationsCount);
    expect(roundTrip.lastError, metadata.lastError);
    expect(roundTrip.deviceId, metadata.deviceId);
    expect(roundTrip.userId, metadata.userId);
    expect(roundTrip.syncMode, metadata.syncMode);
  });

  test('LocalSyncRepository enqueues and updates operations', () async {
    final store = MemorySyncStore();
    final repository = LocalSyncRepository(
      store: store,
      syncMode: SyncMode.mockCloud,
      syncNowBehavior: (_) => false,
    );

    final operation = SyncOperation(
      id: 'op-2',
      entityType: SyncEntityType.paperAccount,
      operationType: SyncOperationType.update,
      entityId: 'paper-account',
      createdAt: DateTime.utc(2026, 1, 1),
      status: SyncOperationStatus.pending,
    );
    await repository.enqueueOperation(operation);

    final pending = await repository.pendingOperations();
    expect(pending.when(success: (data) => data.length, failure: (_) => 0), 1);

    await repository.markOperationFailed(
      operation.id,
      errorMessage: 'temporary failure',
    );
    final failed = await repository.pendingOperations();
    expect(
      failed.when(
        success: (data) =>
            data.singleWhere((item) => item.id == operation.id).status,
        failure: (_) => SyncOperationStatus.synced,
      ),
      SyncOperationStatus.failed,
    );

    await repository.markOperationSynced(operation.id);
    await repository.clearSyncedOperations();
    final cleared = await repository.pendingOperations();
    expect(cleared.when(success: (data) => data.length, failure: (_) => 0), 0);
  });

  test('SyncState syncNow success and failure states', () async {
    final successRepository = LocalSyncRepository(
      store: MemorySyncStore(),
      syncMode: SyncMode.mockCloud,
      syncNowBehavior: (_) => false,
    );
    final failingRepository = LocalSyncRepository(
      store: MemorySyncStore(),
      syncMode: SyncMode.mockCloud,
      syncNowBehavior: (_) => true,
    );

    final operation = SyncOperation(
      id: 'op-3',
      entityType: SyncEntityType.settings,
      operationType: SyncOperationType.update,
      createdAt: DateTime.utc(2026, 1, 1),
      status: SyncOperationStatus.pending,
    );
    await successRepository.enqueueOperation(operation);
    await failingRepository.enqueueOperation(operation);

    final successState = SyncState(repository: successRepository);
    await successState.refreshMetadata();
    final successResult = await successState.syncNow();
    expect(
      successResult.when(
        success: (data) => data.status,
        failure: (_) => SyncStatus.failed,
      ),
      SyncStatus.synced,
    );
    expect(successState.status, SyncStatus.synced);

    final failureState = SyncState(repository: failingRepository);
    await failureState.refreshMetadata();
    final failureResult = await failureState.syncNow();
    expect(
      failureResult.when(
        success: (data) => data.status,
        failure: (_) => SyncStatus.synced,
      ),
      SyncStatus.failed,
    );
    expect(failureState.status, SyncStatus.failed);
    expect(failureState.errorMessage, isNotNull);
  });

  test('local mutations enqueue sync operations but still succeed', () async {
    final failingSyncRepository = _FailingSyncRepository();
    final syncState = SyncState(repository: failingSyncRepository);
    await syncState.refreshMetadata();

    final paperRepository = LocalPaperTradingRepository(
      store: MemoryPaperTradingStore(),
    );
    final paperState = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
      repository: paperRepository,
      syncState: syncState,
    );
    final paperResult = await paperState.executeOrder(
      asset: MockMarketData.assets.first,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: 100,
    );
    expect(paperResult.success, isTrue);
    expect(paperState.positions, isNotEmpty);

    final journalRepository = LocalJournalRepository(
      store: MemoryJournalStore(),
    );
    final journalState = JournalState(
      repository: journalRepository,
      syncState: syncState,
    );
    await journalState.addEntry(
      JournalEntry(
        id: 'journal-1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        title: 'Test',
        body: 'Test body',
        linkedAssetSymbol: 'NVO',
      ),
    );
    expect(journalState.entries, isNotEmpty);

    final optionsRepository = LocalOptionsPortfolioRepository(
      store: MemoryOptionsPortfolioStore(),
    );
    final optionsState = OptionsPortfolioState(
      repository: optionsRepository,
      syncState: syncState,
    );
    await optionsState.addPosition(
      OptionPosition(
        id: 'opt-1',
        underlyingSymbol: 'NVO',
        optionType: OptionType.put,
        side: OptionSide.sell,
        strikePrice: 100,
        premium: 1.5,
        contractsCount: 1,
        openedAt: DateTime.utc(2026, 1, 1),
        expirationDate: DateTime.utc(2026, 2, 1),
        status: OptionPositionStatus.open,
        linkedStrategy: OptionStrategy.cashSecuredPut,
      ),
    );
    expect(optionsState.allPositions, isNotEmpty);

    expect(syncState.errorMessage, isNotNull);
  });

  test('paper trading mutations enqueue pending sync operations', () async {
    final syncRepository = LocalSyncRepository(
      store: MemorySyncStore(),
      syncMode: SyncMode.mockCloud,
    );
    final syncState = SyncState(repository: syncRepository);
    await syncState.refreshMetadata();

    final paperState = PaperTradingState(
      initialCashBalance: 1000,
      initialPositions: const [],
      repository: LocalPaperTradingRepository(store: MemoryPaperTradingStore()),
      syncState: syncState,
    );

    final result = await paperState.executeOrder(
      asset: MockMarketData.assets.first,
      side: PaperOrderSide.buy,
      quantity: 1,
      executionPrice: 100,
    );

    expect(result.success, isTrue);
    expect(syncState.pendingOperations, isNotEmpty);
    expect(syncState.metadata.pendingOperationsCount, 1);
  });
}

class _FailingSyncRepository implements SyncRepository {
  @override
  Future<AppResult<SyncMetadata>> loadMetadata() async {
    return AppSuccess(
      SyncMetadata.defaultMetadata(syncMode: SyncMode.mockCloud),
    );
  }

  @override
  Future<AppResult<void>> saveMetadata(SyncMetadata metadata) async {
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<SyncOperation>> enqueueOperation(
    SyncOperation operation,
  ) async {
    return const AppFailure('Queue unavailable.');
  }

  @override
  Future<AppResult<List<SyncOperation>>> pendingOperations() async {
    return const AppSuccess(<SyncOperation>[]);
  }

  @override
  Future<AppResult<void>> markOperationSynced(String operationId) async {
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> markOperationFailed(
    String operationId, {
    String? errorMessage,
  }) async {
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> clearSyncedOperations() async {
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<SyncResult>> syncNow() async {
    return const AppFailure('Sync unavailable.');
  }
}
