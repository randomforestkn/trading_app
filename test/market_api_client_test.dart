import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trading_app/core/data/market_api_client.dart';
import 'package:trading_app/core/data/market_provider_config.dart';

void main() {
  test('TwelveData price endpoint URL is built correctly', () async {
    Uri? capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response('{"price":"123.45"}', 200);
    });
    final apiClient = HttpMarketApiClient(
      providerConfig: MarketProviderConfig.fromValues(
        provider: 'twelvedata',
        useRemoteMarketData: true,
        baseUrl: 'https://api.twelvedata.com',
        apiKey: 'secret-api-key',
      ),
      httpClient: client,
    );

    final result = await apiClient.fetchQuote('AAPL');

    expect(
      capturedUri.toString(),
      'https://api.twelvedata.com/price?symbol=AAPL&apikey=secret-api-key',
    );
    result.when(
      success: (quote) {
        expect(quote.symbol, 'AAPL');
        expect(quote.price, 123.45);
      },
      failure: fail,
    );
  });

  test('API key is not included in surfaced or logged errors', () async {
    final capturedLogs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        capturedLogs.add(message);
      }
    };

    try {
      final client = MockClient((request) async {
        return http.Response(
          '{"status":"error","code":400,"message":"Invalid API key secret-api-key"}',
          200,
        );
      });
      final apiClient = HttpMarketApiClient(
        providerConfig: MarketProviderConfig.fromValues(
          provider: 'twelvedata',
          useRemoteMarketData: true,
          baseUrl: 'https://api.twelvedata.com',
          apiKey: 'secret-api-key',
        ),
        httpClient: client,
      );

      final result = await apiClient.fetchQuote('AAPL');

      result.when(
        success: (_) => fail('Expected remote failure'),
        failure: (message) {
          expect(message, isNot(contains('secret-api-key')));
          expect(message, contains('Invalid API key'));
        },
      );
    } finally {
      debugPrint = previousDebugPrint;
    }

    final joinedLogs = capturedLogs.join('\n');
    expect(joinedLogs, isNot(contains('secret-api-key')));
    expect(joinedLogs, contains('provider=Twelve Data'));
    expect(joinedLogs, contains('/price'));
  });

  test('network failures redact apikey query parameter in logs', () async {
    final capturedLogs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        capturedLogs.add(message);
      }
    };

    try {
      final client = MockClient((request) async {
        throw http.ClientException('Connection failed', request.url);
      });
      final apiClient = HttpMarketApiClient(
        providerConfig: MarketProviderConfig.fromValues(
          provider: 'twelvedata',
          useRemoteMarketData: true,
          baseUrl: 'https://api.twelvedata.com',
          apiKey: 'secret-api-key',
        ),
        httpClient: client,
      );

      final result = await apiClient.fetchQuote('AAPL');

      result.when(
        success: (_) => fail('Expected remote failure'),
        failure: (message) {
          expect(message, isNot(contains('secret-api-key')));
        },
      );
    } finally {
      debugPrint = previousDebugPrint;
    }

    final joinedLogs = capturedLogs.join('\n');
    expect(joinedLogs, isNot(contains('secret-api-key')));
    expect(joinedLogs, contains('network_error'));
    expect(joinedLogs, contains('apikey=REDACTED'));
    expect(joinedLogs, isNot(contains('apikey=secret-api-key')));
  });
}
