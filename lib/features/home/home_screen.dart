import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/mock_market_data.dart';
import '../../core/models/asset.dart';
import '../../core/models/market_index.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/asset_tile.dart';
import '../../core/widgets/change_text.dart';
import '../../core/widgets/mini_trend_chart.dart';
import '../../core/widgets/section_header.dart';
import '../activity/activity_screen.dart';
import '../asset_detail/asset_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'ClearTrade',
      subtitle: 'Paper trading workspace',
      actions: [
        IconButton(
          tooltip: 'Activity',
          onPressed: () =>
              Navigator.of(context).pushNamed(ActivityScreen.routeName),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
      ],
      children: [
        const _MarketSnapshotCard(),
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
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MockMarketData.topMovers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final asset = MockMarketData.topMovers[index];
              return _MoverCard(
                asset: asset,
                onTap: () => _openAsset(context, asset),
              );
            },
          ),
        ),
        const SectionHeader('Quick watchlist access'),
        ...MockMarketData.assets
            .take(4)
            .map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AssetTile(
                  asset: asset,
                  onTap: () => _openAsset(context, asset),
                ),
              ),
            ),
        const SectionHeader('Crypto'),
        ...MockMarketData.crypto.map(
          (asset) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AssetTile(
              asset: asset,
              onTap: () => _openAsset(context, asset),
            ),
          ),
        ),
        const SectionHeader('Popular ETFs'),
        ...MockMarketData.etfs.map(
          (asset) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AssetTile(
              asset: asset,
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
    final totalValue = cashBalance + positionsValue;

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
                    '\$${totalValue.toStringAsFixed(2)}',
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
            padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 8),
                Text(
                  asset.type.label,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const Spacer(),
                MiniTrendChart(
                  points: asset.trend,
                  isPositive: asset.dailyChangePercent >= 0,
                  width: 92,
                  height: 44,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${asset.price.toStringAsFixed(asset.price > 1000 ? 0 : 2)}',
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
