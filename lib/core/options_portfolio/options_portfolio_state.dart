import 'package:flutter/widgets.dart';

import '../data/app_result.dart';
import '../strategies/option_contract.dart';
import '../strategies/option_strategy.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_snapshots.dart';
import '../sync/sync_state.dart';
import '../utils/app_logger.dart';
import 'local_options_portfolio_repository.dart';
import 'option_position.dart';
import 'option_trade.dart';
import 'options_portfolio_account.dart';
import 'options_portfolio_repository.dart';
import 'wheel_cycle.dart';

class OptionsPortfolioState extends ChangeNotifier {
  OptionsPortfolioState({
    OptionsPortfolioRepository? repository,
    SyncState? syncState,
  }) : _repository = repository ?? const LocalOptionsPortfolioRepository(),
       _syncState = syncState;

  final OptionsPortfolioRepository _repository;
  final SyncState? _syncState;
  final List<OptionPosition> _positions = [];
  final List<OptionTrade> _trades = [];
  final List<WheelCycle> _wheelCycles = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  List<OptionPosition> get allPositions => List.unmodifiable(_positions);

  List<OptionPosition> get openPositions {
    final positions = _positions.where((position) => position.isOpen).toList();
    positions.sort((left, right) {
      final expirationComparison = left.expirationDate.compareTo(
        right.expirationDate,
      );
      if (expirationComparison != 0) {
        return expirationComparison;
      }
      return right.openedAt.compareTo(left.openedAt);
    });
    return List.unmodifiable(positions);
  }

  List<OptionPosition> get closedPositions {
    return List.unmodifiable(_positions.where((position) => !position.isOpen));
  }

  List<OptionTrade> get trades => List.unmodifiable(_trades);

  List<WheelCycle> get wheelCycles => List.unmodifiable(_wheelCycles);

  static Future<OptionsPortfolioState> load({
    OptionsPortfolioRepository? repository,
    SyncState? syncState,
  }) async {
    final state = OptionsPortfolioState(
      repository: repository,
      syncState: syncState,
    );
    await state.restore();
    return state;
  }

