import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/data/local_mock_market_repository.dart';
import 'package:trading_app/core/data/market_api_client.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/market_repository_factory.dart';
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
          result: const AppSuccess([
            {
              'symbol': 'AAPL',
              'name': 'Apple Inc.',
              'type': 'stock',
              'price': 250.5,
              'dailyChangePercent': 1.25,
              'open': 248.0,
              'high': 251.0,
              'low': 247.5,
              'volume': '12M',
              'marketCap': r'$3.5T',
              'trend': [248.0, 249.5, 250.5],
            },
          ]),
        ),
      );

      final result = await repository.loadAssets();

      result.when(
        success: (assets) {
          expect(assets.single.symbol, 'AAPL');
          expect(assets.single.price, 250.5);
          expect(assets.single.type.name, 'stock');
          expect(assets.single.trend.length, 3);
        },
        failure: fail,
      );
    },
  );

  test('Remote repository returns failure on bad or missing config', () async {
    final repository = RemoteMarketRepository(
      apiClient: _FakeMarketApiClient(
        result: const AppFailure('Remote market data is not configured.'),
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

class _FakeMarketApiClient implements MarketApiClient {
  const _FakeMarketApiClient({required this.result});

  final AppResult<List<Map<String, Object?>>> result;

  @override
  Future<AppResult<List<Map<String, Object?>>>> fetchAssets() async => result;
}
