import '../config/app_config.dart';
import '../models/asset.dart';
import 'app_result.dart';

enum MarketDataMode {
  demo,
  remote;

  String get label => AppConfig.marketModeLabel(this);
}

abstract class MarketRepository {
  MarketDataMode get mode;

  Future<AppResult<List<TradingAsset>>> loadAssets();

  Future<AppResult<List<TradingAsset>>> refreshPrices(
    List<TradingAsset> currentAssets,
  );
}
