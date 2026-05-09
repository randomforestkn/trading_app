import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_motion.dart';

class AppPillChip extends StatelessWidget {
  const AppPillChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
    this.selectedColor,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = selectedColor ?? AppColors.secondary;
    return AnimatedScale(
      duration: AppMotion.fast,
      scale: selected ? 1.0 : 0.99,
      child: FilterChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 16),
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        side: BorderSide(color: selected ? accent : AppColors.border),
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: accent.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: selected ? accent : Colors.white70,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
    );
  }
}
