import 'dart:convert';

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'options_portfolio_account.dart';
import 'options_portfolio_repository.dart';
import 'options_portfolio_store.dart';

class LocalOptionsPortfolioRepository implements OptionsPortfolioRepository {
  const LocalOptionsPortfolioRepository({this.store});

  final OptionsPortfolioStore? store;

  @override
  Future<AppResult<OptionsPortfolioAccount>> loadAccount() async {
    final savedAccount = await store?.read();
    if (savedAccount == null) {
      return AppSuccess(OptionsPortfolioAccount.defaultAccount());
    }

    try {
      return AppSuccess(OptionsPortfolioAccount.fromJsonString(savedAccount));
    } on FormatException catch (error, stackTrace) {
      AppLogger.warn(
        'Options portfolio storage contained invalid data',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return AppSuccess(OptionsPortfolioAccount.defaultAccount());
    } on TypeError catch (error, stackTrace) {
      AppLogger.warn(
        'Options portfolio storage contained invalid types',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return AppSuccess(OptionsPortfolioAccount.defaultAccount());
    }
  }

  @override
  Future<AppResult<void>> saveAccount(OptionsPortfolioAccount account) async {
    await store?.write(jsonEncode(account.toJson()));
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<OptionsPortfolioAccount>> resetAccount() async {
    await store?.clear();
    return AppSuccess(OptionsPortfolioAccount.defaultAccount());
  }
}
