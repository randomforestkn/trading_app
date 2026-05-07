import 'package:flutter/material.dart';

import '../features/activity/activity_screen.dart';
import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import 'theme/app_theme.dart';

class TradingApp extends StatelessWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClearTrade',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      routes: {ActivityScreen.routeName: (_) => const ActivityScreen()},
      home: const TradingShell(),
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
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Learn',
          ),
        ],
      ),
    );
  }
}
