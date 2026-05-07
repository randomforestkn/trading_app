import 'dart:math';

import '../config/app_config.dart';
import '../models/asset.dart';
import 'app_result.dart';
import 'market_repository.dart';
import 'mock_market_data.dart';

typedef PriceMovementGenerator = double Function(TradingAsset asset);

class LocalMockMarketRepository implements MarketRepository {
  LocalMockMarketRepository({
    Iterable<TradingAsset>? initialAssets,
    Random? random,
    PriceMovementGenerator? movementGenerator,
  }) : _initialAssets = List.unmodifiable(
         initialAssets ?? MockMarketData.assets,
       ),
       _random = random ?? Random(),
       _movementGenerator = movementGenerator;

  final List<TradingAsset> _initialAssets;
  final Random _random;
  final PriceMovementGenerator? _movementGenerator;

  @override
  MarketDataMode get mode => MarketDataMode.demo;

  @override
  Future<AppResult<List<TradingAsset>>> loadAssets() async {
    return AppSuccess([..._initialAssets]);
  }

  @override
  Future<AppResult<List<TradingAsset>>> refreshPrices(
    List<TradingAsset> currentAssets,
  ) async {
    final refreshed = currentAssets
        .map((asset) {
          final movement =
              _movementGenerator?.call(asset) ??
              (AppConfig.simulatedPriceMovementMin +
                  (_random.nextDouble() *
                      (AppConfig.simulatedPriceMovementMax -
                          AppConfig.simulatedPriceMovementMin)));
          final newPrice = asset.price * (1 + movement);

          return asset.copyWith(
            price: newPrice,
            dailyChangePercent: asset.dailyChangePercent + (movement * 100),
            high: max(asset.high, newPrice),
            low: min(asset.low, newPrice),
          );
        })
        .toList(growable: false);

    return AppSuccess(refreshed);
  }
}
