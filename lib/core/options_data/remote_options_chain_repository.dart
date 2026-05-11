import '../data/app_result.dart';
import '../utils/app_logger.dart';
import '../strategies/option_contract.dart';
import 'options_api_client.dart';
import 'options_chain_models.dart';
import 'options_chain_repository.dart';

class RemoteOptionsChainRepository implements OptionsChainRepository {
  RemoteOptionsChainRepository({required OptionsApiClient apiClient})
    : _apiClient = apiClient;

  final OptionsApiClient _apiClient;

  @override
  bool get isRemoteOptionsData => true;

  @override
  Future<AppResult<List<DateTime>>> fetchExpirations(String symbol) async {
    if (!_apiClient.config.isRemoteEnabled) {
      return const AppFailure(
        'Remote options data is not configured. Provide OPTIONS_BASE_URL and OPTIONS_API_KEY.',
      );
    }

    try {
      return await _apiClient.fetchExpirations(symbol);
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Options expirations fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Unable to load options expirations.');
    }
  }

  @override
  Future<AppResult<OptionChain>> fetchChain(
    String symbol,
    DateTime expirationDate,
  ) async {
    if (!_apiClient.config.isRemoteEnabled) {
      return const AppFailure(
        'Remote options data is not configured. Provide OPTIONS_BASE_URL and OPTIONS_API_KEY.',
      );
    }

    try {
      return await _apiClient.fetchChain(symbol, expirationDate);
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Options chain fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Unable to load options chain.');
    }
  }

  @override
  Future<AppResult<OptionQuote>> fetchQuote(
    String symbol,
    DateTime expirationDate,
    double strike,
    OptionType optionType,
  ) async {
    if (!_apiClient.config.isRemoteEnabled) {
      return const AppFailure(
        'Remote options data is not configured. Provide OPTIONS_BASE_URL and OPTIONS_API_KEY.',
      );
    }

    try {
      return await _apiClient.fetchQuote(
        symbol,
        expirationDate,
        strike,
        optionType,
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Options quote fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Unable to load options quote.');
    }
  }
}
