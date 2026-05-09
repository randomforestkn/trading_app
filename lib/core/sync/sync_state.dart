import 'package:flutter/widgets.dart';

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'sync_metadata.dart';
import 'sync_operation.dart';
import 'sync_repository.dart';
import 'sync_result.dart';
import 'sync_status.dart';

class SyncState extends ChangeNotifier {
  SyncState({required SyncRepository repository}) : _repository = repository;

  final SyncRepository _repository;
  SyncMetadata _metadata = SyncMetadata.defaultMetadata();
  List<SyncOperation> _pendingOperations = const [];
  bool _isSyncing = false;
  String? _errorMessage;

  SyncStatus get status {
    if (_isSyncing) {
      return SyncStatus.syncing;
    }
    if (_errorMessage != null) {
      return SyncStatus.failed;
    }
    if (_metadata.syncMode == SyncMode.localOnly) {
      return SyncStatus.offline;
    }
    if (_pendingOperations.isNotEmpty) {
      return SyncStatus.idle;
    }
    return SyncStatus.synced;
  }

  SyncMetadata get metadata => _metadata;

  List<SyncOperation> get pendingOperations => List.unmodifiable(
    _pendingOperations
        .where((operation) => operation.status != SyncOperationStatus.synced)
        .toList(growable: false),
  );

  bool get isSyncing => _isSyncing;

  String? get errorMessage => _errorMessage;

  Future<void> refreshMetadata() async {
    var hadFailure = false;
    try {
      final metadataResult = await _repository.loadMetadata();
      final operationsResult = await _repository.pendingOperations();
      metadataResult.when(
        success: (metadata) => _metadata = metadata,
        failure: (message) {
          AppLogger.warn('Sync metadata refresh failed', error: message);
          _errorMessage = message;
          hadFailure = true;
        },
      );
      operationsResult.when(
        success: (operations) => _pendingOperations = operations,
        failure: (message) {
          AppLogger.warn('Sync pending ops refresh failed', error: message);
          _errorMessage = message;
          hadFailure = true;
        },
      );
      if (!hadFailure) {
        _errorMessage = _metadata.lastError;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sync metadata refresh threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to load sync state.';
    }
    notifyListeners();
  }

  Future<void> restoreMetadata(SyncMetadata metadata) async {
    _metadata = metadata.copyWith(
      pendingOperationsCount: _pendingOperations
          .where((operation) => operation.status != SyncOperationStatus.synced)
          .length,
    );
    try {
      await _repository.saveMetadata(_metadata);
      _errorMessage = null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sync metadata restore threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to restore sync metadata.';
    }
    notifyListeners();
  }

  Future<void> enqueueOperation(SyncOperation operation) async {
    try {
      final result = await _repository.enqueueOperation(operation);
      result.when(
        success: (savedOperation) {
          _pendingOperations = [
            savedOperation,
            ..._pendingOperations.where((item) => item.id != savedOperation.id),
          ];
          _metadata = _metadata.copyWith(
            pendingOperationsCount: _pendingOperations
                .where((item) => item.status != SyncOperationStatus.synced)
                .length,
            lastAttemptedAt: operation.createdAt,
            clearLastError: true,
          );
          _errorMessage = null;
        },
        failure: (message) {
          AppLogger.warn('Sync enqueue failed', error: message);
          _errorMessage = message;
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sync enqueue threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to enqueue sync operation.';
    }
    notifyListeners();
  }

  Future<AppResult<SyncResult>> syncNow() async {
    _setSyncing(true);
    late final AppResult<SyncResult> result;
    try {
      result = await _repository.syncNow();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sync now threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to sync.';
      _setSyncing(false);
      notifyListeners();
      return const AppFailure('Unable to sync.');
    }
    result.when(
      success: (syncResult) {
        _errorMessage = syncResult.hasFailures ? syncResult.message : null;
      },
      failure: (message) {
        AppLogger.warn('Sync now failed', error: message);
        _errorMessage = message;
      },
    );
    _setSyncing(false);
    if (result is AppSuccess<SyncResult>) {
      await refreshMetadata();
    }
    notifyListeners();
    return result;
  }

  Future<void> retryFailed() async {
    final failedOperations = _pendingOperations
        .where((operation) => operation.status == SyncOperationStatus.failed)
        .toList(growable: false);
    for (final operation in failedOperations) {
      await enqueueOperation(
        operation.copyWith(
          status: SyncOperationStatus.pending,
          clearErrorMessage: true,
        ),
      );
    }
  }

  Future<void> clearSynced() async {
    var refreshed = false;
    try {
      final result = await _repository.clearSyncedOperations();
      result.when(
        success: (_) {
          refreshed = true;
        },
        failure: (message) {
          AppLogger.warn('Clear synced operations failed', error: message);
          _errorMessage = message;
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Clear synced operations threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to clear synced operations.';
    }
    if (refreshed) {
      await refreshMetadata();
    }
    notifyListeners();
  }

  void _setSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }
}

class SyncScope extends InheritedNotifier<SyncState> {
  const SyncScope({required SyncState state, required super.child, super.key})
    : super(notifier: state);

  static SyncState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SyncScope>();
    assert(scope != null, 'SyncScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
