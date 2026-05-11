import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_result.dart';
import 'market_api_models.dart';
import 'market_provider_adapter.dart';
import 'market_provider_config.dart';

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
    final result = await _getJson(
      _buildUri(
        path: _adapter.quotePath,
        queryParameters: _adapter.quoteQueryParameters(
          symbol: symbol,
          apiKey: providerConfig.apiKey,
        ),
      ),
    );
    return result.when(
      success: (decoded) {
        final payload = decoded is Map<String, Object?>
            ? decoded
            : decoded is List && decoded.isNotEmpty && decoded.first is Map
            ? Map<String, Object?>.from(decoded.first as Map)
            : null;
        final quote = payload == null ? null : _adapter.parseQuote(payload);
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

    final result = await _getJson(
      _buildUri(
        path: _adapter.historicalCandlesPath,
        queryParameters: _adapter.historicalCandlesQueryParameters(
          symbol: symbol,
          apiKey: providerConfig.apiKey,
          interval: interval,
          outputSize: outputSize,
        ),
      ),
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
    return base.resolveUri(Uri(path: path, queryParameters: queryParameters));
  }

  Future<AppResult<Object?>> _getJson(Uri uri) async {
    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AppFailure(
          'Market API request failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      return AppSuccess(decoded);
    } on FormatException {
      return const AppFailure('Market API returned invalid JSON.');
    } catch (_) {
      return const AppFailure('Market API request failed.');
    }
  }
}
