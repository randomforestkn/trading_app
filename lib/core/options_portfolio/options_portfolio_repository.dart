import '../data/app_result.dart';
import 'options_portfolio_account.dart';

abstract class OptionsPortfolioRepository {
  Future<AppResult<OptionsPortfolioAccount>> loadAccount();

  Future<AppResult<void>> saveAccount(OptionsPortfolioAccount account);

  Future<AppResult<OptionsPortfolioAccount>> resetAccount();
}
