import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/asset.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(asset.symbol)),
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
                    _Header(asset: asset),
                    const SectionHeader('Price chart'),
                    _ChartPlaceholder(asset: asset),
                    const SectionHeader('Plain English'),
                    _ExplanationCard(asset: asset),
                    const SectionHeader('Key stats'),
                    StatGrid(stats: asset.tradingStats),
                    const SizedBox(height: 10),
                    StatGrid(stats: asset.stats),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _openTrade(context, OrderSide.buy),
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
                                _openTrade(context, OrderSide.sell),
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

  void _openTrade(BuildContext context, OrderSide side) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TradeScreen(asset: asset, initialSide: side),
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

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.asset});

  final TradingAsset asset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 236,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Mock 1D price movement',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const Spacer(),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: '1D', label: Text('1D')),
                      ButtonSegment(value: '1W', label: Text('1W')),
                      ButtonSegment(value: '1M', label: Text('1M')),
                    ],
                    selected: const {'1D'},
                    onSelectionChanged: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: CustomPaint(
                  painter: _ChartPainter(
                    points: asset.trend,
                    isPositive: asset.dailyChangePercent >= 0,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: MiniTrendChart(
                      points: asset.trend,
                      isPositive: asset.dailyChangePercent >= 0,
                      height: 44,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
