import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/data/auth_repository.dart';
import '../core/data/auth_state.dart';
import '../core/data/auth_store.dart';
import '../core/data/local_demo_auth_repository.dart';
import '../core/data/local_paper_trading_repository.dart';
import '../core/data/market_repository.dart';
import '../core/data/market_repository_factory.dart';
import '../core/data/market_state.dart';
import '../core/data/paper_trading_state.dart';
import '../core/data/paper_trading_repository.dart';
import '../core/data/paper_trading_store.dart';
import '../core/utils/app_logger.dart';
import '../features/activity/activity_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import 'theme/app_theme.dart';

class TradingApp extends StatefulWidget {
  const TradingApp({
    super.key,
    this.authRepository,
    this.marketRepository,
    this.paperTradingRepository,
  });

  final AuthRepository? authRepository;
  final MarketRepository? marketRepository;
  final PaperTradingRepository? paperTradingRepository;

  @override
  State<TradingApp> createState() => _TradingAppState();
}

class _TradingAppState extends State<TradingApp> {
  late final AuthState _authState;
  late final MarketState _marketState;
  late final Future<PaperTradingState> _paperTradingStateFuture;
  PaperTradingState? _paperTradingState;
  late final Future<void> _authRestoreFuture;
  late final Future<PaperTradingState> _startupFuture;

  @override
  void initState() {
    super.initState();
    _authState = AuthState(
      repository:
          widget.authRepository ??
          LocalDemoAuthRepository(store: SharedPreferencesAuthStore()),
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
    );
    _authRestoreFuture = _authState.restoreSession();
    _startupFuture = _restoreStartupState();
  }

  @override
  void dispose() {
    _authState.dispose();
    _marketState.dispose();
    _paperTradingState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaperTradingState>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _paperTradingState = snapshot.data;
          return AuthScope(
            state: _authState,
            child: PaperTradingScope(
              state: _paperTradingState!,
              child: MarketScope(
                state: _marketState,
                child: _buildMaterialApp(const TradingShell()),
              ),
            ),
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

  Future<PaperTradingState> _restoreStartupState() async {
    await _authRestoreFuture;
    final paperTradingState = await _paperTradingStateFuture;
    await _marketState.loadAssets();
    return paperTradingState;
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
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
      home: home,
    );
  }
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
