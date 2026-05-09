import 'package:flutter/material.dart';

import '../design/app_spacing.dart';
import 'app_stat_tile.dart';

class StatGrid extends StatelessWidget {
  const StatGrid({required this.stats, super.key});

  final Map<String, String> stats;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tileWidth = width > 920
        ? 190.0
        : width > 600
        ? 170.0
        : 150.0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: stats.entries.map((entry) {
        return SizedBox(
          width: tileWidth,
          child: AppStatTile(label: entry.key, value: entry.value),
        );
      }).toList(),
    );
  }
}
