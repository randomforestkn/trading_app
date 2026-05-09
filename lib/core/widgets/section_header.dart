import 'package:flutter/material.dart';

import '../design/app_spacing.dart';
import '../design/app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, AppSpacing.xxl, 2, AppSpacing.sm),
      child: Text(title, style: AppTypography.sectionHeader),
    );
  }
}