  Future<void> restore() async {
    _setLoading(true);
    late final AppResult<OptionsPortfolioAccount> result;
    try {
      result = await _repository.loadAccount();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Options portfolio restore threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to restore options portfolio.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (account) {
        _applyAccount(account);
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Options portfolio restore failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
  }

  OptionPosition? positionById(String id) {
    for (final position in _positions) {
      if (position.id == id) {
        return position;
      }
    }
    return null;
  }

  List<OptionPosition> positionsByUnderlying(String symbol) {
    return List.unmodifiable(
      _positions
          .where(
            (position) =>
                position.underlyingSymbol.toLowerCase() == symbol.toLowerCase(),
          )
          .toList(growable: false),
    );
  }

  WheelCycle? wheelCycleForUnderlying(String symbol) {
    for (final cycle in _wheelCycles.reversed) {
      if (cycle.underlyingSymbol.toLowerCase() == symbol.toLowerCase()) {
        return cycle;
      }
    }
    return null;
  }

  Future<void> addPosition(OptionPosition position) async {
    final now = DateTime.now();
    final normalized = position.copyWith(
      id: position.id.isEmpty ? _createId(now) : position.id,
      openedAt: position.openedAt,
    );
    _positions.removeWhere((candidate) => candidate.id == normalized.id);
    _positions.insert(0, normalized);
    _appendTrade(
      OptionTrade(
        id: _createTradeId(now),
        positionId: normalized.id,
        createdAt: now,
        eventType: OptionTradeEventType.open,
        premium: normalized.totalPremium,
        quantity: normalized.contractsCount.toDouble(),
        notes: normalized.notes,
      ),
    );
    _updateWheelCycleForOpenPosition(normalized);
    _touch(now);
    notifyListeners();
    await _persist('Unable to save option position.');
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.create,
        entityId: normalized.id,
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
  }

  Future<void> updatePosition(OptionPosition position) async {
    final index = _positions.indexWhere(
      (candidate) => candidate.id == position.id,
    );
    if (index == -1) {
      await addPosition(position);
      return;
    }
    _positions[index] = position;
    _sortPositions();
    _touch(DateTime.now());
    notifyListeners();
    await _persist('Unable to update option position.');
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.update,
        entityId: position.id,
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
  }

  Future<void> closePosition(
    String id, {
    double? realizedPnl,
    String? notes,
    double? currentUnderlyingPrice,
  }) async {
    final position = positionById(id);
    if (position == null) {
      _errorMessage = 'Unable to find option position.';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final updated = position.copyWith(status: OptionPositionStatus.closed);
    _replacePosition(updated);
    final trade = OptionTrade(
      id: _createTradeId(now),
      positionId: updated.id,
      createdAt: now,
      eventType: OptionTradeEventType.close,
      premium: updated.totalPremium,
      quantity: updated.contractsCount.toDouble(),
      realizedPnl:
          realizedPnl ??
          _estimateRealizedPnlForClose(
            updated,
            currentUnderlyingPrice: currentUnderlyingPrice,
          ),
      notes: notes ?? updated.notes,
    );
    _appendTrade(trade);
    _updateWheelCycleForLifecycle(updated, OptionTradeEventType.close);
    _touch(now);
    notifyListeners();
    await _persist('Unable to close option position.');
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.update,
        entityId: updated.id,
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
  }

  Future<void> markExpired(
    String id, {
    String? notes,
    double? currentUnderlyingPrice,
  }) async {
    final position = positionById(id);
    if (position == null) {
      _errorMessage = 'Unable to find option position.';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final updated = position.copyWith(status: OptionPositionStatus.expired);
    _replacePosition(updated);
    _appendTrade(
      OptionTrade(
        id: _createTradeId(now),
        positionId: updated.id,
        createdAt: now,
        eventType: OptionTradeEventType.expireWorthless,
        premium: updated.totalPremium,
        quantity: updated.contractsCount.toDouble(),
        realizedPnl: updated.totalPremium,
        notes: notes ?? updated.notes,
      ),
    );
    _updateWheelCycleForLifecycle(
      updated,
      OptionTradeEventType.expireWorthless,
    );
    _touch(now);
    notifyListeners();
    await _persist('Unable to mark option expired.');
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.update,
        entityId: updated.id,
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
  }

  Future<void> markAssigned(
    String id, {
    double? currentUnderlyingPrice,
    String? notes,
  }) async {
    final position = positionById(id);
    if (position == null) {
      _errorMessage = 'Unable to find option position.';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final updated = position.copyWith(status: OptionPositionStatus.assigned);
    _replacePosition(updated);
    final referencePrice = currentUnderlyingPrice ?? updated.strikePrice;
    final realized = updated.optionType == OptionType.put
        ? updated.totalPremium -
              (updated.side == OptionSide.sell
                  ? (updated.strikePrice - referencePrice)
                            .clamp(0, double.infinity)
                            .toDouble() *
                        updated.sharesControlled
                  : 0.0)
        : updated.totalPremium;
    _appendTrade(
      OptionTrade(
        id: _createTradeId(now),
        positionId: updated.id,
        createdAt: now,
        eventType: OptionTradeEventType.assignment,
        premium: updated.totalPremium,
        quantity: updated.contractsCount.toDouble(),
        realizedPnl: realized,
        notes: notes ?? updated.notes,
      ),
    );
    _updateWheelCycleForAssignment(updated, realized);
    _touch(now);
    notifyListeners();
    await _persist('Unable to mark option assigned.');
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.update,
        entityId: updated.id,
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
  }

  Future<void> deletePosition(String id) async {
    final position = positionById(id);
    if (position == null) {
      return;
    }
    _positions.removeWhere((candidate) => candidate.id == id);
    _trades.removeWhere((trade) => trade.positionId == id);
    for (var index = _wheelCycles.length - 1; index >= 0; index--) {
      final cycle = _wheelCycles[index];
      final updatedPutIds = cycle.putPositionIds
          .where((positionId) => positionId != id)
          .toList(growable: false);
      final updatedCallIds = cycle.callPositionIds
          .where((positionId) => positionId != id)
          .toList(growable: false);
      final shouldRemove =
          updatedPutIds.isEmpty &&
          updatedCallIds.isEmpty &&
          cycle.underlyingSymbol.toLowerCase() ==
              position.underlyingSymbol.toLowerCase();
      if (shouldRemove) {
        _wheelCycles.removeAt(index);
      } else {
        _wheelCycles[index] = cycle.copyWith(
          putPositionIds: updatedPutIds,
          callPositionIds: updatedCallIds,
        );
      }
    }
    _touch(DateTime.now());
    notifyListeners();
    await _persist('Unable to delete option position.');
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.delete,
        entityId: id,
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
  }

  Future<void> reset() async {
    _setSaving(true);
    late final AppResult<OptionsPortfolioAccount> result;
    try {
      result = await _repository.resetAccount();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Options portfolio reset threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to reset options portfolio.';
      _setSaving(false);
      notifyListeners();
      return;
    }
    result.when(
      success: (account) {
        _applyAccount(account);
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Options portfolio reset failed', error: message);
        _errorMessage = message;
      },
    );
    _setSaving(false);
    notifyListeners();
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.reset,
        entityId: 'options-portfolio',
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
  }

  Future<AppResult<void>> replaceAccount(
    OptionsPortfolioAccount account, {
    bool enqueueSync = true,
  }) async {
    _setSaving(true);
    _applyAccount(account);
    late final AppResult<void> result;
    try {
      result = await _repository.saveAccount(_toAccount());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Options portfolio restore from snapshot threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to restore options portfolio.';
      _setSaving(false);
      notifyListeners();
      return const AppFailure('Unable to restore options portfolio.');
    }
    result.when(
      success: (_) {
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn(
          'Options portfolio restore from snapshot failed',
          error: message,
        );
        _errorMessage = message;
      },
    );
    _setSaving(false);
    notifyListeners();
    if (_errorMessage == null && enqueueSync) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.reset,
        entityId: 'options-portfolio',
        payload: optionsPortfolioSnapshot(_toAccount()),
      );
    }
    return _errorMessage == null
        ? const AppSuccess(null)
        : AppFailure(_errorMessage!);
  }

  Map<String, Object?> toJson() => _toAccount().toJson();

  void _applyAccount(OptionsPortfolioAccount account) {
    _positions
      ..clear()
      ..addAll(account.positions);
    _trades
      ..clear()
      ..addAll(account.trades);
    _wheelCycles
      ..clear()
      ..addAll(account.wheelCycles);
    _sortPositions();
    _sortTrades();
    _sortCycles();
    _lastUpdated = account.lastUpdated;
  }

  Future<void> _persist(String failureMessage) async {
    _setSaving(true);
    late final AppResult<void> result;
    try {
      result = await _repository.saveAccount(_toAccount());
    } catch (error, stackTrace) {
      AppLogger.error(failureMessage, error: error, stackTrace: stackTrace);
      _errorMessage = failureMessage;
      _setSaving(false);
      return;
    }
    result.when(
      success: (_) {
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn(failureMessage, error: message);
        _errorMessage = message;
      },
    );
    _setSaving(false);
    notifyListeners();
  }

  OptionsPortfolioAccount _toAccount() {
    return OptionsPortfolioAccount(
      positions: List.unmodifiable(_positions),
      trades: List.unmodifiable(_trades),
      wheelCycles: List.unmodifiable(_wheelCycles),
      lastUpdated: _lastUpdated ?? DateTime.now(),
    );
  }

  void _appendTrade(OptionTrade trade) {
    _trades.removeWhere((candidate) => candidate.id == trade.id);
    _trades.insert(0, trade);
    _sortTrades();
  }

  void _replacePosition(OptionPosition position) {
    final index = _positions.indexWhere(
      (candidate) => candidate.id == position.id,
    );
    if (index == -1) {
      _positions.insert(0, position);
    } else {
      _positions[index] = position;
    }
    _sortPositions();
  }

  void _updateWheelCycleForOpenPosition(OptionPosition position) {
    if (position.linkedStrategy != OptionStrategy.wheel) {
      return;
    }
    final cycle = wheelCycleForUnderlying(position.underlyingSymbol);
    if (position.optionType == OptionType.put) {
      if (cycle == null) {
        _wheelCycles.insert(
          0,
          WheelCycle(
            id: _createId(position.openedAt),
            underlyingSymbol: position.underlyingSymbol,
            startedAt: position.openedAt,
            status: WheelCycleStatus.sellingPuts,
            putPositionIds: [position.id],
            totalPremiumCollected: position.totalPremium,
          ),
        );
      } else {
        _replaceCycle(
          cycle.copyWith(
            status: WheelCycleStatus.sellingPuts,
            putPositionIds: [...cycle.putPositionIds, position.id],
            totalPremiumCollected:
                cycle.totalPremiumCollected + position.totalPremium,
          ),
        );
      }
    } else if (position.optionType == OptionType.call) {
      if (cycle == null) {
        _wheelCycles.insert(
          0,
          WheelCycle(
            id: _createId(position.openedAt),
            underlyingSymbol: position.underlyingSymbol,
            startedAt: position.openedAt,
            status: WheelCycleStatus.sellingCalls,
            callPositionIds: [position.id],
            totalPremiumCollected: position.totalPremium,
          ),
        );
      } else {
        _replaceCycle(
          cycle.copyWith(
            status: WheelCycleStatus.sellingCalls,
            callPositionIds: [...cycle.callPositionIds, position.id],
            totalPremiumCollected:
                cycle.totalPremiumCollected + position.totalPremium,
          ),
        );
      }
    }
    _sortCycles();
  }

  void _updateWheelCycleForAssignment(
    OptionPosition position,
    double realized,
  ) {
    final cycle = wheelCycleForUnderlying(position.underlyingSymbol);
    if (cycle == null) {
      return;
    }
    final nextStatus = position.optionType == OptionType.call
        ? WheelCycleStatus.calledAway
        : WheelCycleStatus.assigned;
    _replaceCycle(
      cycle.copyWith(
        status: nextStatus,
        assignedShares: position.optionType == OptionType.put
            ? position.sharesControlled.toDouble()
            : cycle.assignedShares,
        assignedCostBasis: position.optionType == OptionType.put
            ? position.breakeven
            : cycle.assignedCostBasis,
        realizedPnl: cycle.realizedPnl + realized.toDouble(),
        putPositionIds: position.optionType == OptionType.put
            ? [...cycle.putPositionIds]
            : cycle.putPositionIds,
        callPositionIds: position.optionType == OptionType.call
            ? [...cycle.callPositionIds]
            : cycle.callPositionIds,
      ),
    );
    _sortCycles();
  }

  void _updateWheelCycleForLifecycle(
    OptionPosition position,
    OptionTradeEventType eventType,
  ) {
    final cycle = wheelCycleForUnderlying(position.underlyingSymbol);
    if (cycle == null) {
      return;
    }
    if (eventType == OptionTradeEventType.expireWorthless &&
        position.optionType == OptionType.put) {
      _replaceCycle(cycle.copyWith(status: WheelCycleStatus.closed));
    }
    if (eventType == OptionTradeEventType.close &&
        position.optionType == OptionType.call &&
        position.linkedStrategy == OptionStrategy.wheel) {
      _replaceCycle(cycle.copyWith(status: WheelCycleStatus.calledAway));
    }
    _sortCycles();
  }

  void _replaceCycle(WheelCycle cycle) {
    final index = _wheelCycles.indexWhere(
      (candidate) => candidate.id == cycle.id,
    );
    if (index == -1) {
      _wheelCycles.insert(0, cycle);
    } else {
      _wheelCycles[index] = cycle;
    }
  }

  void _sortPositions() {
    _positions.sort((left, right) {
      final statusComparison = left.status.index.compareTo(right.status.index);
      if (statusComparison != 0) {
        return statusComparison;
      }
      final expirationComparison = left.expirationDate.compareTo(
        right.expirationDate,
      );
      if (expirationComparison != 0) {
        return expirationComparison;
      }
      return right.openedAt.compareTo(left.openedAt);
    });
  }

  void _sortTrades() {
    _trades.sort((left, right) {
      final createdComparison = right.createdAt.compareTo(left.createdAt);
      if (createdComparison != 0) {
        return createdComparison;
      }
      return right.id.compareTo(left.id);
    });
  }

  void _sortCycles() {
    _wheelCycles.sort((left, right) {
      final startedComparison = right.startedAt.compareTo(left.startedAt);
      if (startedComparison != 0) {
        return startedComparison;
      }
      return right.id.compareTo(left.id);
    });
  }

  Future<void> _enqueueSyncOperation({
    required SyncOperationType operationType,
    required String entityId,
    required Map<String, Object?> payload,
  }) async {
    final syncState = _syncState;
    if (syncState == null) {
      return;
    }
    try {
      await syncState.enqueueOperation(
        buildSyncOperation(
          id: 'options-${operationType.name}-${DateTime.now().microsecondsSinceEpoch}',
          entityType: SyncEntityType.optionsPortfolio,
          operationType: operationType,
          entityId: entityId,
          createdAt: DateTime.now(),
          payload: payload,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Options portfolio sync enqueue failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  double _estimateRealizedPnlForClose(
    OptionPosition position, {
    double? currentUnderlyingPrice,
  }) {
    final referencePrice = currentUnderlyingPrice ?? position.strikePrice;
    if (position.optionType == OptionType.put) {
      return position.totalPremium -
          ((position.strikePrice - referencePrice)
                  .clamp(0, double.infinity)
                  .toDouble() *
              position.sharesControlled);
    }
    return position.totalPremium;
  }

  void _touch(DateTime timestamp) {
    _lastUpdated = timestamp;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  String _createId(DateTime timestamp) =>
      'opt-${timestamp.microsecondsSinceEpoch}';

  String _createTradeId(DateTime timestamp) =>
      'opt-trade-${timestamp.microsecondsSinceEpoch}';
}

class OptionsPortfolioScope extends InheritedNotifier<OptionsPortfolioState> {
  const OptionsPortfolioScope({
    required OptionsPortfolioState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static OptionsPortfolioState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OptionsPortfolioScope>();
    assert(
      scope != null,
      'OptionsPortfolioScope was not found in the widget tree.',
    );
    return scope!.notifier!;
  }
}
