enum AssetType { stock, etf, cfd, option, crypto, bond }

extension AssetTypeLabel on AssetType {
  String get label {
    return switch (this) {
      AssetType.stock => 'Stock',
      AssetType.etf => 'ETF',
      AssetType.cfd => 'CFD',
      AssetType.option => 'Option',
      AssetType.crypto => 'Crypto',
      AssetType.bond => 'Bond',
    };
  }
}

class TradingAsset {
  const TradingAsset({
    required this.symbol,
    required this.name,
    required this.type,
    required this.price,
    required this.dailyChangePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.marketCap,
    required this.trend,
    required this.explanation,
    required this.stats,
  });

  final String symbol;
  final String name;
  final AssetType type;
  final double price;
  final double dailyChangePercent;
  final double open;
  final double high;
  final double low;
  final String volume;
  final String marketCap;
  final List<double> trend;
  final String explanation;
  final Map<String, String> stats;

  TradingAsset copyWith({
    double? price,
    double? dailyChangePercent,
    double? open,
    double? high,
    double? low,
    List<double>? trend,
  }) {
    return TradingAsset(
      symbol: symbol,
      name: name,
      type: type,
      price: price ?? this.price,
      dailyChangePercent: dailyChangePercent ?? this.dailyChangePercent,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      volume: volume,
      marketCap: marketCap,
      trend: trend ?? this.trend,
      explanation: explanation,
      stats: stats,
    );
  }

  Map<String, String> get tradingStats => {
    'Open': '\$${open.toStringAsFixed(open > 1000 ? 0 : 2)}',
    'High': '\$${high.toStringAsFixed(high > 1000 ? 0 : 2)}',
    'Low': '\$${low.toStringAsFixed(low > 1000 ? 0 : 2)}',
    'Volume': volume,
    'Market cap': marketCap,
  };
}
