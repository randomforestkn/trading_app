import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_result.dart';

abstract class MarketApiClient {
  Future<AppResult<List<Map<String, Object?>>>> fetchAssets();
}

class HttpMarketApiClient implements MarketApiClient {
  HttpMarketApiClient({
    required this.baseUrl,
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _httpClient;

  @override
  Future<AppResult<List<Map<String, Object?>>>> fetchAssets() async {
    if (baseUrl.trim().isEmpty || apiKey.trim().isEmpty) {
      return const AppFailure(
        'Remote market data is not configured. Provide MARKET_API_BASE_URL and MARKET_API_KEY.',
      );
    }

    try {
      final response = await _httpClient.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AppFailure(
          'Market API request failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      final rawAssets = decoded is Map<String, Object?>
          ? decoded['assets']
          : decoded;
      if (rawAssets is! List) {
        return const AppFailure('Market API response did not include assets.');
      }

      return AppSuccess(
        rawAssets
            .whereType<Map>()
            .map((asset) => Map<String, Object?>.from(asset))
            .toList(growable: false),
      );
    } on FormatException {
      return const AppFailure('Market API returned invalid JSON.');
    } catch (_) {
      return const AppFailure('Market API request failed.');
    }
  }
}
