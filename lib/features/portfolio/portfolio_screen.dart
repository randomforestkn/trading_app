import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/market_state.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/models/asset.dart';
import '../../core/models/portfolio_position.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/change_text.dart';
import '../../core/widgets/section_header.dart';
import '../activity/activity_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tradingState = PaperTradingScope.of(context);
    final marketState = MarketScope.of(context);
    final positions = tradingState.positionsFor(marketState);

    return AppPage(
      title: 'Portfolio',
      subtitle: 'Paper account overview',
      actions: [
        IconButton(
          tooltip: 'Activity',
          onPressed: () =>
              Navigator.of(context).pushNamed(ActivityScreen.routeName),
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: 'Reset paper portfolio',
          onPressed: () => _confirmReset(context, tradingState),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.danger,
            backgroundColor: AppTheme.danger.withValues(alpha: 0.10),
          ),
          icon: const Icon(Icons.restart_alt),
        ),
      ],
      children: [
        _PortfolioSummary(
          portfolioValue: tradingState.totalPortfolioValueFor(marketState),
          cashBalance: tradingState.cashBalance,
          unrealized: tradingState.unrealizedProfitLossFor(marketState),
          lastUpdated: tradingState.lastUpdated,
        ),
        const SectionHeader('Open positions'),
        if (positions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'No open positions yet. Place a paper trade to begin.',
              ),
            ),
          )
        else
          ...positions.map(
            (position) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PositionTile(position: position),
            ),
          ),
        const SectionHeader('Asset allocation'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allocationCards(tradingState, marketState),
        ),
      ],
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    PaperTradingState tradingState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset paper portfolio?'),
          content: const Text(
            'This restores the default mock account, including cash and starting positions, and clears order history. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await tradingState.reset();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Paper portfolio reset.'),
      ),
    );
  }

  List<Widget> _allocationCards(
    PaperTradingState tradingState,
    MarketState marketState,
  ) {
    final total = tradingState.totalPortfolioValueFor(marketState);
    final positions = tradingState.positionsFor(marketState);
    final stockValue = positions
        .where((position) => position.asset.type == AssetType.stock)
        .fold<double>(0, (total, position) => total + position.marketValue);
    final etfValue = positions
        .where((position) => position.asset.type == AssetType.etf)
        .fold<double>(0, (total, position) => total + position.marketValue);
    final cryptoValue = positions
        .where((position) => position.asset.type == AssetType.crypto)
        .fold<double>(0, (total, position) => total + position.marketValue);
    final otherValue =
        tradingState.positionsValueFor(marketState) -
        stockValue -
        etfValue -
        cryptoValue;

    String percentage(double value) =>
        total == 0 ? '0%' : '${((value / total) * 100).round()}%';

    return [
      _AllocationCard(
        label: 'Stocks',
        value: percentage(stockValue),
        color: AppTheme.primary,
      ),
      _AllocationCard(
        label: 'ETFs',
        value: percentage(etfValue),
        color: AppTheme.secondary,
      ),
      _AllocationCard(
        label: 'Crypto',
        value: percentage(cryptoValue),
        color: AppTheme.warning,
      ),
      _AllocationCard(
        label: 'Other',
        value: percentage(otherValue),
        color: const Color(0xFFBCA8FF),
      ),
      _AllocationCard(
        label: 'Cash',
        value: percentage(tradingState.cashBalance),
        color: Colors.white70,
      ),
    ];
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({
    required this.portfolioValue,
    required this.cashBalance,
    required this.unrealized,
    required this.lastUpdated,
  });

  final double portfolioValue;
  final double cashBalance;
  final double unrealized;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total portfolio value',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${portfolioValue.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              lastUpdated == null
                  ? 'Default mock portfolio'
                  : 'Last updated ${_formatTimestamp(lastUpdated!)}',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Cash balance',
                    value: '\$${cashBalance.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Unrealized P/L',
                    value:
                        '${unrealized >= 0 ? '+' : ''}\$${unrealized.toStringAsFixed(2)}',
                    positive: unrealized >= 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final month = _monthName(timestamp.month);
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$month ${timestamp.day}, ${timestamp.year} at $hour:$minute';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.positive});

  final String label;
  final String value;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: positive == null
                ? Colors.white
                : positive!
                ? AppTheme.primary
                : AppTheme.danger,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PositionTile extends StatelessWidget {
  const _PositionTile({required this.position});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          position.asset.symbol,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${position.quantity} units • avg \$${position.averagePrice.toStringAsFixed(2)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${position.marketValue.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            ChangeText(position.unrealizedProfitLossPercent, compact: true),
          ],
        ),
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width > 520 ? 190 : 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.pie_chart, color: color),
              const SizedBox(height: 14),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }
}
