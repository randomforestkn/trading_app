import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../models/asset.dart';
import '../utils/app_logger.dart';
import 'app_result.dart';
import 'local_mock_market_repository.dart';
import 'market_repository.dart';
import 'mock_market_data.dart';

class MarketState extends ChangeNotifier {
  MarketState({
    Iterable<TradingAsset>? initialAssets,
    MarketRepository? repository,
    PriceMovementGenerator? movementGenerator,
  }) : _repository =
           repository ??
           LocalMockMarketRepository(
             initialAssets: initialAssets,
             movementGenerator: movementGenerator,
           ) {
    for (final asset in initialAssets ?? MockMarketData.assets) {
      _upsertAsset(asset, resetHistory: true);
    }
  }

  static const int maxHistoryLength = AppConfig.maxMarketHistoryLength;

  final MarketRepository _repository;
  final Map<String, TradingAsset> _assetsBySymbol = {};
  final Map<String, List<double>> _historyBySymbol = {};
  DateTime? _lastRefreshAt;
  bool _isLoading = false;
  String? _errorMessage;

  List<TradingAsset> get assets => List.unmodifiable(_assetsBySymbol.values);

  DateTime? get lastRefreshAt => _lastRefreshAt;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  MarketDataMode get dataMode => _repository.mode;

  List<TradingAsset> get topMovers {
    final sorted = [...assets]
      ..sort(
        (a, b) =>
            b.dailyChangePercent.abs().compareTo(a.dailyChangePercent.abs()),
      );
    return sorted.take(4).toList();
  }

  List<TradingAsset> get crypto =>
      assets.where((asset) => asset.type == AssetType.crypto).toList();

  List<TradingAsset> get etfs =>
      assets.where((asset) => asset.type == AssetType.etf).toList();

  TradingAsset? get biggestGainer {
    if (assets.isEmpty) {
      return null;
    }
    return assets.reduce(
      (best, asset) =>
          asset.dailyChangePercent > best.dailyChangePercent ? asset : best,
    );
  }

  TradingAsset? get biggestLoser {
    if (assets.isEmpty) {
      return null;
    }
    return assets.reduce(
      (worst, asset) =>
          asset.dailyChangePercent < worst.dailyChangePercent ? asset : worst,
    );
  }

  TradingAsset assetBySymbol(String symbol) {
    return _assetsBySymbol[symbol] ??
        MockMarketData.assets.firstWhere((asset) => asset.symbol == symbol);
  }

  TradingAsset latestFor(TradingAsset asset) => assetBySymbol(asset.symbol);

  List<double> historyFor(String symbol) {
    final history = _historyBySymbol[symbol];
    if (history == null || history.isEmpty) {
      return assetBySymbol(symbol).trend;
    }
    return List.unmodifiable(history);
  }

  List<double> timeframeHistoryFor(String symbol, String timeframe) {
    final history = historyFor(symbol);
    final length = switch (timeframe) {
      '1D' => 12,
      '1W' => 20,
      '1M' => maxHistoryLength,
      _ => maxHistoryLength,
    };

    if (history.length <= length) {
      return history;
    }
    return history.sublist(history.length - length);
  }

  Future<void> loadAssets() async {
    _setLoading(true);
    final result = await _repository.loadAssets();
    result.when(
      success: (assets) {
        _assetsBySymbol.clear();
        _historyBySymbol.clear();
        for (final asset in assets) {
          _upsertAsset(asset, resetHistory: true);
        }
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Market asset load failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
  }

  Future<AppResult<void>> refreshPrices() async {
    _setLoading(true);
    final result = await _repository.refreshPrices(assets);
    late final AppResult<void> operationResult;
    result.when(
      success: (assets) {
        for (final asset in assets) {
          _upsertAsset(asset);
        }
        _lastRefreshAt = DateTime.now();
        _errorMessage = null;
        operationResult = const AppSuccess(null);
      },
      failure: (message) {
        AppLogger.warn('Market price refresh failed', error: message);
        _errorMessage = message;
        operationResult = AppFailure(message);
      },
    );
    _setLoading(false);
    return operationResult;
  }

  void _upsertAsset(TradingAsset asset, {bool resetHistory = false}) {
    final existingHistory = resetHistory
        ? asset.trend
        : (_historyBySymbol[asset.symbol] ?? asset.trend);
    final history = _boundedHistory([
      ...existingHistory,
      if (existingHistory.isEmpty || existingHistory.last != asset.price)
        asset.price,
    ]);
    _historyBySymbol[asset.symbol] = history;
    _assetsBySymbol[asset.symbol] = asset.copyWith(
      trend: history.length > 12
          ? history.sublist(history.length - 12)
          : history,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  static List<double> _boundedHistory(List<double> points) {
    if (points.length <= maxHistoryLength) {
      return points;
    }
    return points.sublist(points.length - maxHistoryLength);
  }
}

class MarketScope extends InheritedNotifier<MarketState> {
  const MarketScope({
    required MarketState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static MarketState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MarketScope>();
    assert(scope != null, 'MarketScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
