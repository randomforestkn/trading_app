import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../models/asset.dart';
import '../models/paper_order.dart';
import '../models/portfolio_position.dart';
import 'app_result.dart';
import 'local_paper_trading_repository.dart';
import 'market_state.dart';
import 'mock_market_data.dart';
import 'paper_trading_account.dart';
import 'paper_trading_repository.dart';
import '../utils/app_logger.dart';

class TradeExecutionResult {
  const TradeExecutionResult._({required this.success, required this.message});

  const TradeExecutionResult.success(String message)
    : this._(success: true, message: message);

  const TradeExecutionResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class PaperTradingState extends ChangeNotifier {
  PaperTradingState({
    double initialCashBalance = AppConfig.defaultStartingCash,
    List<PortfolioPosition>? initialPositions,
    List<PaperOrder>? initialOrders,
    DateTime? initialLastUpdated,
    PaperTradingRepository? repository,
  }) : _cashBalance = initialCashBalance,
       _lastUpdated = initialLastUpdated,
       _repository = repository ?? const LocalPaperTradingRepository() {
    for (final position in initialPositions ?? MockMarketData.positions) {
      _positions[position.asset.symbol] = position;
    }
    _orders.addAll(initialOrders ?? const []);
  }

  static const double defaultCashBalance = AppConfig.defaultStartingCash;

  static Future<PaperTradingState> load({
    PaperTradingRepository? repository,
  }) async {
    final accountRepository = repository ?? const LocalPaperTradingRepository();
    final result = await accountRepository.loadAccount();
    return result.when(
      success: (account) =>
          PaperTradingState.fromAccount(account, repository: accountRepository),
      failure: (_) => PaperTradingState(repository: accountRepository),
    );
  }

  factory PaperTradingState.fromAccount(
    PaperTradingAccount account, {
    PaperTradingRepository? repository,
  }) {
    return PaperTradingState(
      initialCashBalance: account.cashBalance,
      initialPositions: account.positions,
      initialOrders: account.orders,
      initialLastUpdated: account.lastUpdated,
      repository: repository,
    );
  }

  factory PaperTradingState.fromJsonString(String source) {
    return PaperTradingState.fromAccount(
      PaperTradingAccount.fromJsonString(source),
    );
  }

  double _cashBalance;
  DateTime? _lastUpdated;
  final Map<String, PortfolioPosition> _positions = {};
  final List<PaperOrder> _orders = [];
  final PaperTradingRepository _repository;
  bool _isSaving = false;
  String? _lastError;

  double get cashBalance => _cashBalance;

  DateTime? get lastUpdated => _lastUpdated;

  bool get isSaving => _isSaving;

  String? get lastError => _lastError;

  List<PortfolioPosition> get positions => List.unmodifiable(
    _positions.values.where((position) => position.quantity > 0),
  );

  List<PortfolioPosition> positionsFor(MarketState marketState) {
    return positions
        .map(
          (position) => PortfolioPosition(
            asset: marketState.assetBySymbol(position.asset.symbol),
            quantity: position.quantity,
            averagePrice: position.averagePrice,
          ),
        )
        .toList(growable: false);
  }

  List<PaperOrder> get orders => List.unmodifiable(_orders.reversed);

  double get positionsValue => positions.fold<double>(
    0,
    (total, position) => total + position.marketValue,
  );

  double positionsValueFor(MarketState marketState) {
    return positionsFor(
      marketState,
    ).fold<double>(0, (total, position) => total + position.marketValue);
  }

  double get unrealizedProfitLoss => positions.fold<double>(
    0,
    (total, position) => total + position.unrealizedProfitLoss,
  );

  double unrealizedProfitLossFor(MarketState marketState) {
    return positionsFor(marketState).fold<double>(
      0,
      (total, position) => total + position.unrealizedProfitLoss,
    );
  }

  double get totalPortfolioValue => cashBalance + positionsValue;

  double totalPortfolioValueFor(MarketState marketState) =>
      cashBalance + positionsValueFor(marketState);

  double quantityFor(String symbol) => _positions[symbol]?.quantity ?? 0;

  Future<TradeExecutionResult> executeOrder({
    required TradingAsset asset,
    required PaperOrderSide side,
    required double quantity,
    required double executionPrice,
  }) async {
    if (quantity <= 0 || executionPrice <= 0) {
      return const TradeExecutionResult.failure(
        'Enter a valid quantity and price.',
      );
    }

    final estimatedTotal = quantity * executionPrice;
    final existingPosition = _positions[asset.symbol];

    if (side == PaperOrderSide.buy) {
      if (estimatedTotal > _cashBalance) {
        return TradeExecutionResult.failure(
          'Insufficient cash. Available: \$${_cashBalance.toStringAsFixed(2)}.',
        );
      }

      final existingQuantity = existingPosition?.quantity ?? 0;
      final existingCost = existingPosition?.averagePrice ?? 0;
      final newQuantity = existingQuantity + quantity;
      final newAverageCost =
          ((existingQuantity * existingCost) + estimatedTotal) / newQuantity;

      _cashBalance -= estimatedTotal;
      _positions[asset.symbol] = PortfolioPosition(
        asset: asset,
        quantity: newQuantity,
        averagePrice: newAverageCost,
      );
    } else {
      final ownedQuantity = existingPosition?.quantity ?? 0;
      if (quantity > ownedQuantity) {
        return TradeExecutionResult.failure(
          'Not enough ${asset.symbol}. Owned: ${ownedQuantity.toStringAsFixed(4)}.',
        );
      }

      _cashBalance += estimatedTotal;
      final remainingQuantity = ownedQuantity - quantity;
      if (remainingQuantity <= 0.0000001) {
        _positions.remove(asset.symbol);
      } else {
        _positions[asset.symbol] = PortfolioPosition(
          asset: asset,
          quantity: remainingQuantity,
          averagePrice: existingPosition!.averagePrice,
        );
      }
    }

    _orders.add(
      PaperOrder(
        assetSymbol: asset.symbol,
        assetName: asset.name,
        side: side,
        quantity: quantity,
        executionPrice: executionPrice,
        estimatedTotal: estimatedTotal,
        timestamp: DateTime.now(),
        status: PaperOrderStatus.filled,
      ),
    );
    _lastUpdated = DateTime.now();
    notifyListeners();
    final saveResult = await _saveAccount(_toAccount());
    if (saveResult is AppFailure<void>) {
      return TradeExecutionResult.failure(saveResult.message);
    }

    return TradeExecutionResult.success(
      '${side.label} order filled for ${quantity.toStringAsFixed(4)} ${asset.symbol}.',
    );
  }

  Future<void> reset() async {
    _setSaving(true);
    final result = await _repository.resetAccount();
    result.when(
      success: (account) {
        _applyAccount(account);
        _lastError = null;
      },
      failure: (message) {
        AppLogger.warn('Paper account reset failed', error: message);
        _lastError = message;
      },
    );
    _setSaving(false);
    notifyListeners();
  }

  Future<void> clearOrderHistory() async {
    _setSaving(true);
    final result = await _repository.clearOrderHistory(_toAccount());
    result.when(
      success: (account) {
        _applyAccount(account);
        _lastError = null;
      },
      failure: (message) {
        AppLogger.warn('Clear order history failed', error: message);
        _lastError = message;
      },
    );
    _setSaving(false);
    notifyListeners();
  }

  String toJsonString() => _toAccount().toJsonString();

  Map<String, Object?> toJson() => _toAccount().toJson();

  PaperTradingAccount _toAccount() {
    return PaperTradingAccount(
      cashBalance: _cashBalance,
      positions: positions,
      orders: List.unmodifiable(_orders),
      lastUpdated: _lastUpdated,
    );
  }

  void _applyAccount(PaperTradingAccount account) {
    _cashBalance = account.cashBalance;
    _lastUpdated = account.lastUpdated;
    _positions
      ..clear()
      ..addEntries(
        account.positions.map(
          (position) => MapEntry(position.asset.symbol, position),
        ),
      );
    _orders
      ..clear()
      ..addAll(account.orders);
  }

  Future<AppResult<void>> _saveAccount(PaperTradingAccount account) async {
    _setSaving(true);
    final result = await _repository.saveAccount(account);
    result.when(
      success: (_) {
        _lastError = null;
      },
      failure: (message) {
        AppLogger.warn('Paper account save failed', error: message);
        _lastError = message;
      },
    );
    _setSaving(false);
    return result;
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}

class PaperTradingScope extends InheritedNotifier<PaperTradingState> {
  const PaperTradingScope({
    required PaperTradingState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static PaperTradingState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PaperTradingScope>();
    assert(
      scope != null,
      'PaperTradingScope was not found in the widget tree.',
    );
    return scope!.notifier!;
  }
}
