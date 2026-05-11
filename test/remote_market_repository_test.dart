import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/data/local_mock_market_repository.dart';
import 'package:trading_app/core/data/market_api_client.dart';
import 'package:trading_app/core/data/market_api_models.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/market_repository_factory.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/remote_market_repository.dart';

void main() {
  test('Local mock mode remains default', () {
    final repository = MarketRepositoryFactory.buildDefault();

    expect(repository, isA<LocalMockMarketRepository>());
    expect(repository.mode, MarketDataMode.demo);
  });

  test(
    'Remote repository maps successful API response into TradingAsset',
    () async {
      final repository = RemoteMarketRepository(
        apiClient: _FakeMarketApiClient(
          quoteResult: const AppSuccess([
            MarketQuote(
              symbol: 'AAPL',
              name: 'Apple Inc.',
              type: null,
              price: 250.5,
              open: 248.0,
              high: 251.0,
              low: 247.5,
              close: 250.5,
              change: 3.1,
              changePercent: 1.25,
              volume: '12M',
            ),
          ]),
        ),
      );

      final result = await repository.loadAssets();

      result.when(
        success: (assets) {
          expect(assets, hasLength(MockMarketData.assets.length));
          expect(assets.first.symbol, 'AAPL');
          expect(assets.first.price, 250.5);
          expect(assets.first.type.name, 'stock');
          expect(assets.first.trend.length, greaterThan(0));
        },
        failure: fail,
      );
    },
  );

  test('Remote repository returns failure on bad or missing config', () async {
    final repository = RemoteMarketRepository(
      apiClient: _FakeMarketApiClient(
        quoteResult: const AppFailure('Remote market data is not configured.'),
        fallbackResult: const AppFailure(
          'Remote market data is not configured.',
        ),
      ),
    );

    final result = await repository.loadAssets();

    result.when(
      success: (_) => fail('Expected remote failure'),
      failure: (message) {
        expect(message, contains('not configured'));
      },
    );
  });
}

class _FakeMarketApiClient extends MarketApiClient {
  _FakeMarketApiClient({this.quoteResult, this.fallbackResult});

  final AppResult<List<MarketQuote>>? quoteResult;
  final AppResult<List<Map<String, Object?>>>? fallbackResult;

  @override
  Future<AppResult<MarketQuote>> fetchQuote(String symbol) async {
    final quotes = quoteResult;
    return quotes == null
        ? const AppFailure('Quote fetch unavailable')
        : quotes.when(
            success: (data) => data.isEmpty
                ? const AppFailure('No quote data')
                : AppSuccess(data.first),
            failure: AppFailure.new,
          );
  }

  @override
  Future<AppResult<List<MarketQuote>>> fetchQuotes(List<String> symbols) async {
    return quoteResult ?? const AppFailure('Quote fetch unavailable');
  }

  @override
  Future<AppResult<List<Map<String, Object?>>>> fetchAssets() async {
    return fallbackResult ?? const AppFailure('Fallback fetch unavailable');
  }
}
