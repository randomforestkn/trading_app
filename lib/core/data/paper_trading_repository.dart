import 'app_result.dart';
import 'paper_trading_account.dart';

abstract class PaperTradingRepository {
  Future<AppResult<PaperTradingAccount>> loadAccount();

  Future<AppResult<void>> saveAccount(PaperTradingAccount account);

  Future<AppResult<PaperTradingAccount>> resetAccount();

  Future<AppResult<PaperTradingAccount>> clearOrderHistory(
    PaperTradingAccount account,
  );
}
