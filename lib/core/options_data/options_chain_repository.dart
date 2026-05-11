import '../data/app_result.dart';
import '../strategies/option_contract.dart';
import 'options_chain_models.dart';

abstract class OptionsChainRepository {
  bool get isRemoteOptionsData => false;

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
