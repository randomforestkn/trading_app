import '../models/asset.dart';
import 'market_api_models.dart';

abstract class MarketProviderAdapter {
  const MarketProviderAdapter();

  String get providerName;

  bool get supportsBatchQuotes;

  bool get supportsHistoricalCandles;

  String get quotePath;

  String get batchQuotePath;

  String get historicalCandlesPath;

  String get apiKeyQueryParameter;

  Map<String, String> quoteQueryParameters({
    required String symbol,
    required String apiKey,
  });

  Map<String, String> batchQuoteQueryParameters({
    required List<String> symbols,
    required String apiKey,
  });

  Map<String, String> historicalCandlesQueryParameters({
    required String symbol,
    required String apiKey,
    required String interval,
    required int outputSize,
  });

  MarketQuote? parseQuote(Map<String, Object?> json);

  List<MarketQuote> parseQuoteCollection(Object? decoded);

  List<MarketCandle> parseHistoricalCandles(Object? decoded);

  AssetType? parseAssetType(Object? value);

  double? parseDouble(Object? value);

  String? parseString(Object? value);
}

class TwelveDataMarketProviderAdapter implements MarketProviderAdapter {
  const TwelveDataMarketProviderAdapter();

  @override
  String get providerName => 'twelvedata';

  @override
  bool get supportsBatchQuotes => true;

  @override
  bool get supportsHistoricalCandles => true;

  @override
  String get quotePath => '/quote';

  @override
  String get batchQuotePath => '/quote';

  @override
  String get historicalCandlesPath => '/time_series';

  @override
  String get apiKeyQueryParameter => 'apikey';

  @override
  Map<String, String> quoteQueryParameters({
    required String symbol,
    required String apiKey,
  }) {
    return {'symbol': symbol, 'apikey': apiKey};
  }

  @override
  Map<String, String> batchQuoteQueryParameters({
    required List<String> symbols,
    required String apiKey,
  }) {
    return {'symbol': symbols.join(','), 'apikey': apiKey};
  }

  @override
  Map<String, String> historicalCandlesQueryParameters({
    required String symbol,
    required String apiKey,
    required String interval,
    required int outputSize,
  }) {
    return {
      'symbol': symbol,
      'interval': interval,
      'outputsize': outputSize.toString(),
      'format': 'JSON',
      'apikey': apiKey,
    };
  }

  @override
  MarketQuote? parseQuote(Map<String, Object?> json) {
    final symbol = parseString(json['symbol']);
    final price =
        parseDouble(json['price']) ??
        parseDouble(json['close']) ??
        parseDouble(json['last']) ??
        parseDouble(json['c']);
    if (symbol == null || price == null) {
      return null;
    }

    return MarketQuote(
      symbol: symbol,
      name: parseString(json['name']),
      type: parseAssetType(json['type']),
      price: price,
      open: parseDouble(json['open']) ?? parseDouble(json['o']),
      high: parseDouble(json['high']) ?? parseDouble(json['h']),
      low: parseDouble(json['low']) ?? parseDouble(json['l']),
      close: parseDouble(json['close']) ?? parseDouble(json['price']) ?? price,
      change: parseDouble(json['change']) ?? parseDouble(json['price_change']),
      changePercent:
          parseDouble(json['percent_change']) ??
          _changePercentFromChange(
            change:
                parseDouble(json['change']) ??
                parseDouble(json['price_change']),
            previousClose:
                parseDouble(json['previous_close']) ??
                parseDouble(json['previousClose']),
          ),
      volume: _stringify(json['volume']),
      timestamp: _timestampFromJson(json),
    );
  }

  @override
  List<MarketQuote> parseQuoteCollection(Object? decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((entry) => parseQuote(Map<String, Object?>.from(entry)))
          .whereType<MarketQuote>()
          .toList(growable: false);
    }

    if (decoded is Map<String, Object?>) {
      final data = decoded['data'] ?? decoded['quotes'] ?? decoded['values'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((entry) => parseQuote(Map<String, Object?>.from(entry)))
            .whereType<MarketQuote>()
            .toList(growable: false);
      }

      final quote = parseQuote(decoded);
      if (quote != null) {
        return [quote];
      }
    }

