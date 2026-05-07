import 'asset.dart';

class PortfolioPosition {
  const PortfolioPosition({
    required this.asset,
    required this.quantity,
    required this.averagePrice,
  });

  final TradingAsset asset;
  final double quantity;
  final double averagePrice;

  double get marketValue => quantity * asset.price;

  double get unrealizedProfitLoss => (asset.price - averagePrice) * quantity;

  double get unrealizedProfitLossPercent => averagePrice == 0
      ? 0
      : ((asset.price - averagePrice) / averagePrice) * 100;
}
