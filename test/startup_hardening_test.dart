import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/data/auth_repository.dart';
import 'package:trading_app/core/data/market_repository.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_repository.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_repository.dart';
import 'package:trading_app/core/models/app_user.dart';
import 'package:trading_app/core/models/auth_session.dart';
import 'package:trading_app/core/models/asset.dart';
import 'package:trading_app/core/config/app_config.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/core/onboarding/local_onboarding_repository.dart';
import 'package:trading_app/core/onboarding/onboarding_progress.dart';
import 'package:trading_app/core/onboarding/onboarding_store.dart';

void main() {
  testWidgets('startup restore renders without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final onboardingRepository = LocalOnboardingRepository(
      store: MemoryOnboardingStore(),
    );
    await onboardingRepository.saveProgress(
      OnboardingProgress(
        viewedVersion: AppConfig.onboardingVersion,
        acceptedVersion: AppConfig.onboardingVersion,
        viewedAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      TradingApp(
        authRepository: _ThrowingAuthRepository(),
        onboardingRepository: onboardingRepository,
        marketRepository: _FailingMarketRepository(),
        paperTradingRepository: _ThrowingPaperTradingRepository(),
        journalRepository: _ThrowingJournalRepository(),
        optionsPortfolioRepository: _ThrowingOptionsPortfolioRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('Unable to load market data.'), findsOneWidget);
  });
}

class _ThrowingAuthRepository implements AuthRepository {
  const _ThrowingAuthRepository();

  @override
  Future<AppResult<AppUser?>> currentUser() {
    throw StateError('auth unavailable');
  }

  @override
  Future<AppResult<AuthSession?>> restoreSession() {
    throw StateError('auth unavailable');
  }

  @override
  Future<AppResult<AuthSession>> signInDemo() {
    throw StateError('auth unavailable');
  }

  @override
  Future<AppResult<void>> signOut() {
    throw StateError('auth unavailable');
  }

  @override
  Future<AppResult<void>> saveSession(AuthSession session) {
    throw StateError('auth unavailable');
  }

  @override
  Future<AppResult<AuthSession>> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw StateError('auth unavailable');
  }
}

class _ThrowingPaperTradingRepository implements PaperTradingRepository {
  const _ThrowingPaperTradingRepository();

  @override
  Future<AppResult<PaperTradingAccount>> clearOrderHistory(
    PaperTradingAccount account,
  ) {
    throw StateError('paper trading unavailable');
  }

  @override
  Future<AppResult<PaperTradingAccount>> loadAccount() {
    throw StateError('paper trading unavailable');
  }

  @override
  Future<AppResult<PaperTradingAccount>> resetAccount() {
    throw StateError('paper trading unavailable');
  }

  @override
  Future<AppResult<void>> saveAccount(PaperTradingAccount account) {
    throw StateError('paper trading unavailable');
  }
}

class _FailingMarketRepository implements MarketRepository {
  const _FailingMarketRepository();

  @override
  MarketDataMode get mode => MarketDataMode.remote;

  @override
  Future<AppResult<List<TradingAsset>>> loadAssets() async {
    return const AppFailure('Unable to load market data.');
  }

  @override
  Future<AppResult<List<TradingAsset>>> refreshPrices(
    List<TradingAsset> currentAssets,
  ) async {
    return const AppFailure('Unable to refresh market data.');
  }
}

class _ThrowingJournalRepository implements JournalRepository {
  const _ThrowingJournalRepository();

  @override
  Future<AppResult<List<JournalEntry>>> loadEntries() {
    throw StateError('journal unavailable');
  }

  @override
  Future<AppResult<void>> saveEntries(List<JournalEntry> entries) {
    throw StateError('journal unavailable');
  }

  @override
  Future<AppResult<void>> deleteEntry(String entryId) {
    throw StateError('journal unavailable');
  }

  @override
  Future<AppResult<void>> clearEntries() {
    throw StateError('journal unavailable');
  }
}

class _ThrowingOptionsPortfolioRepository
    implements OptionsPortfolioRepository {
  const _ThrowingOptionsPortfolioRepository();

  @override
  Future<AppResult<OptionsPortfolioAccount>> loadAccount() {
    throw StateError('options unavailable');
  }

  @override
  Future<AppResult<void>> saveAccount(OptionsPortfolioAccount account) {
    throw StateError('options unavailable');
  }

  @override
  Future<AppResult<OptionsPortfolioAccount>> resetAccount() {
    throw StateError('options unavailable');
  }
}
