import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/data/local_mock_market_repository.dart';
import 'package:trading_app/core/data/market_api_client.dart';
import 'package:trading_app/core/data/market_api_models.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/data/market_repository_factory.dart';
import 'package:trading_app/core/data/mock_market_data.dart';
import 'package:trading_app/core/data/market_state.dart';
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

  test(
    'Remote repository fetchAssets returns updated TradingAsset list using fake price response',
    () async {
      final repository = RemoteMarketRepository(
        apiClient: _SequentialMarketApiClient(
          quotesBySymbol: {
            'AAPL': const AppSuccess(
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
            ),
          },
        ),
      );

      final result = await repository.fetchAssets();

      result.when(
        success: (assets) {
          expect(assets, hasLength(MockMarketData.assets.length));
          final aapl = assets.firstWhere((asset) => asset.symbol == 'AAPL');
          expect(aapl.price, 250.5);
          expect(aapl.name, 'Apple Inc.');
          expect(aapl.type.name, 'stock');
          expect(aapl.marketCap, '\$3.2T');
          expect(aapl.volume, '12M');
          final voo = assets.firstWhere((asset) => asset.symbol == 'VOO');
          expect(voo.name, 'Vanguard S&P 500 ETF');
          expect(voo.marketCap, '\$1.5T');
        },
        failure: fail,
      );
    },
  );

  test(
    'TwelveData symbols map correctly and unsupported mock symbols are skipped',
    () async {
      final client = _RecordingMarketApiClient(
        quotesBySymbol: {
          'AAPL': const AppSuccess(
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
          ),
          'VOO': const AppSuccess(
            MarketQuote(
              symbol: 'VOO',
              name: 'Vanguard S&P 500 ETF',
              type: null,
              price: 510.0,
              open: 508.0,
              high: 511.0,
              low: 507.5,
              close: 510.0,
              change: 1.3,
              changePercent: 0.26,
              volume: '7M',
            ),
          ),
          'BTC/USD': const AppSuccess(
            MarketQuote(
              symbol: 'BTC/USD',
              name: 'Bitcoin',
              type: null,
              price: 69000,
              open: 68000,
              high: 69500,
              low: 67900,
              close: 69000,
              change: 760,
              changePercent: 1.11,
              volume: '43B',
            ),
          ),
          'ETH/USD': const AppSuccess(
            MarketQuote(
              symbol: 'ETH/USD',
              name: 'Ethereum',
              type: null,
              price: 3600,
              open: 3520,
              high: 3610,
              low: 3510,
              close: 3600,
              change: 88,
              changePercent: 2.5,
              volume: '19B',
            ),
          ),
        },
      );
      final repository = RemoteMarketRepository(apiClient: client);

      final result = await repository.loadAssets();

      result.when(
        success: (assets) {
          expect(
            client.requestedSymbols,
            containsAll(['AAPL', 'VOO', 'BTC/USD', 'ETH/USD']),
          );
          expect(client.requestedSymbols, isNot(contains('US500')));
          expect(client.requestedSymbols, isNot(contains('AAPL C230')));
          expect(client.requestedSymbols, isNot(contains('T 4.5 2034')));
          expect(
            assets.firstWhere((asset) => asset.symbol == 'BTC').price,
            69000,
          );
          expect(
            assets.firstWhere((asset) => asset.symbol == 'ETH').price,
            3600,
          );
          expect(
            assets.firstWhere((asset) => asset.symbol == 'BTC').symbol,
            'BTC',
          );
          expect(
            assets.firstWhere((asset) => asset.symbol == 'ETH').symbol,
            'ETH',
          );
        },
        failure: fail,
      );
    },
  );

  test('refreshPrices updates at least one asset in remote mode', () async {
    final client = _SequentialMarketApiClient(
      quotesBySymbol: {
        'AAPL': const AppSuccess(
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
        ),
      },
      refreshQuotesBySymbol: {
        'AAPL': const AppSuccess(
          MarketQuote(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            type: null,
            price: 255.0,
            open: 249.0,
            high: 256.0,
            low: 248.5,
            close: 255.0,
            change: 4.5,
            changePercent: 1.8,
            volume: '13M',
          ),
        ),
      },
    );
    final repository = RemoteMarketRepository(apiClient: client);
    final marketState = MarketState(repository: repository);

    await marketState.loadAssets();
    final before = marketState.assetBySymbol('AAPL').price;

    await marketState.refreshPrices();

    expect(marketState.assetBySymbol('AAPL').price, isNot(before));
    expect(marketState.errorMessage, isNull);
  });

  test(
    'partial quote failure still returns successful updated assets',
    () async {
      final repository = RemoteMarketRepository(
        apiClient: _SequentialMarketApiClient(
          quotesBySymbol: {
            'AAPL': const AppSuccess(
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
            ),
            'VOO': const AppFailure('Timeout'),
            'US500': const AppFailure('Timeout'),
            'AAPL C230': const AppFailure('Timeout'),
            'BTC': const AppFailure('Timeout'),
            'T 4.5 2034': const AppFailure('Timeout'),
            'ETH': const AppFailure('Timeout'),
          },
        ),
      );

      final result = await repository.loadAssets();

      result.when(
        success: (assets) {
          expect(assets, hasLength(MockMarketData.assets.length));
          expect(
            assets.firstWhere((asset) => asset.symbol == 'AAPL').price,
            250.5,
          );
          expect(
            assets.firstWhere((asset) => asset.symbol == 'VOO').price,
            MockMarketData.assets
                .firstWhere((asset) => asset.symbol == 'VOO')
                .price,
          );
        },
        failure: fail,
      );
    },
  );

  test('all quote failures return AppFailure safely', () async {
    final repository = RemoteMarketRepository(
      apiClient: _SequentialMarketApiClient(
        quotesBySymbol: {
          for (final asset in MockMarketData.assets)
            asset.symbol: const AppFailure('Network failure'),
        },
      ),
    );

    final result = await repository.loadAssets();

    result.when(
      success: (_) => fail('Expected remote failure'),
      failure: (message) {
        expect(message, contains('failed'));
      },
    );
  });

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
        expect(message, contains('failed'));
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

