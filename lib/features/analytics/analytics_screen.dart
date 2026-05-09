import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/analytics/performance_snapshot.dart';
import '../../core/analytics/portfolio_analytics.dart';
import '../../core/analytics/trading_analytics.dart';
import '../../core/config/app_config.dart';
import '../../core/data/market_state.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/models/paper_order.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_stat_tile.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/mini_trend_chart.dart';
import '../../core/widgets/section_header.dart';
import '../strategy_simulator/strategy_simulator_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const routeName = '/analytics';

  @override
  Widget build(BuildContext context) {
    final marketState = MarketScope.of(context);
    final paperState = PaperTradingScope.of(context);
    final portfolio = TradingAnalytics.portfolio(
      tradingState: paperState,
      marketState: marketState,
    );
    final activity = TradingAnalytics.activity(tradingState: paperState);
    final performance = TradingAnalytics.performance(
      tradingState: paperState,
      marketState: marketState,
    );
    final hasContent =
        portfolio.openPositionsCount > 0 || activity.totalOrders > 0;

    return AppPage(
      title: 'Analytics',
      subtitle: 'Trader intelligence dashboard',
      children: [
        AppInfoBanner(
          title: marketState.dataMode.label,
          message:
              '${AppConfig.paperTradingDisclaimer} ${AppConfig.simulatedPricesDisclaimer}',
        ),
        const SizedBox(height: 12),
        _PerformanceHero(
          portfolio: portfolio,
          performance: performance,
          activity: activity,
          orders: paperState.orders,
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const SizedBox(
                width: 240,
                child: Text(
                  'Open strategy simulator',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              AppSecondaryButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(StrategySimulatorScreen.routeName),
                icon: Icons.tune,
                label: 'Open',
              ),
            ],
          ),
        ),
        if (portfolio.hasConcentrationWarning) ...[
          const SizedBox(height: 12),
          AppInfoBanner(
            title: 'Concentration risk',
            message:
                'One position represents ${portfolio.concentrationRiskPercent.toStringAsFixed(0)}% of the portfolio. Consider reducing single-asset exposure.',
            icon: Icons.warning_amber_outlined,
            accentColor: AppTheme.warning,
          ),
        ],
        if (!hasContent) ...[
          const SizedBox(height: 18),
          const EmptyStateView(
            title: 'No analytics yet',
            message:
                'Place a few paper trades to unlock portfolio performance and activity analytics.',
            icon: Icons.query_stats_outlined,
          ),
        ] else ...[
          const SectionHeader('P/L summary'),
          _PlSummaryCard(performance: performance),
          const SectionHeader('Allocation breakdown'),
          _AllocationCard(portfolio: portfolio),
          const SectionHeader('Trading activity'),
          _ActivityCard(activity: activity),
          const SectionHeader('Position insights'),
          _PositionInsightsCard(portfolio: portfolio),
        ],
      ],
    );
  }
}

class _PerformanceHero extends StatelessWidget {
  const _PerformanceHero({
    required this.portfolio,
    required this.performance,
    required this.activity,
    required this.orders,
  });

  final PortfolioAnalytics portfolio;
  final PerformanceSnapshot performance;
  final TradingActivityAnalytics activity;
  final List<PaperOrder> orders;

