import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/data/auth_repository.dart';
import '../core/data/auth_repository_factory.dart';
import '../core/data/auth_state.dart';
import '../core/data/local_paper_trading_repository.dart';
import '../core/data/market_repository.dart';
import '../core/data/market_repository_factory.dart';
import '../core/data/market_state.dart';
import '../core/journal/journal_repository.dart';
import '../core/journal/local_journal_repository.dart';
import '../core/journal/journal_state.dart';
import '../core/journal/journal_store.dart';
import '../core/insights/insights_state.dart';
import '../core/onboarding/local_onboarding_repository.dart';
import '../core/onboarding/onboarding_repository.dart';
import '../core/onboarding/onboarding_state.dart';
import '../core/onboarding/onboarding_store.dart';
import '../core/options_portfolio/local_options_portfolio_repository.dart';
import '../core/options_portfolio/options_portfolio_repository.dart';
import '../core/options_portfolio/options_portfolio_state.dart';
import '../core/options_portfolio/options_portfolio_store.dart';
import '../core/data/paper_trading_state.dart';
import '../core/data/paper_trading_repository.dart';
import '../core/data/paper_trading_store.dart';
import '../core/sync/local_sync_repository.dart';
import '../core/sync/sync_repository.dart';
import '../core/sync/sync_state.dart';
import '../core/utils/app_logger.dart';
import '../features/activity/activity_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/export_reports/export_reports_screen.dart';
import '../features/home/home_screen.dart';
import '../features/legal/disclaimer_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/options_portfolio/options_portfolio_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/strategy_simulator/strategy_simulator_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import 'theme/app_theme.dart';

class TradingApp extends StatefulWidget {
  const TradingApp({
    super.key,
    this.authRepository,
    this.onboardingRepository,
    this.marketRepository,
    this.paperTradingRepository,
    this.journalRepository,
    this.optionsPortfolioRepository,
    this.syncRepository,
  });

  final AuthRepository? authRepository;
  final OnboardingRepository? onboardingRepository;
  final MarketRepository? marketRepository;
  final PaperTradingRepository? paperTradingRepository;
  final JournalRepository? journalRepository;
  final OptionsPortfolioRepository? optionsPortfolioRepository;
  final SyncRepository? syncRepository;

  @override
  State<TradingApp> createState() => _TradingAppState();
}

