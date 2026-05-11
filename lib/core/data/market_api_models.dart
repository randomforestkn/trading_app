import '../models/asset.dart';

class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.price,
    this.name,
    this.type,
    this.open,
    this.high,
    this.low,
    this.close,
    this.change,
    this.changePercent,
    this.volume,
    this.timestamp,
  });

  final String symbol;
  final String? name;
  final AssetType? type;
  final double price;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final double? change;
  final double? changePercent;
  final String? volume;
  final DateTime? timestamp;
}

class MarketCandle {
  const MarketCandle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final String? volume;
}
