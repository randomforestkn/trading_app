import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/data/market_state.dart';
import '../../core/data/mock_market_data.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/models/asset.dart';
import '../../core/models/market_index.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/asset_tile.dart';
import '../../core/widgets/change_text.dart';
import '../../core/widgets/mini_trend_chart.dart';
import '../../core/widgets/section_header.dart';
import '../activity/activity_screen.dart';
import '../asset_detail/asset_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final marketState = MarketScope.of(context);

    return AppPage(
      title: AppConfig.appName,
      subtitle: AppConfig.homeSubtitle,
      actions: [
        IconButton(
          tooltip: 'Refresh prices',
          onPressed: marketState.isLoading
              ? null
              : () => _refreshPrices(context, marketState),
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () =>
              Navigator.of(context).pushNamed(SettingsScreen.routeName),
          icon: const Icon(Icons.settings_outlined),
        ),
        IconButton(
          tooltip: 'Activity',
          onPressed: () =>
              Navigator.of(context).pushNamed(ActivityScreen.routeName),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
      ],
      children: [
        const _SimulatedPricesNotice(),
        const SizedBox(height: 12),
        const _MarketSnapshotCard(),
        const SizedBox(height: 12),
        _RefreshSummaryCard(marketState: marketState),
        const SizedBox(height: 12),
        const _PortfolioSnapshotCard(),
        const SectionHeader('Market summary'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: MockMarketData.indices
              .map((index) => _IndexCard(index: index))
              .toList(),
        ),
        const SectionHeader('Top movers'),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: marketState.topMovers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final asset = marketState.topMovers[index];
              return _MoverCard(
                asset: asset,
                onTap: () => _openAsset(context, asset),
              );
            },
          ),
        ),
        const SectionHeader('Quick watchlist access'),
        ...marketState.assets
            .take(4)
            .map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AssetTile(
                  asset: asset,
                  history: marketState.historyFor(asset.symbol),
                  onTap: () => _openAsset(context, asset),
                ),
              ),
            ),
        const SectionHeader('Crypto'),
        ...marketState.crypto.map(
          (asset) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AssetTile(
              asset: asset,
              history: marketState.historyFor(asset.symbol),
              onTap: () => _openAsset(context, asset),
            ),
          ),
        ),
        const SectionHeader('Popular ETFs'),
        ...marketState.etfs.map(
          (asset) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AssetTile(
              asset: asset,
              history: marketState.historyFor(asset.symbol),
              onTap: () => _openAsset(context, asset),
            ),
          ),
        ),
      ],
    );
  }

  void _openAsset(BuildContext context, TradingAsset asset) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)));
  }

  Future<void> _refreshPrices(
    BuildContext context,
    MarketState marketState,
  ) async {
    final result = await marketState.refreshPrices();
    if (!context.mounted) {
      return;
    }
    result.when(
      success: (_) {},
      failure: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}

class _RefreshSummaryCard extends StatelessWidget {
  const _RefreshSummaryCard({required this.marketState});

  final MarketState marketState;

  @override
  Widget build(BuildContext context) {
    final gainer = marketState.biggestGainer;
    final loser = marketState.biggestLoser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Simulated market',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: marketState.isLoading
                      ? null
                      : () => _refreshPrices(context),
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    marketState.isLoading ? 'Refreshing' : 'Refresh prices',
                  ),
                ),
              ],
            ),
            if (marketState.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                marketState.errorMessage!,
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              marketState.lastRefreshAt == null
                  ? 'Not refreshed yet'
                  : 'Last refresh ${_formatTimestamp(marketState.lastRefreshAt!)}',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MoveSnapshot(
                    label: 'Biggest gainer',
                    asset: gainer,
                    positive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MoveSnapshot(
                    label: 'Biggest loser',
                    asset: loser,
                    positive: false,
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
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _refreshPrices(BuildContext context) async {
    final result = await marketState.refreshPrices();
    if (!context.mounted) {
      return;
    }
    result.when(
      success: (_) {},
      failure: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}

class _MoveSnapshot extends StatelessWidget {
  const _MoveSnapshot({
    required this.label,
    required this.asset,
    required this.positive,
  });

  final String label;
  final TradingAsset? asset;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppTheme.primary : AppTheme.danger;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 6),
            Text(
              asset?.symbol ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              asset == null
                  ? '0.00%'
                  : '${asset!.dailyChangePercent >= 0 ? '+' : ''}${asset!.dailyChangePercent.toStringAsFixed(2)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketSnapshotCard extends StatelessWidget {
  const _MarketSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF13251F), Color(0xFF111A26)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total market snapshot',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              'Mixed open, tech leads',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paper market data is delayed and simulated for learning.',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _SnapshotMetric(label: 'Advancers', value: '58%'),
                _SnapshotMetric(label: 'Volatility', value: 'Low'),
                _SnapshotMetric(label: 'Sentiment', value: 'Neutral'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulatedPricesNotice extends StatelessWidget {
  const _SimulatedPricesNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${MarketScope.of(context).dataMode.label}. ${AppConfig.paperTradingDisclaimer}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({required this.index});

  final MarketIndex index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width > 520 ? 190 : 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stacked_line_chart,
                    color: AppTheme.secondary,
                  ),
                  const Spacer(),
                  ChangeText(index.changePercent, compact: true),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                index.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                index.value.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioSnapshotCard extends StatelessWidget {
  const _PortfolioSnapshotCard();

  @override
  Widget build(BuildContext context) {
    final tradingState = PaperTradingScope.of(context);
    final marketState = MarketScope.of(context);
    final unrealized = tradingState.unrealizedProfitLossFor(marketState);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Portfolio snapshot',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${tradingState.totalPortfolioValueFor(marketState).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${unrealized >= 0 ? '+' : ''}\$${unrealized.toStringAsFixed(2)} unrealized P/L',
                    style: TextStyle(
                      color: unrealized >= 0
                          ? AppTheme.primary
                          : AppTheme.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.asset, required this.onTap});

  final TradingAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        asset.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChangeText(asset.dailyChangePercent, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  asset.type.label,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const Spacer(),
                MiniTrendChart(
                  points: MarketScope.of(context).historyFor(asset.symbol),
                  isPositive: asset.dailyChangePercent >= 0,
                  width: 92,
                  height: 34,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${asset.price.toStringAsFixed(asset.price > 1000 ? 0 : 2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