class _TradingAppState extends State<TradingApp> with WidgetsBindingObserver {
  late final AuthState _authState;
  late final OnboardingState _onboardingState;
  late final MarketState _marketState;
  late final SyncState _syncState;
  late final Future<PaperTradingState> _paperTradingStateFuture;
  late final Future<JournalState> _journalStateFuture;
  late final Future<OptionsPortfolioState> _optionsPortfolioStateFuture;
  PaperTradingState? _paperTradingState;
  JournalState? _journalState;
  OptionsPortfolioState? _optionsPortfolioState;
  InsightsState? _insightsState;
  late final Future<_TradingStartupBundle> _startupFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncState = SyncState(
      repository:
          widget.syncRepository ??
          LocalSyncRepository(store: SharedPreferencesSyncStore()),
    );
    _authState = AuthState(
      repository: widget.authRepository ?? AuthRepositoryFactory.buildDefault(),
      syncState: _syncState,
    );
    _onboardingState = OnboardingState(
      repository:
          widget.onboardingRepository ??
          LocalOnboardingRepository(store: SharedPreferencesOnboardingStore()),
    );
    _marketState = MarketState(
      repository:
          widget.marketRepository ?? MarketRepositoryFactory.buildDefault(),
    );
    _paperTradingStateFuture = PaperTradingState.load(
      repository:
          widget.paperTradingRepository ??
          LocalPaperTradingRepository(
            store: SharedPreferencesPaperTradingStore(),
          ),
      syncState: _syncState,
    );
    _journalStateFuture = JournalState.load(
      repository:
          widget.journalRepository ??
          LocalJournalRepository(store: SharedPreferencesJournalStore()),
      syncState: _syncState,
    );
    _optionsPortfolioStateFuture = OptionsPortfolioState.load(
      repository:
          widget.optionsPortfolioRepository ??
          LocalOptionsPortfolioRepository(
            store: SharedPreferencesOptionsPortfolioStore(),
          ),
      syncState: _syncState,
    );
    _startupFuture = _restoreStartupState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authState.dispose();
    _onboardingState.dispose();
    _marketState.dispose();
    _syncState.dispose();
    _paperTradingState?.dispose();
    _journalState?.dispose();
    _insightsState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TradingStartupBundle>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final bundle = snapshot.data!;
          _paperTradingState = bundle.paperTradingState;
          _journalState = bundle.journalState;
          _optionsPortfolioState = bundle.optionsPortfolioState;
          _insightsState ??= bundle.insightsState;
          return AnimatedBuilder(
            animation: _onboardingState,
            builder: (context, _) {
              final home = bundle.onboardingState.isAccepted
                  ? const TradingShell()
                  : const OnboardingScreen(requireAcceptance: true);
              return OnboardingScope(
                state: _onboardingState,
                child: AuthScope(
                  state: _authState,
                  child: SyncScope(
                    state: _syncState,
                    child: PaperTradingScope(
                      state: _paperTradingState!,
                      child: MarketScope(
                        state: _marketState,
                        child: JournalScope(
                          state: _journalState!,
                          child: OptionsPortfolioScope(
                            state: _optionsPortfolioState!,
                            child: InsightsScope(
                              state: _insightsState!,
                              child: _buildMaterialApp(home),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        if (snapshot.hasError) {
          AppLogger.error('Startup restore failed', error: snapshot.error);
          return _buildMaterialApp(
            const _StartupScreen(
              message:
                  'Unable to restore saved demo state. The app will retry on restart.',
            ),
          );
        }

        return _buildMaterialApp(
          const _StartupScreen(message: 'Restoring demo account...'),
        );
      },
    );
  }

  Future<_TradingStartupBundle> _restoreStartupState() async {
    await _authState.restoreSession();
    await _onboardingState.load();
    _journalState = await _journalStateFuture;
    _optionsPortfolioState = await _optionsPortfolioStateFuture;
    final paperTradingState = await _paperTradingStateFuture;
    await _marketState.loadAssets();
    await _syncState.refreshMetadata();
    _insightsState = InsightsState(
      journalState: _journalState!,
      paperTradingState: paperTradingState,
      optionsState: _optionsPortfolioState!,
      marketState: _marketState,
    );
    return _TradingStartupBundle(
      onboardingState: _onboardingState,
      paperTradingState: paperTradingState,
      journalState: _journalState!,
      optionsPortfolioState: _optionsPortfolioState!,
      insightsState: _insightsState!,
    );
  }

  Widget _buildMaterialApp(Widget home) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      routes: {
        ActivityScreen.routeName: (_) => const ActivityScreen(),
        AnalyticsScreen.routeName: (_) => const AnalyticsScreen(),
        ExportReportsScreen.routeName: (_) => const ExportReportsScreen(),
        InsightsScreen.routeName: (_) => const InsightsScreen(),
        JournalScreen.routeName: (_) => const JournalScreen(),
        DisclaimerScreen.routeName: (_) => const DisclaimerScreen(),
        DataPrivacyScreen.routeName: (_) => const DataPrivacyScreen(),
        OptionsPortfolioScreen.routeName: (_) => const OptionsPortfolioScreen(),
        StrategySimulatorScreen.routeName: (_) =>
            const StrategySimulatorScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
      home: home,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    _syncState.refreshMetadata();
    _insightsState?.refreshInsights();
  }
}

class _TradingStartupBundle {
  const _TradingStartupBundle({
    required this.onboardingState,
    required this.paperTradingState,
    required this.journalState,
    required this.optionsPortfolioState,
    required this.insightsState,
  });

  final OnboardingState onboardingState;
  final PaperTradingState paperTradingState;
  final JournalState journalState;
  final OptionsPortfolioState optionsPortfolioState;
  final InsightsState insightsState;
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TradingShell extends StatefulWidget {
  const TradingShell({super.key});

  @override
  State<TradingShell> createState() => _TradingShellState();
}

class _TradingShellState extends State<TradingShell> {
  int _selectedIndex = 0;

  static const _screens = [
    HomeScreen(),
    WatchlistScreen(),
    PortfolioScreen(),
    AnalyticsScreen(),
    LearnScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Learn',
          ),
        ],
      ),
    );
  }
}