    return const [];
  }

  @override
  List<MarketCandle> parseHistoricalCandles(Object? decoded) {
    final values = decoded is Map<String, Object?>
        ? (decoded['values'] ?? decoded['data'])
        : null;
    if (values is! List) {
      return const [];
    }
    return values
        .whereType<Map>()
        .map((entry) => Map<String, Object?>.from(entry))
        .map(_candleFromJson)
        .whereType<MarketCandle>()
        .toList(growable: false);
  }

  MarketCandle? _candleFromJson(Map<String, Object?> json) {
    final close = parseDouble(json['close']) ?? parseDouble(json['c']);
    final open = parseDouble(json['open']) ?? parseDouble(json['o']);
    final high = parseDouble(json['high']) ?? parseDouble(json['h']);
    final low = parseDouble(json['low']) ?? parseDouble(json['l']);
    if (close == null || open == null || high == null || low == null) {
      return null;
    }

    final timestamp =
        _dateTimeFromJson(json) ??
        DateTime.now().subtract(const Duration(days: 1));
    return MarketCandle(
      timestamp: timestamp,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: _stringify(json['volume']) ?? _stringify(json['v']),
    );
  }

  DateTime? _timestampFromJson(Map<String, Object?> json) {
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        rawTimestamp.toInt() * 1000,
        isUtc: true,
      );
    }
    return _dateTimeFromJson(json);
  }

  DateTime? _dateTimeFromJson(Map<String, Object?> json) {
    final rawDateTime = json['datetime'] ?? json['date'];
    if (rawDateTime is String) {
      return DateTime.tryParse(rawDateTime);
    }
    return null;
  }

  String? _stringify(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  double? _changePercentFromChange({
    required double? change,
    required double? previousClose,
  }) {
    if (change == null || previousClose == null || previousClose == 0) {
      return null;
    }
    return (change / previousClose) * 100;
  }

  @override
  AssetType? parseAssetType(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return switch (normalized) {
      'stock' || 'stocks' || 'common stock' => AssetType.stock,
      'etf' || 'etfs' => AssetType.etf,
      'cfd' || 'cfds' => AssetType.cfd,
      'option' || 'options' => AssetType.option,
      'crypto' || 'cryptocurrency' || 'digital currency' => AssetType.crypto,
      'bond' || 'bonds' => AssetType.bond,
      _ => null,
    };
  }

  @override
  double? parseDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  String? parseString(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }
}

class FinnhubMarketProviderAdapter implements MarketProviderAdapter {
  const FinnhubMarketProviderAdapter();

  @override
  String get providerName => 'finnhub';

  @override
  bool get supportsBatchQuotes => false;

  @override
  bool get supportsHistoricalCandles => true;

  @override
  String get quotePath => '/quote';

  @override
  String get batchQuotePath => '/quote';

  @override
  String get historicalCandlesPath => '/stock/candle';

  @override
  String get apiKeyQueryParameter => 'token';

  @override
  Map<String, String> quoteQueryParameters({
    required String symbol,
    required String apiKey,
  }) {
    return {'symbol': symbol, 'token': apiKey};
  }

  @override
  Map<String, String> batchQuoteQueryParameters({
    required List<String> symbols,
    required String apiKey,
  }) {
    return quoteQueryParameters(symbol: symbols.first, apiKey: apiKey);
  }

  @override
  Map<String, String> historicalCandlesQueryParameters({
    required String symbol,
    required String apiKey,
    required String interval,
    required int outputSize,
  }) {
    return {
      'symbol': symbol,
      'resolution': _resolutionFromInterval(interval),
      'count': outputSize.toString(),
      'token': apiKey,
    };
  }

  @override
  MarketQuote? parseQuote(Map<String, Object?> json) {
    final symbol = parseString(json['symbol']);
    final price = parseDouble(json['c']);
    if (symbol == null || price == null) {
      return null;
    }

    return MarketQuote(
      symbol: symbol,
      price: price,
      open: parseDouble(json['o']),
      high: parseDouble(json['h']),
      low: parseDouble(json['l']),
      close: price,
      change: parseDouble(json['d']),
      changePercent: parseDouble(json['dp']),
      timestamp: _timestampFromJson(json),
    );
  }

  @override
  List<MarketQuote> parseQuoteCollection(Object? decoded) {
    if (decoded is Map<String, Object?>) {
      final quote = parseQuote(decoded);
      if (quote != null) {
        return [quote];
      }
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((entry) => parseQuote(Map<String, Object?>.from(entry)))
          .whereType<MarketQuote>()
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<MarketCandle> parseHistoricalCandles(Object? decoded) {
    if (decoded is! Map<String, Object?>) {
      return const [];
    }
    final closes = _numericList(decoded['c']);
    final opens = _numericList(decoded['o']);
    final highs = _numericList(decoded['h']);
    final lows = _numericList(decoded['l']);
    final timestamps = _numericList(decoded['t']);
    if (closes.isEmpty ||
        opens.isEmpty ||
        highs.isEmpty ||
        lows.isEmpty ||
        timestamps.isEmpty) {
      return const [];
    }
    final length = [
      closes.length,
      opens.length,
      highs.length,
      lows.length,
      timestamps.length,
    ].reduce((a, b) => a < b ? a : b);
    final candles = <MarketCandle>[];
    for (var i = 0; i < length; i++) {
      candles.add(
        MarketCandle(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            timestamps[i].toInt() * 1000,
            isUtc: true,
          ),
          open: opens[i],
          high: highs[i],
          low: lows[i],
          close: closes[i],
        ),
      );
    }
    return candles;
  }

  String _resolutionFromInterval(String interval) {
    return switch (interval) {
      '1day' || '1d' => 'D',
      '1week' || '1w' => 'W',
      '1month' || '1m' => 'M',
      _ => 'D',
    };
  }

  DateTime? _timestampFromJson(Map<String, Object?> json) {
    final raw = json['t'];
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        raw.toInt() * 1000,
        isUtc: true,
      );
    }
    return null;
  }

  List<double> _numericList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((entry) => parseDouble(entry))
        .whereType<double>()
        .toList(growable: false);
  }

  @override
  AssetType? parseAssetType(Object? value) => null;

  @override
  double? parseDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  String? parseString(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }
}
