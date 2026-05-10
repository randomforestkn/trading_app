import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_motion.dart';
import '../design/app_spacing.dart';
import '../models/asset.dart';
import 'change_text.dart';
import 'app_card.dart';
import 'mini_trend_chart.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({required this.asset, this.history, this.onTap, super.key});

  final TradingAsset asset;
  final List<double>? history;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: AppSpacing.tilePadding,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.14),
          child: Text(
            asset.symbol.characters.take(2).toString(),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          asset.symbol,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${asset.name} • ${asset.type.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 112,
          child: AnimatedSwitcher(
            duration: AppMotion.short,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Stack(
              key: ValueKey(
                '${asset.symbol}-${asset.price.toStringAsFixed(2)}',
              ),
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: 0.72,
                    child: MiniTrendChart(
                      points: history ?? asset.trend,
                      isPositive: asset.dailyChangePercent >= 0,
                      semanticLabel: 'Price trend for ${asset.symbol}',
                      width: 50,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${asset.price.toStringAsFixed(asset.price > 1000 ? 0 : 2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        ChangeText(asset.dailyChangePercent, compact: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
