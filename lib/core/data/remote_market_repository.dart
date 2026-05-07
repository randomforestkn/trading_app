import '../models/asset.dart';
import 'app_result.dart';
import 'market_api_client.dart';
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
    final response = await _apiClient.fetchAssets();
    return response.when(
      success: (payloads) {
        final assets = payloads
            .map(_assetFromPayload)
            .whereType<TradingAsset>()
            .toList(growable: false);
        if (assets.isEmpty) {
          return const AppFailure('Remote market data response was empty.');
        }
        return AppSuccess(assets);
      },
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<List<TradingAsset>>> refreshPrices(
    List<TradingAsset> currentAssets,
  ) {
    return loadAssets();
  }

  TradingAsset? _assetFromPayload(Map<String, Object?> payload) {
    final symbol = payload['symbol'] as String?;
    final price = _doubleValue(payload['price']);
    if (symbol == null || symbol.trim().isEmpty || price == null) {
      return null;
    }

    final fallback = _fallbackAsset(symbol);
    final type = _assetTypeFromValue(payload['type']) ?? fallback?.type;
    final dailyChangePercent =
        _doubleValue(payload['dailyChangePercent']) ??
        _doubleValue(payload['changePercent']) ??
        fallback?.dailyChangePercent ??
        0;

    return TradingAsset(
      symbol: symbol,
      name: (payload['name'] as String?) ?? fallback?.name ?? symbol,
      type: type ?? AssetType.stock,
      price: price,
      dailyChangePercent: dailyChangePercent,
      open: _doubleValue(payload['open']) ?? fallback?.open ?? price,
      high: _doubleValue(payload['high']) ?? fallback?.high ?? price,
      low: _doubleValue(payload['low']) ?? fallback?.low ?? price,
      volume: _stringValue(payload['volume']) ?? fallback?.volume ?? 'N/A',
      marketCap:
          _stringValue(payload['marketCap']) ?? fallback?.marketCap ?? 'N/A',
      trend: _trendFromPayload(payload['trend']) ?? fallback?.trend ?? [price],
      explanation:
          (payload['explanation'] as String?) ??
          fallback?.explanation ??
          'Remote market data instrument.',
      stats: fallback?.stats ?? const {},
    );
  }

  TradingAsset? _fallbackAsset(String symbol) {
    for (final asset in MockMarketData.assets) {
      if (asset.symbol == symbol) {
        return asset;
      }
    }
    return null;
  }

  AssetType? _assetTypeFromValue(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return switch (normalized) {
      'stock' || 'stocks' => AssetType.stock,
      'etf' || 'etfs' => AssetType.etf,
      'cfd' || 'cfds' => AssetType.cfd,
      'option' || 'options' => AssetType.option,
      'crypto' || 'cryptocurrency' => AssetType.crypto,
      'bond' || 'bonds' => AssetType.bond,
      _ => null,
    };
  }

  double? _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  List<double>? _trendFromPayload(Object? value) {
    if (value is! List) {
      return null;
    }
    final points = value.map(_doubleValue).whereType<double>().toList();
    return points.isEmpty ? null : points;
  }
}
