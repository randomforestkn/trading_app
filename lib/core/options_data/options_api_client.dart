import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'options_chain_models.dart';
import 'options_provider_config.dart';
import '../strategies/option_contract.dart';

abstract class OptionsApiClient {
  OptionsProviderConfig get config;

  Future<AppResult<List<DateTime>>> fetchExpirations(String symbol);

  Future<AppResult<OptionChain>> fetchChain(
    String symbol,
    DateTime expirationDate,
  );

  Future<AppResult<OptionQuote>> fetchQuote(
    String symbol,
    DateTime expirationDate,
    double strike,
    OptionType optionType,
  );
}

class HttpOptionsApiClient implements OptionsApiClient {
  HttpOptionsApiClient({required this.providerConfig, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final OptionsProviderConfig providerConfig;
  final http.Client _httpClient;

  @override
  OptionsProviderConfig get config => providerConfig;

  @override
  Future<AppResult<List<DateTime>>> fetchExpirations(String symbol) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote options data is not configured. Provide OPTIONS_BASE_URL and OPTIONS_API_KEY.',
      );
    }

    final result = await _getJson(
      _buildUri(path: '/options/expirations', symbol: symbol),
    );
    return result.when(
      success: (payload) {
        final expirations = _parseExpirations(payload);
        if (expirations.isEmpty) {
          return const AppFailure(
            'Options API response did not include expirations.',
          );
        }
        return AppSuccess(expirations);
      },
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<OptionChain>> fetchChain(
    String symbol,
    DateTime expirationDate,
  ) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote options data is not configured. Provide OPTIONS_BASE_URL and OPTIONS_API_KEY.',
      );
    }

    final result = await _getJson(
      _buildUri(
        path: '/options/chain',
        symbol: symbol,
        expirationDate: expirationDate,
      ),
    );
    return result.when(
      success: (payload) {
        final chain = _parseChain(symbol, expirationDate, payload);
        if (chain == null || chain.quotes.isEmpty) {
          return const AppFailure(
            'Options API response did not include chain data.',
          );
        }
        return AppSuccess(chain);
      },
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<OptionQuote>> fetchQuote(
    String symbol,
    DateTime expirationDate,
    double strike,
    OptionType optionType,
  ) async {
    final result = await fetchChain(symbol, expirationDate);
    return result.when(
      success: (chain) {
        final quote = chain.quoteFor(type: optionType, strike: strike);
        return quote == null
            ? const AppFailure('Quote not found in options chain.')
            : AppSuccess(quote);
      },
      failure: AppFailure.new,
    );
  }

  Uri _buildUri({
    required String path,
    required String symbol,
    DateTime? expirationDate,
  }) {
    final base = Uri.parse(providerConfig.baseUrl.trim());
    final queryParameters = <String, String>{
      'symbol': symbol,
      if (expirationDate != null)
        'expiration': expirationDate.toIso8601String().split('T').first,
    };
    return base.resolveUri(Uri(path: path, queryParameters: queryParameters));
  }

  Future<AppResult<Map<String, Object?>>> _getJson(Uri uri) async {
    try {
      final response = await _httpClient.get(uri, headers: _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AppFailure(
          'Options API request failed with status ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      final payload = _normalizeMap(decoded);
      if (payload == null) {
        return const AppFailure(
          'Options API response did not include an object.',
        );
      }
      return AppSuccess(payload);
    } on FormatException {
      return const AppFailure('Options API returned invalid JSON.');
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Options API request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Options API request failed.');
    }
  }

  Map<String, String> _headers() {
    return {
      'x-options-provider': providerConfig.providerLabel,
      if (providerConfig.hasApiKey) 'x-api-key': providerConfig.apiKey,
      'x-options-delayed': providerConfig.delayedMarketData.toString(),
    };
  }

  List<DateTime> _parseExpirations(Map<String, Object?> payload) {
    final source = _firstList(payload, ['expirations', 'data', 'dates']);
    return source
        .map((item) => _parseDateTime(item))
        .whereType<DateTime>()
        .toList(growable: false);
  }

  OptionChain? _parseChain(
    String symbol,
    DateTime expirationDate,
    Map<String, Object?> payload,
  ) {
    final quotesSource = _firstList(payload, ['quotes', 'chain', 'data']);
    final quotes = quotesSource
        .whereType<Map>()
        .map(
          (item) => OptionQuote.fromJson(
            Map<String, Object?>.from(item.cast<String, dynamic>()),
          ),
        )
        .toList(growable: false);
    if (quotes.isEmpty) {
      return null;
    }
    return OptionChain(
      underlyingSymbol: symbol,
      expirationDate: expirationDate,
      quotes: quotes,
      updatedAt:
          _parseDateTime(_readString(payload, ['updatedAt'])) ?? DateTime.now(),
    );
  }

  List<Object?> _firstList(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is List) {
        return value;
      }
    }
    return const [];
  }

  String? _readString(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, Object?>? _normalizeMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    return null;
  }
}
