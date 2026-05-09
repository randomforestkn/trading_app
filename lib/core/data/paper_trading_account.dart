import 'dart:convert';

import '../config/app_config.dart';
import '../models/asset.dart';
import '../models/paper_order.dart';
import '../models/portfolio_position.dart';
import 'mock_market_data.dart';

class PaperTradingAccount {
  const PaperTradingAccount({
    required this.cashBalance,
    required this.positions,
    required this.orders,
    required this.lastUpdated,
    this.startingCash = defaultStartingCash,
  });

  static const double defaultStartingCash = AppConfig.defaultStartingCash;

  factory PaperTradingAccount.defaultAccount() {
    return PaperTradingAccount(
      cashBalance: defaultStartingCash,
      positions: MockMarketData.positions,
      orders: const [],
      lastUpdated: null,
    );
  }

  factory PaperTradingAccount.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Saved paper trading account must be an object.',
      );
    }
    return PaperTradingAccount.fromJson(decoded);
  }

  factory PaperTradingAccount.fromJson(Map<String, Object?> json) {
    final cashBalance = (json['cashBalance'] as num?)?.toDouble();
    final startingCash = (json['startingCash'] as num?)?.toDouble();
    final positionsJson = json['positions'] as List?;
    final ordersJson = json['orders'] as List?;
    final lastUpdatedValue = json['lastUpdated'] as String?;

    return PaperTradingAccount(
      cashBalance: cashBalance ?? defaultStartingCash,
      startingCash: startingCash ?? defaultStartingCash,
      positions:
          positionsJson
              ?.map(_positionFromJson)
              .whereType<PortfolioPosition>()
              .toList() ??
          MockMarketData.positions,
      orders:
          ordersJson?.map(_orderFromJson).whereType<PaperOrder>().toList() ??
          const [],
      lastUpdated: lastUpdatedValue == null
          ? null
          : DateTime.tryParse(lastUpdatedValue),
    );
  }

  final double startingCash;
  final double cashBalance;
  final List<PortfolioPosition> positions;
  final List<PaperOrder> orders;
  final DateTime? lastUpdated;

  PaperTradingAccount copyWith({
    double? cashBalance,
    List<PortfolioPosition>? positions,
    List<PaperOrder>? orders,
    DateTime? lastUpdated,
    bool clearLastUpdated = false,
  }) {
    return PaperTradingAccount(
      startingCash: startingCash,
      cashBalance: cashBalance ?? this.cashBalance,
      positions: positions ?? this.positions,
      orders: orders ?? this.orders,
      lastUpdated: clearLastUpdated ? null : lastUpdated ?? this.lastUpdated,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, Object?> toJson() {
    return {
      'startingCash': startingCash,
      'cashBalance': cashBalance,
      'positions': positions.map(_positionToJson).toList(),
      'orders': orders.map(_orderToJson).toList(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  static Map<String, Object?> _positionToJson(PortfolioPosition position) {
    return {
      'symbol': position.asset.symbol,
      'quantity': position.quantity,
      'averageCost': position.averagePrice,
    };
  }

  static PortfolioPosition? _positionFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final symbol = value['symbol'] as String?;
    final quantity = (value['quantity'] as num?)?.toDouble();
    final averageCost = (value['averageCost'] as num?)?.toDouble();
    final asset = _assetForSymbol(symbol);
    if (asset == null || quantity == null || averageCost == null) {
      return null;
    }

    return PortfolioPosition(
      asset: asset,
      quantity: quantity,
      averagePrice: averageCost,
    );
  }

  static Map<String, Object?> _orderToJson(PaperOrder order) {
    return {
      'assetSymbol': order.assetSymbol,
      'assetName': order.assetName,
      'side': order.side.name,
      'quantity': order.quantity,
      'executionPrice': order.executionPrice,
      'estimatedTotal': order.estimatedTotal,
      'timestamp': order.timestamp.toIso8601String(),
      'status': order.status.name,
      'averageCostAtExecution': order.averageCostAtExecution,
      'realizedProfitLoss': order.realizedProfitLoss,
    };
  }

  static PaperOrder? _orderFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final assetSymbol = value['assetSymbol'] as String?;
    final assetName = value['assetName'] as String?;
    final sideName = value['side'] as String?;
    final statusName = value['status'] as String?;
    final timestampValue = value['timestamp'] as String?;
    final quantity = (value['quantity'] as num?)?.toDouble();
    final executionPrice = (value['executionPrice'] as num?)?.toDouble();
    final estimatedTotal = (value['estimatedTotal'] as num?)?.toDouble();
    final averageCostAtExecution = (value['averageCostAtExecution'] as num?)
        ?.toDouble();
    final realizedProfitLoss = (value['realizedProfitLoss'] as num?)
        ?.toDouble();
    final side = _sideForName(sideName);
    final status = _statusForName(statusName);
    final timestamp = timestampValue == null
        ? null
        : DateTime.tryParse(timestampValue);

    if (assetSymbol == null ||
        assetName == null ||
        side == null ||
        quantity == null ||
        executionPrice == null ||
        estimatedTotal == null ||
        timestamp == null ||
        status == null) {
      return null;
    }

    return PaperOrder(
      assetSymbol: assetSymbol,
      assetName: assetName,
      side: side,
      quantity: quantity,
      executionPrice: executionPrice,
      estimatedTotal: estimatedTotal,
      timestamp: timestamp,
      status: status,
      averageCostAtExecution: averageCostAtExecution,
      realizedProfitLoss: realizedProfitLoss,
    );
  }

  static TradingAsset? _assetForSymbol(String? symbol) {
    if (symbol == null) {
      return null;
    }
    for (final asset in MockMarketData.assets) {
      if (asset.symbol == symbol) {
        return asset;
      }
    }
    return null;
  }

  static PaperOrderSide? _sideForName(String? name) {
    for (final side in PaperOrderSide.values) {
      if (side.name == name) {
        return side;
      }
    }
    return null;
  }

  static PaperOrderStatus? _statusForName(String? name) {
    for (final status in PaperOrderStatus.values) {
      if (status.name == name) {
        return status;
      }
    }
    return null;
  }
}
