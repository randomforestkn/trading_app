import 'app_result.dart';
import 'paper_trading_account.dart';
import 'paper_trading_repository.dart';
import 'paper_trading_store.dart';

class LocalPaperTradingRepository implements PaperTradingRepository {
  const LocalPaperTradingRepository({this.store});

  final PaperTradingStore? store;

  @override
  Future<AppResult<PaperTradingAccount>> loadAccount() async {
    final savedAccount = await store?.read();
    if (savedAccount == null) {
      return AppSuccess(PaperTradingAccount.defaultAccount());
    }

    try {
      return AppSuccess(PaperTradingAccount.fromJsonString(savedAccount));
    } on FormatException {
      await store?.clear();
      return AppSuccess(PaperTradingAccount.defaultAccount());
    } on TypeError {
      await store?.clear();
      return AppSuccess(PaperTradingAccount.defaultAccount());
    }
  }

  @override
  Future<AppResult<void>> saveAccount(PaperTradingAccount account) async {
    await store?.write(account.toJsonString());
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<PaperTradingAccount>> resetAccount() async {
    await store?.clear();
    return AppSuccess(PaperTradingAccount.defaultAccount());
  }

  @override
  Future<AppResult<PaperTradingAccount>> clearOrderHistory(
    PaperTradingAccount account,
  ) async {
    final updatedAccount = account.copyWith(
      orders: const [],
      lastUpdated: DateTime.now(),
    );
    await saveAccount(updatedAccount);
    return AppSuccess(updatedAccount);
  }
}
