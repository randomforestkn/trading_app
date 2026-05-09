import '../data/market_state.dart';
import '../data/paper_trading_state.dart';
import '../models/paper_order.dart';
import 'portfolio_analytics.dart';
import 'performance_snapshot.dart';

class TradedAssetSummary {
  const TradedAssetSummary({
    required this.symbol,
    required this.name,
    required this.orderCount,
    required this.totalQuantity,
    required this.totalNotional,
  });

  final String symbol;
  final String name;
  final int orderCount;
  final double totalQuantity;
  final double totalNotional;
}

class TradingActivityAnalytics {
  const TradingActivityAnalytics({
    required this.totalOrders,
    required this.buyOrderCount,
    required this.sellOrderCount,
    required this.totalBuyVolume,
    required this.totalSellVolume,
    required this.averageOrderSize,
    required this.largestOrder,
    required this.mostTradedAsset,
    required this.lastTradeDate,
  });

  final int totalOrders;
  final int buyOrderCount;
  final int sellOrderCount;
  final double totalBuyVolume;
  final double totalSellVolume;
  final double averageOrderSize;
  final PaperOrder? largestOrder;
  final TradedAssetSummary? mostTradedAsset;
  final DateTime? lastTradeDate;

  static TradingActivityAnalytics fromState(PaperTradingState tradingState) {
    final orders = tradingState.orders;
    final buyOrders = orders
        .where((order) => order.side == PaperOrderSide.buy)
        .toList(growable: false);
    final sellOrders = orders
        .where((order) => order.side == PaperOrderSide.sell)
        .toList(growable: false);
    final totalBuyVolume = buyOrders.fold<double>(
      0,
      (total, order) => total + order.estimatedTotal,
    );
    final totalSellVolume = sellOrders.fold<double>(
      0,
      (total, order) => total + order.estimatedTotal,
    );
    final largestOrder = orders.isEmpty
        ? null
        : orders.reduce(
            (largest, current) =>
                current.estimatedTotal > largest.estimatedTotal
                ? current
                : largest,
          );
    final lastTradeDate = orders.isEmpty ? null : orders.first.timestamp;

    final byAsset = <String, _AssetTradeAggregate>{};
    for (final order in orders) {
      final aggregate = byAsset.putIfAbsent(
        order.assetSymbol,
        () => _AssetTradeAggregate(order.assetSymbol, order.assetName),
      );
      aggregate.orderCount += 1;
      aggregate.totalQuantity += order.quantity;
      aggregate.totalNotional += order.estimatedTotal;
    }

    TradedAssetSummary? mostTradedAsset;
    if (byAsset.isNotEmpty) {
      final aggregate = byAsset.values.reduce(
        (best, current) =>
            current.totalNotional > best.totalNotional ? current : best,
      );
      mostTradedAsset = TradedAssetSummary(
        symbol: aggregate.symbol,
        name: aggregate.name,
        orderCount: aggregate.orderCount,
        totalQuantity: aggregate.totalQuantity,
        totalNotional: aggregate.totalNotional,
      );
    }

    return TradingActivityAnalytics(
      totalOrders: orders.length,
      buyOrderCount: buyOrders.length,
      sellOrderCount: sellOrders.length,
      totalBuyVolume: totalBuyVolume,
      totalSellVolume: totalSellVolume,
      averageOrderSize: orders.isEmpty
          ? 0
          : orders.fold<double>(
                  0,
                  (total, order) => total + order.estimatedTotal,
                ) /
                orders.length,
      largestOrder: largestOrder,
      mostTradedAsset: mostTradedAsset,
      lastTradeDate: lastTradeDate,
    );
  }
}

class TradingAnalytics {
  const TradingAnalytics._();

  static PortfolioAnalytics portfolio({
    required PaperTradingState tradingState,
    required MarketState marketState,
  }) {
    return PortfolioAnalytics.fromState(
      tradingState: tradingState,
      marketState: marketState,
    );
  }

  static TradingActivityAnalytics activity({
    required PaperTradingState tradingState,
  }) {
    return TradingActivityAnalytics.fromState(tradingState);
  }

  static PerformanceSnapshot performance({
    required PaperTradingState tradingState,
    required MarketState marketState,
  }) {
    final portfolioAnalytics = portfolio(
      tradingState: tradingState,
      marketState: marketState,
    );
    return PerformanceSnapshot.fromPortfolio(portfolioAnalytics);
  }
}

class _AssetTradeAggregate {
  _AssetTradeAggregate(this.symbol, this.name);

  final String symbol;
  final String name;
  int orderCount = 0;
  double totalQuantity = 0;
  double totalNotional = 0;
}