  @override
  Widget build(BuildContext context) {
    final series = _performanceSeries(orders);
    final returnColor = performance.totalProfitLoss >= 0
        ? AppTheme.primary
        : AppTheme.danger;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Performance overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Portfolio value',
                  value: _money(portfolio.totalPortfolioValue),
                ),
              ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Return',
                  value: _percent(performance.returnPercent),
                  color: returnColor,
                ),
              ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Open positions',
                  value: portfolio.openPositionsCount.toString(),
                ),
              ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Total orders',
                  value: activity.totalOrders.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Performance trace',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        _money(performance.totalProfitLoss),
                        style: TextStyle(
                          color: returnColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 86,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: MiniTrendChart(
                        points: series.isEmpty ? const [0, 0] : series,
                        isPositive: performance.totalProfitLoss >= 0,
                        height: 44,
                        width: 220,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlSummaryCard extends StatelessWidget {
  const _PlSummaryCard({required this.performance});

  final PerformanceSnapshot performance;

  @override
  Widget build(BuildContext context) {
    final returnColor = performance.totalProfitLoss >= 0
        ? AppTheme.primary
        : AppTheme.danger;

    return AppCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Realized P/L',
              value: _money(performance.realizedProfitLoss),
              color: performance.realizedProfitLoss >= 0
                  ? AppTheme.primary
                  : AppTheme.danger,
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Unrealized P/L',
              value: _money(performance.unrealizedProfitLoss),
              color: performance.unrealizedProfitLoss >= 0
                  ? AppTheme.primary
                  : AppTheme.danger,
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Total P/L',
              value: _money(performance.totalProfitLoss),
              color: returnColor,
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Return',
              value: _percent(performance.returnPercent),
              color: returnColor,
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Cash allocation',
              value: _percent(performance.cashAllocationPercent),
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Invested allocation',
              value: _percent(performance.investedAllocationPercent),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.portfolio});

  final PortfolioAnalytics portfolio;

  @override
  Widget build(BuildContext context) {
    if (portfolio.allocationByAsset.isEmpty) {
      return const AppCard(
        child: EmptyStateView(
          title: 'No holdings yet',
          message: 'Buy an asset to see asset-level allocation analytics.',
          icon: Icons.account_balance_wallet_outlined,
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricBar(
            label: 'Cash',
            value: _money(portfolio.cashBalance),
            percent: portfolio.cashAllocationPercent / 100,
            color: Colors.white70,
          ),
          const SizedBox(height: 12),
          ...portfolio.allocationByAsset.map(
            (allocation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MetricBar(
                label: allocation.asset.symbol,
                value: _money(allocation.marketValue),
                subtitle:
                    '${allocation.asset.name} • ${allocation.weightPercent.toStringAsFixed(0)}%',
                percent: allocation.weightPercent / 100,
                color: allocation.unrealizedProfitLoss >= 0
                    ? AppTheme.primary
                    : AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final TradingActivityAnalytics activity;

  @override
  Widget build(BuildContext context) {
    if (activity.totalOrders == 0) {
      return const AppCard(
        child: EmptyStateView(
          title: 'No orders yet',
          message: 'Activity analytics appear after the first paper trade.',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    final buyPercent = activity.totalOrders == 0
        ? 0.0
        : activity.buyOrderCount / activity.totalOrders;
    final sellPercent = activity.totalOrders == 0
        ? 0.0
        : activity.sellOrderCount / activity.totalOrders;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Buy orders',
                  value: activity.buyOrderCount.toString(),
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Sell orders',
                  value: activity.sellOrderCount.toString(),
                  color: AppTheme.warning,
                ),
              ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Avg order size',
                  value: _money(activity.averageOrderSize),
                ),
              ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Most traded',
                  value: activity.mostTradedAsset?.symbol ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricBar(
            label: 'Buy mix',
            value: '${activity.buyOrderCount} orders',
            percent: buyPercent,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _MetricBar(
            label: 'Sell mix',
            value: '${activity.sellOrderCount} orders',
            percent: sellPercent,
            color: AppTheme.warning,
          ),
          if (activity.mostTradedAsset != null) ...[
            const SizedBox(height: 14),
            Text(
              'Most traded asset: ${activity.mostTradedAsset!.symbol} '
              '(${activity.mostTradedAsset!.orderCount} orders, ${_money(activity.mostTradedAsset!.totalNotional)})',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (activity.largestOrder != null) ...[
            const SizedBox(height: 8),
            Text(
              'Largest order: ${activity.largestOrder!.side.label} ${activity.largestOrder!.assetSymbol} '
              '${_money(activity.largestOrder!.estimatedTotal)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (activity.lastTradeDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last trade ${_formatDate(activity.lastTradeDate!)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _PositionInsightsCard extends StatelessWidget {
  const _PositionInsightsCard({required this.portfolio});

  final PortfolioAnalytics portfolio;

  @override
  Widget build(BuildContext context) {
    if (portfolio.openPositionsCount == 0) {
      return const AppCard(
        child: EmptyStateView(
          title: 'No open positions',
          message:
              'Open a position to see best/worst and concentration insights.',
          icon: Icons.insights_outlined,
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (portfolio.largestPosition != null)
                SizedBox(
                  width: 170,
                  child: AppStatTile(
                    label: 'Largest position',
                    value: portfolio.largestPosition!.asset.symbol,
                    subtitle:
                        '${portfolio.largestPosition!.weightPercent.toStringAsFixed(0)}% of portfolio',
                  ),
                ),
              if (portfolio.bestPosition != null)
                SizedBox(
                  width: 170,
                  child: AppStatTile(
                    label: 'Best position',
                    value: portfolio.bestPosition!.asset.symbol,
                    color: AppTheme.primary,
                    subtitle: _money(
                      portfolio.bestPosition!.unrealizedProfitLoss,
                    ),
                  ),
                ),
              if (portfolio.worstPosition != null)
                SizedBox(
                  width: 170,
                  child: AppStatTile(
                    label: 'Worst position',
                    value: portfolio.worstPosition!.asset.symbol,
                    color: AppTheme.danger,
                    subtitle: _money(
                      portfolio.worstPosition!.unrealizedProfitLoss,
                    ),
                  ),
                ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Concentration',
                  value: _percent(portfolio.concentrationRiskPercent),
                  color: portfolio.hasConcentrationWarning
                      ? AppTheme.warning
                      : AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    this.subtitle,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: const TextStyle(color: Colors.white60)),
        ],
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppTheme.surfaceHigh),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: clamped,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

List<double> _performanceSeries(List<PaperOrder> orders) {
  if (orders.isEmpty) {
    return const [];
  }

  var cumulative = 0.0;
  final points = <double>[0];
  final chronological = [...orders]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  for (final order in chronological) {
    cumulative += order.realizedProfitLoss ?? 0;
    points.add(cumulative);
  }
  return points;
}

String _money(double value) {
  return '\$${value.toStringAsFixed(value.abs() >= 1000 ? 0 : 2)}';
}

String _percent(double value) => '${value.toStringAsFixed(1)}%';

String _formatDate(DateTime timestamp) {
  final monthNames = [
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
  final month = monthNames[timestamp.month - 1];
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$month ${timestamp.day}, ${timestamp.year} at $hour:$minute';
}
