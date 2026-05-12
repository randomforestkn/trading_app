import '../models/asset.dart';
import '../utils/app_logger.dart';
import 'app_result.dart';
import 'market_api_client.dart';
import 'market_api_models.dart';
import 'market_repository.dart';
import 'mock_market_data.dart';

class RemoteMarketRepository implements MarketRepository {
  const RemoteMarketRepository({required MarketApiClient apiClient})
    : _apiClient = apiClient;

  final MarketApiClient _apiClient;

  @override
  MarketDataMode get mode => MarketDataMode.remote;

  @override
  Future<AppResult<List<TradingAsset>>> loadAssets() async {
    return fetchAssets();
  }

  @override
  Future<AppResult<List<TradingAsset>>> refreshPrices(
    List<TradingAsset> currentAssets,
  ) {
    final assets = currentAssets.isEmpty
        ? MockMarketData.assets
        : currentAssets;
    return _fetchRemoteAssets(assets);
  }

  Future<AppResult<List<TradingAsset>>> fetchAssets() {
    return _fetchRemoteAssets(MockMarketData.assets);
  }

  Future<AppResult<List<TradingAsset>>> _fetchRemoteAssets(
    List<TradingAsset> fallbackAssets,
  ) async {
    if (fallbackAssets.isEmpty) {
      return const AppFailure('Remote market data universe is empty.');
    }

    final mergedAssets = <TradingAsset>[];
    var supportedSymbolCount = 0;
    var successCount = 0;

    for (final fallback in fallbackAssets) {
      final remoteSymbol = _remoteSymbolForAsset(fallback);
      if (remoteSymbol == null) {
        mergedAssets.add(fallback);
        continue;
      }

      supportedSymbolCount++;
      final response = await _apiClient.fetchQuote(remoteSymbol);
      final asset = response.when(
        success: (quote) {
          successCount++;
          return _assetFromQuote(
                quote,
                fallback,
                localSymbol: fallback.symbol,
              ) ??
              fallback;
        },
        failure: (message) {
          AppLogger.warn(
            'Remote market quote fetch failed for ${fallback.symbol}',
            error: message,
          );
          return fallback;
        },
      );
      mergedAssets.add(asset);
    }

    if (supportedSymbolCount == 0) {
      AppLogger.warn(
        'Remote market provider did not support any configured mock symbols.',
      );
      return AppSuccess(mergedAssets);
    }

    if (successCount == 0) {
      AppLogger.warn('Remote market quote refresh failed for all symbols.');
      return const AppFailure('Remote market data refresh failed.');
    }

    return AppSuccess(mergedAssets);
  }

  TradingAsset? _assetFromQuote(
    MarketQuote quote,
    TradingAsset? fallback, {
    required String localSymbol,
  }) {
    final price = quote.price;
    final type = quote.type ?? fallback?.type;
    final previousPrice = fallback?.price;
    final change = quote.change ?? _derivedChange(price, previousPrice);
    final dailyChangePercent =
        quote.changePercent ??
        _derivedChangePercent(change, previousPrice) ??
        fallback?.dailyChangePercent ??
        0;

    return TradingAsset(
      symbol: localSymbol,
      name: quote.name ?? fallback?.name ?? localSymbol,
      type: type ?? AssetType.stock,
      price: price,
      dailyChangePercent: dailyChangePercent,
      open: quote.open ?? fallback?.open ?? previousPrice ?? price,
      high: quote.high ?? fallback?.high ?? price,
      low: quote.low ?? fallback?.low ?? price,
      volume: quote.volume ?? fallback?.volume ?? 'N/A',
      marketCap: fallback?.marketCap ?? 'N/A',
      trend: fallback?.trend ?? [price],
      explanation: fallback?.explanation ?? 'Remote market data instrument.',
      stats: fallback?.stats ?? const {},
    );
  }

  String? _remoteSymbolForAsset(TradingAsset asset) {
    switch (asset.type) {
      case AssetType.stock:
      case AssetType.etf:
        return asset.symbol;
      case AssetType.crypto:
        final normalized = asset.symbol.toUpperCase();
        if (normalized.contains('/')) {
          return normalized;
        }
        return '$normalized/USD';
      case AssetType.cfd:
      case AssetType.option:
      case AssetType.bond:
        return null;
    }
  }

  double? _derivedChange(double price, double? previousPrice) {
    if (previousPrice == null) {
      return null;
    }
    return price - previousPrice;
  }

  double? _derivedChangePercent(double? change, double? previousPrice) {
    if (change == null || previousPrice == null || previousPrice == 0) {
      return null;
    }
    return (change / previousPrice) * 100;
  }
}
