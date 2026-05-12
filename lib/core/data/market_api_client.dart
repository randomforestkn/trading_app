import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_result.dart';
import 'market_api_models.dart';
import 'market_provider_adapter.dart';
import 'market_provider_config.dart';
import '../utils/app_logger.dart';

abstract class MarketApiClient {
  MarketProviderConfig get config => MarketProviderConfig.current;

  Future<AppResult<MarketQuote>> fetchQuote(String symbol) async {
    return const AppFailure('Quote fetch is not implemented.');
  }

  Future<AppResult<List<MarketQuote>>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) {
      return const AppSuccess(<MarketQuote>[]);
    }

    final quotes = <MarketQuote>[];
    for (final symbol in symbols) {
      final result = await fetchQuote(symbol);
      final quote = result.when(success: (data) => data, failure: (_) => null);
      if (quote != null) {
        quotes.add(quote);
      }
    }

    if (quotes.isEmpty) {
      return const AppFailure('Batch quote fetch is not implemented.');
    }
    return AppSuccess(quotes);
  }

  Future<AppResult<List<MarketCandle>>> fetchHistoricalCandles(
    String symbol, {
    String interval = '1day',
    int outputSize = 30,
  }) async {
    return const AppFailure('Historical candle fetch is not implemented.');
  }

  Future<AppResult<List<Map<String, Object?>>>> fetchAssets();
}

