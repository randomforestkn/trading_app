import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/mock_market_data.dart';
import '../../core/models/portfolio_position.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/change_text.dart';
import '../../core/widgets/section_header.dart';
import '../activity/activity_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  static const double cashBalance = 18420.55;

  @override
  Widget build(BuildContext context) {
    final positions = MockMarketData.positions;
    final positionsValue = positions.fold<double>(
      0,
      (total, position) => total + position.marketValue,
    );
    final unrealized = positions.fold<double>(
      0,
      (total, position) => total + position.unrealizedProfitLoss,
    );
    final portfolioValue = cashBalance + positionsValue;

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
      ],
      children: [
        _PortfolioSummary(
          portfolioValue: portfolioValue,
          cashBalance: cashBalance,
          unrealized: unrealized,
        ),
        const SectionHeader('Open positions'),
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
          children: const [
            _AllocationCard(
              label: 'Stocks',
              value: '35%',
              color: AppTheme.primary,
            ),
            _AllocationCard(
              label: 'ETFs',
              value: '28%',
              color: AppTheme.secondary,
            ),
            _AllocationCard(
              label: 'Crypto',
              value: '22%',
              color: AppTheme.warning,
            ),
            _AllocationCard(label: 'Cash', value: '15%', color: Colors.white70),
          ],
        ),
      ],
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({
    required this.portfolioValue,
    required this.cashBalance,
    required this.unrealized,
  });

  final double portfolioValue;
  final double cashBalance;
  final double unrealized;

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
