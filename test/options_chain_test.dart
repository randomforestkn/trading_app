import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/options_data/local_manual_options_repository.dart';
import 'package:trading_app/core/options_data/options_api_client.dart';
import 'package:trading_app/core/options_data/options_chain_models.dart';
import 'package:trading_app/core/options_data/options_chain_repository.dart';
import 'package:trading_app/core/options_data/options_chain_repository_factory.dart';
import 'package:trading_app/core/options_data/options_chain_state.dart';
import 'package:trading_app/core/options_data/options_provider_config.dart';
import 'package:trading_app/core/options_data/remote_options_chain_repository.dart';
import 'package:trading_app/core/strategies/option_contract.dart';

void main() {
  test('OptionsProviderConfig defaults to manual mode', () {
    expect(OptionsProviderConfig.current.provider, OptionsProvider.custom);
    expect(OptionsProviderConfig.current.isRemoteEnabled, isFalse);
    expect(OptionsProviderConfig.current.dataModeLabel, 'Manual options input');
  });

  test('OptionsProviderConfig parses remote configuration safely', () {
    final config = OptionsProviderConfig.fromValues(
      provider: 'polygon',
      useRemoteOptionsData: true,
      baseUrl: 'https://example.com/api',
      apiKey: 'secret',
      delayedMarketData: true,
    );

    expect(config.provider, OptionsProvider.polygon);
    expect(config.isRemoteEnabled, isTrue);
    expect(config.safeConfigSummary, contains('example.com'));
  });

  test(
    'Options repository factory falls back to manual input without config',
    () {
      final repo = OptionsChainRepositoryFactory.build(
        useRemote: true,
        baseUrl: '',
        apiKey: '',
        delayedMarketData: true,
      );

      expect(repo, isA<LocalManualOptionsRepository>());
    },
  );

  test('Remote options repository maps chain data successfully', () async {
    final apiClient = _FakeOptionsApiClient(
      config: OptionsProviderConfig.fromValues(
        provider: 'tradier',
        useRemoteOptionsData: true,
        baseUrl: 'https://api.tradier.com',
        apiKey: 'secret',
        delayedMarketData: true,
      ),
    );
    final repository = RemoteOptionsChainRepository(apiClient: apiClient);

    final expirations = await repository.fetchExpirations('AAPL');
    expect(
      expirations.when(success: (data) => data.length, failure: (_) => 0),
      2,
    );

    final chain = await repository.fetchChain('AAPL', DateTime(2026, 2, 1));
    final parsed = chain.when(
      success: (data) => data,
      failure: (message) => throw StateError(message),
    );

    expect(parsed.underlyingSymbol, 'AAPL');
    expect(parsed.quotes, isNotEmpty);
    expect(parsed.quoteFor(type: OptionType.call, strike: 100), isNotNull);
  });

  test(
    'Remote options repository returns failure on malformed response',
    () async {
      final apiClient = _FakeOptionsApiClient(
        config: OptionsProviderConfig.fromValues(
          provider: 'tradier',
          useRemoteOptionsData: true,
          baseUrl: 'https://api.tradier.com',
          apiKey: 'secret',
          delayedMarketData: true,
        ),
        malformedChain: true,
      );
      final repository = RemoteOptionsChainRepository(apiClient: apiClient);

      final result = await repository.fetchChain('AAPL', DateTime(2026, 2, 1));

      expect(result is AppFailure<OptionChain>, isTrue);
    },
  );

  test('OptionsChainState handles remote failures safely', () async {
    final state = OptionsChainState(repository: _FailingOptionsRepository());
    await state.setUnderlying('AAPL');
    await state.refreshExpirations();

    expect(state.errorMessage, isNotNull);
    expect(state.hasRemoteData, isFalse);
  });
}

class _FakeOptionsApiClient implements OptionsApiClient {
  _FakeOptionsApiClient({required this.config, this.malformedChain = false});

  @override
  final OptionsProviderConfig config;
  final bool malformedChain;

  @override
  Future<AppResult<List<DateTime>>> fetchExpirations(String symbol) async {
    return AppSuccess([DateTime(2026, 2, 1), DateTime(2026, 3, 1)]);
  }

  @override
  Future<AppResult<OptionChain>> fetchChain(
    String symbol,
    DateTime expirationDate,
  ) async {
    if (malformedChain) {
      return const AppFailure('Malformed chain response.');
    }
    return AppSuccess(
      OptionChain(
        underlyingSymbol: symbol,
        expirationDate: expirationDate,
        updatedAt: DateTime(2026, 1, 1),
        quotes: [
          OptionQuote(
            underlyingSymbol: symbol,
            expirationDate: expirationDate,
            strike: 100,
            optionType: OptionType.call,
            updatedAt: DateTime(2026, 1, 1),
            bid: 2.1,
            ask: 2.3,
            last: 2.2,
            mark: 2.2,
            volume: 250,
            openInterest: 1200,
            impliedVolatility: 22,
            inTheMoney: false,
          ),
        ],
      ),
    );
  }

  @override
  Future<AppResult<OptionQuote>> fetchQuote(
    String symbol,
    DateTime expirationDate,
    double strike,
    OptionType optionType,
  ) async {
    return AppSuccess(
      OptionQuote(
        underlyingSymbol: symbol,
        expirationDate: expirationDate,
        strike: strike,
        optionType: optionType,
        updatedAt: DateTime(2026, 1, 1),
        bid: 2.1,
        ask: 2.3,
        last: 2.2,
        mark: 2.2,
        volume: 250,
        openInterest: 1200,
        impliedVolatility: 22,
        inTheMoney: false,
      ),
    );
  }
}

class _FailingOptionsRepository implements OptionsChainRepository {
  @override
  bool get isRemoteOptionsData => true;

  @override
  Future<AppResult<List<DateTime>>> fetchExpirations(String symbol) async {
    return const AppFailure('Options unavailable.');
  }

  @override
  Future<AppResult<OptionChain>> fetchChain(
    String symbol,
    DateTime expirationDate,
  ) async {
    return const AppFailure('Options unavailable.');
  }

  @override
  Future<AppResult<OptionQuote>> fetchQuote(
    String symbol,
    DateTime expirationDate,
    double strike,
    OptionType optionType,
  ) async {
    return const AppFailure('Options unavailable.');
  }
}
