import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

class AppStatTile extends StatelessWidget {
  const AppStatTile({
    required this.label,
    required this.value,
    super.key,
    this.subtitle,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;

    return Container(
      padding: AppSpacing.statTilePadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.statLabel)),
              if (icon != null) Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.statValue.copyWith(color: accent)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: AppTypography.caption),
          ],
        ],
      ),
    );
  }
}
