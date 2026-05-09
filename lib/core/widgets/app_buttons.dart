import 'package:flutter/material.dart';

import '../design/app_motion.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final resolved = isDestructive
        ? FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          )
        : null;
    return AnimatedOpacity(
      duration: AppMotion.short,
      opacity: onPressed == null ? 0.55 : 1,
      child: icon == null
          ? FilledButton(
              onPressed: onPressed,
              style: resolved,
              child: Text(label),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              style: resolved,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.short,
      opacity: onPressed == null ? 0.55 : 1,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
