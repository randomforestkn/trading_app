import '../data/app_result.dart';
import '../strategies/option_contract.dart';
import 'options_chain_models.dart';
import 'options_chain_repository.dart';

class LocalManualOptionsRepository implements OptionsChainRepository {
  const LocalManualOptionsRepository();

  @override
  bool get isRemoteOptionsData => false;

  @override
  Future<AppResult<List<DateTime>>> fetchExpirations(String symbol) async {
    return const AppSuccess(<DateTime>[]);
  }

  @override
  Future<AppResult<OptionChain>> fetchChain(
    String symbol,
    DateTime expirationDate,
  ) async {
    return const AppFailure(
      'Manual options input mode is active. Remote chain data is not configured.',
    );
  }

  @override
  Future<AppResult<OptionQuote>> fetchQuote(
    String symbol,
    DateTime expirationDate,
    double strike,
    OptionType optionType,
  ) async {
    return const AppFailure(
      'Manual options input mode is active. Remote chain data is not configured.',
    );
  }
}
