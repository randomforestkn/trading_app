import 'package:flutter/material.dart';

import '../design/app_spacing.dart';
import '../design/app_typography.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.sectionHeader.copyWith(fontSize: 18),
            ),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = AppSpacing.screenPaddingForWidth(
              constraints.maxWidth,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding.left,
                AppSpacing.md,
                horizontalPadding.right,
                AppSpacing.xl,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
