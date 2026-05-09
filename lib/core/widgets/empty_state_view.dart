import 'package:flutter/material.dart';

import '../design/app_motion.dart';
import '../design/app_spacing.dart';
import 'app_card.dart';
import 'app_buttons.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            duration: AppMotion.short,
            opacity: 1,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white10,
              child: Icon(icon, color: Colors.white70),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(label: actionLabel!, onPressed: onActionPressed),
          ],
        ],
      ),
    );
  }
}
