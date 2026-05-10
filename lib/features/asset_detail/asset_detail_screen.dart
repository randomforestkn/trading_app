import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/market_state.dart';
import '../../core/models/asset.dart';
import '../../core/models/paper_order.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_pill_chip.dart';
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
                constraints: const BoxConstraints(maxWidth: 900),
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
                    const SizedBox(height: 14),
                    AppInfoBanner(
                      title: 'Paper trading',
                      message:
                          'Use the live simulated chart for practice only. Prices are demo data.',
                      accentColor: AppTheme.secondary,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            onPressed: () =>
                                _openTrade(context, PaperOrderSide.buy),
                            icon: Icons.add_chart,
                            label: 'Buy',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPrimaryButton(
                            onPressed: () =>
                                _openTrade(context, PaperOrderSide.sell),
                            icon: Icons.remove_circle_outline,
                            label: 'Sell',
                            isDestructive: true,
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
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;
          final header = isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 12),
                    Text(
                      asset.symbol,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${asset.name} • ${asset.type.label}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '\$${asset.price.toStringAsFixed(asset.price > 1000 ? 0 : 2)}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: ChangeText(asset.dailyChangePercent),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.14,
                          ),
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
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
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
                );
          return header;
        },
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

    return AppCard(
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
              Wrap(
                spacing: 8,
                children: [
                  AppPillChip(
                    label: '1D',
                    selected: _timeframe == '1D',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _timeframe = '1D');
                      }
                    },
                  ),
                  AppPillChip(
                    label: '1W',
                    selected: _timeframe == '1W',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _timeframe = '1W');
                      }
                    },
                  ),
                  AppPillChip(
                    label: '1M',
                    selected: _timeframe == '1M',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _timeframe = '1M');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Live simulated price history chart for ${asset.symbol}',
            image: true,
            child: SizedBox(
              height: 260,
              child: CustomPaint(
                painter: _ChartPainter(points: points, isPositive: isPositive),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: MiniTrendChart(
                    points: points,
                    isPositive: isPositive,
                    semanticLabel: 'Mini price trend for ${asset.symbol}',
                    height: 44,
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final offsets = <Offset>[];

    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - ((points[i] - minValue) / range * size.height);
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final controlPoint = Offset((current.dx + next.dx) / 2, current.dy);
      final endPoint = Offset((current.dx + next.dx) / 2, next.dy);
      path.quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        endPoint.dx,
        endPoint.dy,
      );
    }
    path.lineTo(offsets.last.dx, offsets.last.dy);

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
    return AppCard(
      child: Text(
        asset.explanation,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