class HttpMarketApiClient implements MarketApiClient {
  HttpMarketApiClient({required this.providerConfig, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final MarketProviderConfig providerConfig;
  final http.Client _httpClient;

  @override
  MarketProviderConfig get config => providerConfig;

  MarketProviderAdapter get _adapter => switch (providerConfig.provider) {
    MarketProvider.twelvedata => const TwelveDataMarketProviderAdapter(),
    MarketProvider.finnhub => const FinnhubMarketProviderAdapter(),
  };

  @override
  Future<AppResult<MarketQuote>> fetchQuote(String symbol) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote market data is not configured. Provide MARKET_API_BASE_URL and MARKET_API_KEY.',
      );
    }
    final uri = _buildUri(
      path: _adapter.quotePath,
      queryParameters: _adapter.quoteQueryParameters(
        symbol: symbol,
        apiKey: providerConfig.apiKey,
      ),
    );
    final result = await _getJson(
      uri,
      symbol: symbol,
      endpointPath: _adapter.quotePath,
    );
    return result.when(
      success: (decoded) {
        final payload = decoded is Map<String, Object?>
            ? decoded
            : decoded is List && decoded.isNotEmpty && decoded.first is Map
            ? Map<String, Object?>.from(decoded.first as Map)
            : null;
        final errorMessage = _providerErrorMessage(payload);
        if (errorMessage != null) {
          _logFailure(
            uri: uri,
            endpointPath: _adapter.quotePath,
            symbol: symbol,
            statusCode: 200,
            responseBody: _sanitizedBody(jsonEncode(payload)),
            category: 'provider_error',
            message: errorMessage,
          );
          return AppFailure(errorMessage);
        }
        final quote = payload == null
            ? null
            : _adapter.parseQuote(payload) ??
                  _quoteFromMinimalPayload(payload, requestedSymbol: symbol);
        if (quote == null) {
          return const AppFailure(
            'Market API response did not include quote data.',
          );
        }
        return AppSuccess(quote);
      },
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<List<MarketQuote>>> fetchQuotes(List<String> symbols) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote market data is not configured. Provide MARKET_API_BASE_URL and MARKET_API_KEY.',
      );
    }
    if (symbols.isEmpty) {
      return const AppSuccess(<MarketQuote>[]);
    }

    if (_adapter.supportsBatchQuotes && symbols.length > 1) {
      final batchResult = await _getJson(
        _buildUri(
          path: _adapter.batchQuotePath,
          queryParameters: _adapter.batchQuoteQueryParameters(
            symbols: symbols,
            apiKey: providerConfig.apiKey,
          ),
        ),
        endpointPath: _adapter.batchQuotePath,
        symbol: symbols.first,
      );
      final parsedBatch = batchResult.when(
        success: (decoded) => _adapter.parseQuoteCollection(decoded),
        failure: (_) => const <MarketQuote>[],
      );
      final parsedSymbols = parsedBatch.map((quote) => quote.symbol).toSet();
      final missing = symbols.where(
        (symbol) => !parsedSymbols.contains(symbol),
      );
      if (parsedBatch.isNotEmpty && missing.isEmpty) {
        return AppSuccess(parsedBatch);
      }
      final fallback = await _fetchQuotesIndividually(symbols);
      return fallback;
    }

    return _fetchQuotesIndividually(symbols);
  }

  Future<AppResult<List<MarketQuote>>> _fetchQuotesIndividually(
    List<String> symbols,
  ) async {
    final quotes = <MarketQuote>[];
    for (final symbol in symbols) {
      final result = await fetchQuote(symbol);
      final quote = result.when(success: (data) => data, failure: (_) => null);
      if (quote != null) {
        quotes.add(quote);
      }
    }
    if (quotes.isEmpty) {
      return const AppFailure('Market API response did not include quotes.');
    }
    return AppSuccess(quotes);
  }

  @override
  Future<AppResult<List<MarketCandle>>> fetchHistoricalCandles(
    String symbol, {
    String interval = '1day',
    int outputSize = 30,
  }) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote market data is not configured. Provide MARKET_API_BASE_URL and MARKET_API_KEY.',
      );
    }
    if (!_adapter.supportsHistoricalCandles) {
      return const AppFailure(
        'Historical candles are not supported by this market provider.',
      );
    }

    final uri = _buildUri(
      path: _adapter.historicalCandlesPath,
      queryParameters: _adapter.historicalCandlesQueryParameters(
        symbol: symbol,
        apiKey: providerConfig.apiKey,
        interval: interval,
        outputSize: outputSize,
      ),
    );
    final result = await _getJson(
      uri,
      symbol: symbol,
      endpointPath: _adapter.historicalCandlesPath,
    );
    return result.when(
      success: (decoded) {
        final candles = _adapter.parseHistoricalCandles(decoded);
        if (candles.isEmpty) {
          return const AppFailure(
            'Market API response did not include candles.',
          );
        }
        return AppSuccess(candles);
      },
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<List<Map<String, Object?>>>> fetchAssets() async {
    return const AppFailure(
      'Fetch assets is not supported directly by the remote provider. Use fetchQuotes().',
    );
  }

  Uri _buildUri({
    required String path,
    required Map<String, String> queryParameters,
  }) {
    final base = Uri.parse(providerConfig.baseUrl.trim());
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return base.resolveUri(
      Uri(path: normalizedPath, queryParameters: queryParameters),
    );
  }

  Future<AppResult<Object?>> _getJson(
    Uri uri, {
    required String endpointPath,
    String? symbol,
  }) async {
    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logFailure(
          uri: uri,
          endpointPath: endpointPath,
          symbol: symbol,
          statusCode: response.statusCode,
          responseBody: _sanitizedBody(response.body),
          category: 'http_error',
          message:
              'Market API request failed with status ${response.statusCode}.',
        );
        return AppFailure(
          'Market API request failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      return AppSuccess(decoded);
    } on FormatException {
      _logFailure(
        uri: uri,
        endpointPath: endpointPath,
        symbol: symbol,
        statusCode: null,
        responseBody: null,
        category: 'format_error',
        message: 'Market API returned invalid JSON.',
      );
      return const AppFailure('Market API returned invalid JSON.');
    } catch (error) {
      final safeError = _sanitizeSensitiveData(error.toString());
      _logFailure(
        uri: uri,
        endpointPath: endpointPath,
        symbol: symbol,
        statusCode: null,
        responseBody: null,
        category: 'network_error',
        message: 'Market API request failed.',
        error: safeError,
      );
      return const AppFailure('Market API request failed.');
    }
  }

  MarketQuote? _quoteFromMinimalPayload(
    Map<String, Object?> payload, {
    required String requestedSymbol,
  }) {
    if (providerConfig.provider != MarketProvider.twelvedata) {
      return null;
    }

    final price =
        _doubleValue(payload['price']) ??
        _doubleValue(payload['close']) ??
        _doubleValue(payload['last']) ??
        _doubleValue(payload['c']);
    if (price == null) {
      return null;
    }

    final previousClose =
        _doubleValue(payload['previous_close']) ??
        _doubleValue(payload['previousClose']);
    final change =
        _doubleValue(payload['change']) ??
        _doubleValue(payload['price_change']) ??
        _derivedChange(price, previousClose);
    final changePercent =
        _doubleValue(payload['percent_change']) ??
        _derivedChangePercent(change, previousClose);

    return MarketQuote(
      symbol: requestedSymbol,
      name: _stringValue(payload['name']),
      type: _adapter.parseAssetType(payload['type']),
      price: price,
      open: _doubleValue(payload['open']) ?? _doubleValue(payload['o']),
      high: _doubleValue(payload['high']) ?? _doubleValue(payload['h']),
      low: _doubleValue(payload['low']) ?? _doubleValue(payload['l']),
      close: price,
      change: change,
      changePercent: changePercent,
      volume: _stringValue(payload['volume']),
      timestamp: _timestampFromJson(payload),
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

    final rawDateTime = json['datetime'] ?? json['date'];
    if (rawDateTime is String) {
      return DateTime.tryParse(rawDateTime);
    }
    return null;
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

  String? _providerErrorMessage(Map<String, Object?>? payload) {
    if (payload == null) {
      return null;
    }

    final status = payload['status']?.toString().toLowerCase();
    final code = payload['code'];
    final message = payload['message']?.toString().trim();
    if (status == 'error' || (code is num && code >= 400)) {
      return message?.isNotEmpty == true
          ? _sanitizeSensitiveData(message!)
          : 'Market API returned an error response.';
    }
    return null;
  }

  void _logFailure({
    required Uri uri,
    required String endpointPath,
    required String? symbol,
    required int? statusCode,
    required String? responseBody,
    required String category,
    required String message,
    Object? error,
  }) {
    AppLogger.warn(
      'Market API failure category=$category '
      'provider=${providerConfig.provider.label} '
      'path=$endpointPath symbol=${symbol ?? 'n/a'} '
      'status=${statusCode ?? 'n/a'} url=${_sanitizeUri(uri)}',
      error: responseBody ?? error ?? message,
    );
  }

  String _sanitizeUri(Uri uri) {
    final apiKeyQueryParameter = _adapter.apiKeyQueryParameter.toLowerCase();
    final sanitized = Map<String, String>.from(uri.queryParameters)
      ..removeWhere(
        (key, value) =>
            key.toLowerCase() == apiKeyQueryParameter ||
            key.toLowerCase().contains('key') ||
            key.toLowerCase() == 'token' ||
            key.toLowerCase() == 'access_token' ||
            key.toLowerCase() == 'authorization' ||
            key.toLowerCase() == 'apikey',
      );
    return _sanitizeSensitiveData(
      uri
          .replace(queryParameters: sanitized.isEmpty ? null : sanitized)
          .toString(),
    );
  }

  String _sanitizedBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return '<empty body>';
    }
    final redacted = _sanitizeSensitiveData(trimmed);
    if (redacted.length <= 300) {
      return redacted;
    }
    return '${redacted.substring(0, 300)}…';
  }

  String _sanitizeSensitiveData(String input) {
    var sanitized = AppLogger.sanitizeText(input);
    final apiKey = providerConfig.apiKey.trim();
    if (apiKey.isNotEmpty) {
      sanitized = sanitized.replaceAll(apiKey, 'REDACTED');
    }
    return sanitized;
  }
}
