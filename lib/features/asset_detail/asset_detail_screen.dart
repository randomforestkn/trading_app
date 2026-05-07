import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/market_state.dart';
import '../../core/models/asset.dart';
import '../../core/models/paper_order.dart';
import '../../core/widgets/change_text.dart';
import '../../core/widgets/mini_trend_chart.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_grid.dart';
import '../trade/trade_screen.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({required this.asset, super.key});

  final TradingAsset asset;

  @override
  Widget build(BuildContext context) {
    final currentAsset = MarketScope.of(context).latestFor(asset);

    return Scaffold(
      appBar: AppBar(title: Text(currentAsset.symbol)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(asset: currentAsset),
                    const SectionHeader('Price chart'),
                    _LivePriceChart(asset: currentAsset),
                    const SectionHeader('Plain English'),
                    _ExplanationCard(asset: currentAsset),
                    const SectionHeader('Key stats'),
                    StatGrid(stats: currentAsset.tradingStats),
                    const SizedBox(height: 10),
                    StatGrid(stats: currentAsset.stats),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                _openTrade(context, PaperOrderSide.buy),
                            icon: const Icon(Icons.add_chart),
                            label: const Text('Buy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _openTrade(context, PaperOrderSide.sell),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Sell'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTrade(BuildContext context, PaperOrderSide side) {
    final currentAsset = MarketScope.of(context).latestFor(asset);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TradeScreen(asset: currentAsset, initialSide: side),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.asset});

  final TradingAsset asset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
                  child: Text(
                    asset.symbol.characters.take(2).toString(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.symbol,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${asset.name} • ${asset.type.label}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${asset.price.toStringAsFixed(asset.price > 1000 ? 0 : 2)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: ChangeText(asset.dailyChangePercent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePriceChart extends StatefulWidget {
  const _LivePriceChart({required this.asset});

  final TradingAsset asset;

  @override
  State<_LivePriceChart> createState() => _LivePriceChartState();
}

class _LivePriceChartState extends State<_LivePriceChart> {
  String _timeframe = '1D';

  @override
  Widget build(BuildContext context) {
    final marketState = MarketScope.of(context);
    final asset = marketState.latestFor(widget.asset);
    final points = marketState.timeframeHistoryFor(asset.symbol, _timeframe);
    final first = points.isEmpty ? asset.price : points.first;
    final latest = points.isEmpty ? asset.price : points.last;
    final priceChange = latest - first;
    final percentChange = first == 0 ? 0.0 : (priceChange / first) * 100;
    final isPositive = priceChange >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live simulated price history',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${latest.toStringAsFixed(latest > 1000 ? 0 : 2)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${priceChange >= 0 ? '+' : ''}\$${priceChange.toStringAsFixed(2)} (${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: isPositive ? AppTheme.primary : AppTheme.danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: '1D', label: Text('1D')),
                    ButtonSegment(value: '1W', label: Text('1W')),
                    ButtonSegment(value: '1M', label: Text('1M')),
                  ],
                  selected: {_timeframe},
                  onSelectionChanged: (value) {
                    setState(() => _timeframe = value.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: CustomPaint(
                painter: _ChartPainter(points: points, isPositive: isPositive),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: MiniTrendChart(
                    points: points,
                    isPositive: isPositive,
                    height: 44,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.points, required this.isPositive});

  final List<double> points;
  final bool isPositive;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.length < 2) {
      return;
    }

    final minValue = points.reduce((a, b) => a < b ? a : b);
    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final range = maxValue == minValue ? 1 : maxValue - minValue;
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - ((points[i] - minValue) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          isPositive ? AppTheme.primary : AppTheme.danger,
          AppTheme.secondary,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return points != oldDelegate.points || isPositive != oldDelegate.isPositive;
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.asset});

  final TradingAsset asset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          asset.explanation,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