class _SequentialMarketApiClient extends MarketApiClient {
  _SequentialMarketApiClient({
    required this.quotesBySymbol,
    this.refreshQuotesBySymbol,
  });

  final Map<String, AppResult<MarketQuote>> quotesBySymbol;
  final Map<String, AppResult<MarketQuote>>? refreshQuotesBySymbol;
  final Map<String, int> _callCountBySymbol = {};

  @override
  Future<AppResult<MarketQuote>> fetchQuote(String symbol) async {
    final callCount = _callCountBySymbol[symbol] ?? 0;
    _callCountBySymbol[symbol] = callCount + 1;
    final source = callCount == 0 ? quotesBySymbol : refreshQuotesBySymbol;
    final result = source?[symbol] ?? quotesBySymbol[symbol];
    return result ?? const AppFailure('Quote fetch unavailable');
  }

  @override
  Future<AppResult<List<Map<String, Object?>>>> fetchAssets() async {
    return const AppFailure('Fallback fetch unavailable');
  }
}

class _RecordingMarketApiClient extends MarketApiClient {
  _RecordingMarketApiClient({required this.quotesBySymbol});

  final Map<String, AppResult<MarketQuote>> quotesBySymbol;
  final List<String> requestedSymbols = [];

  @override
  Future<AppResult<MarketQuote>> fetchQuote(String symbol) async {
    requestedSymbols.add(symbol);
    return quotesBySymbol[symbol] ??
        const AppFailure('Quote fetch unavailable');
  }

  @override
  Future<AppResult<List<Map<String, Object?>>>> fetchAssets() async {
    return const AppFailure('Fallback fetch unavailable');
  }
}
